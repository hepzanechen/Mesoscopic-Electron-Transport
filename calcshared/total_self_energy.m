function [Sigma_retarded_Total, leads_info] = total_self_energy(E, leads_info, system_dim)

    % Initialize self-energy matrices based on the size of the system
    dim = system_dim * 2;
    Sigma_retarded_Total = sparse(dim, dim);  % Initialize as sparse matrix

    % Loop through each lead to calculate self-energy
    for i = 1:length(leads_info)
        % Extract information about the lead
        mu = leads_info{i}.mu;
        position_electron = 2 * leads_info{i}.position - 1;
        position_hole = 2 * leads_info{i}.position;
        t = leads_info{i}.t;
        epsilon0 = leads_info{i}.epsilon0;
        V1alpha = leads_info{i}.V1alpha;

        % Calculate self-energies for the current lead
        Sigma_electron = self_energy_decimation(E, t, epsilon0, V1alpha, 'particle');
        Sigma_hole = self_energy_decimation(E, t, epsilon0, V1alpha, 'hole');

        % Initialize and use direct indexing to embed Sigma matrices
        Sigma_electron_largematrix = sparse(dim, dim);
        Sigma_hole_largematrix = sparse(dim, dim);
        Sigma_electron_largematrix(position_electron, position_electron) = Sigma_electron;
        Sigma_hole_largematrix(position_hole, position_hole) = Sigma_hole;

        % Aggregate contributions to the total self-energy
        Sigma_retarded_Total = Sigma_retarded_Total + Sigma_electron_largematrix + Sigma_hole_largematrix;

        % Create larger Gamma matrices and then embed
        Gammaee_large = sparse(dim, dim);
        Gammahh_large = sparse(dim, dim);
        Gammaee_large(position_electron, position_electron) = 1j*(Sigma_electron-Sigma_electron');
        Gammahh_large(position_hole, position_hole) = 1j*(Sigma_hole-Sigma_hole');

        % Update Gammaee and Gammahh for later calculations
        leads_info{i}.Gamma.e = Gammaee_large;
        leads_info{i}.Gamma.h = Gammahh_large;
    end
end
