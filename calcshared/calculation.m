function [results] = calculation(E, H_total, eta, leads_info,Temperature)
    % Parameters
    k_B=1;
    H_total_size = size(H_total, 1);

    % Call the modified total_self_energy function
    [Sigma_retarded_Total, leads_info] = total_self_energy(E, leads_info, H_total_size/2);

    G_retarded = inv((E + eta) * eye(H_total_size) - H_total - Sigma_retarded_Total);

    % Ldos, Initializing rho_jj for each site
    % Getting only the electron/odd indices from the diagonal
    diag_G_retarded = diag(G_retarded);
    results.rho_jj = -imag(diag_G_retarded(1:2:end)) / pi;

    % Calculating DOS
    trace_Gii_electron = trace(G_retarded * kron(eye(H_total_size / 2), diag([1, 0])));
    trace_Gii_hole = trace(G_retarded * kron(eye(H_total_size / 2), diag([0, 1])));
    results.rho_electron = -imag(trace_Gii_electron) / pi;
    results.rho_hole = -imag(trace_Gii_hole) / pi;

    % Calculating transmission between different leads
    num_leads = length(leads_info);
    results.transmission = zeros(num_leads, num_leads);
    results.andreev = zeros(num_leads, num_leads);
    results.noise = zeros(num_leads, num_leads);
    types = {'h', 'e'}; % Electron and hole types, sgn(2)=1
    T = zeros(num_leads, num_leads, 2, 2); % Initialize transmission array (2 for 'e' and 'h')


    % Compute common portion of sum_gamma_term outside the i, j, alpha, beta loops
    common_sum_gamma_term = 0;
    for k = 1:length(leads_info)
        for gamma_idx = 1:2
            gamma = types{gamma_idx};
            common_sum_gamma_term = common_sum_gamma_term + leads_info{k}.Gamma.(gamma) * fermi_distribution(E, leads_info{k}.mu, k_B, Temperature, gamma);
        end
    end

    % Initialize arrays
    T = zeros(num_leads, num_leads, 2, 2); % Transmission matrix

    % Loop through leads and types to calculate transmission
    for i = 1:num_leads
        for j = 1:num_leads
            for alpha_idx = 1:2
                alpha = types{alpha_idx};
                for beta_idx = 1:2
                    beta = types{beta_idx};

                    % Compute Transmission
                    if i == j && alpha_idx == beta_idx
                        T(i, j, alpha_idx, beta_idx) = nnz(leads_info{i}.Gamma.(alpha)) + trace(leads_info{i}.Gamma.(alpha) * G_retarded * leads_info{i}.Gamma.(alpha) * G_retarded' + ...
                                               1i * leads_info{i}.Gamma.(alpha) * (G_retarded' - G_retarded));
                    else
                        T(i, j, alpha_idx, beta_idx) = trace(leads_info{i}.Gamma.(alpha) * G_retarded * leads_info{j}.Gamma.(beta) * G_retarded');
                    end
                end
            end
        end
    end

    % Now, compute noise_{ij} and current_{i}
    noise = zeros(num_leads, num_leads);
    current = zeros(num_leads);
    for i = 1:num_leads
        for j = 1:num_leads
            for alpha_idx = 1:2
                alpha = types{alpha_idx};
                for beta_idx = 1:2
                    beta = types{beta_idx};

                    % First term
                    if i == j && alpha_idx == beta_idx
                        noise(i, j) = noise(i, j) + nnz(leads_info{i}.Gamma.(alpha))*fermi_distribution(E, leads_info{i}.mu, k_B, Temperature, alpha) * (1 - fermi_distribution(E, leads_info{i}.mu, k_B, Temperature, alpha));
                        current(i) = current(i) + sign(alpha_idx-1.5)*nnz(leads_info{i}.Gamma.(alpha))*fermi_distribution(E, leads_info{i}.mu, k_B, Temperature, alpha);
                    end

                    % Second term
                    current(i) = current(i) - sign(alpha_idx-1.5)*T(i, j, alpha_idx, beta_idx) * fermi_distribution(E, leads_info{j}.mu, k_B, Temperature, beta) ;
                    noise(i, j) = noise(i, j) - sign(alpha_idx-1.5) * sign(beta_idx-1.5) * (T(j, i, beta_idx, alpha_idx) * fermi_distribution(E, leads_info{i}.mu, k_B, Temperature, alpha) * (1 - fermi_distribution(E, leads_info{i}.mu, k_B, Temperature, alpha)) + ...
                                                  T(i, j, alpha_idx, beta_idx) * fermi_distribution(E, leads_info{j}.mu, k_B, Temperature, beta) * (1 - fermi_distribution(E, leads_info{j}.mu, k_B, Temperature, beta)));

                    % Third term (using precomputed T matrix)
                    if i == j && alpha_idx == beta_idx
                        for k = 1:num_leads
                            for gamma_idx = 1:2
                                noise(i, j) = noise(i, j) + T(j, k, beta_idx, gamma_idx) * fermi_distribution(E, leads_info{k}.mu, k_B, Temperature, types{gamma_idx});
                            end
                        end
                    end

                    % Fourth term calculation
                    delta_term = sparse(H_total_size, H_total_size);
                    if i == j && alpha_idx == beta_idx
                        delta_term = fermi_distribution(E, leads_info{i}.mu, k_B, Temperature, alpha) * double(leads_info{i}.Gamma.(alpha) ~= 0);
                    end

                    Ga_term_ij = 1i*leads_info{j}.Gamma.(beta) * G_retarded' * fermi_distribution(E, leads_info{j}.mu, k_B, Temperature, beta);
                    Gr_term_ij = -1i*leads_info{j}.Gamma.(beta) * G_retarded * fermi_distribution(E, leads_info{i}.mu, k_B, Temperature, alpha);
                    sum_gamma_term_ij = leads_info{j}.Gamma.(beta) * G_retarded * common_sum_gamma_term * G_retarded';

                    Ga_term_ji = 1i*leads_info{i}.Gamma.(alpha) * G_retarded' * fermi_distribution(E, leads_info{i}.mu, k_B, Temperature, alpha);
                    Gr_term_ji = -1i*leads_info{i}.Gamma.(alpha) * G_retarded * fermi_distribution(E, leads_info{j}.mu, k_B, Temperature, beta);
                    sum_gamma_term_ji = leads_info{i}.Gamma.(alpha) * G_retarded * common_sum_gamma_term * G_retarded';

                    s_s_FermiProduct_ij = delta_term + Ga_term_ij + Gr_term_ij + sum_gamma_term_ij;
                    s_s_FermiProduct_ji = delta_term + Ga_term_ji + Gr_term_ji + sum_gamma_term_ji;

                    % Fourth Term
                    noise(i, j) = noise(i, j) - sign(alpha_idx-1.5) * sign(beta_idx-1.5) * trace(s_s_FermiProduct_ij * s_s_FermiProduct_ji);

                end
            end
        end
    end
    results.transmission = T(:,:,2,2);
    results.andreev = T(:,:,1,2);
    results.current=current;
    results.noise = noise;
end