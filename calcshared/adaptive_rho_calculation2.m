function [results_struct] = adaptive_rho_calculation2(E_values, threshold, H_total, eta, leads_info,Temperature)
    % Initialize
    E = E_values;

    % Calculate results for the initial energy points
    results = arrayfun(@(E) calculation(E, H_total, eta, leads_info,Temperature), E, 'UniformOutput', false);
    iteration_counter = 0;
    max_iterations = 2;

    % Loop for refining the energy range based on the results
    while true
        iteration_counter = iteration_counter + 1;

        % Find peaks and their locations
        rho_electron_values = cellfun(@(res) res.rho_electron, results);
        [pks, locs] = findpeaks(rho_electron_values, 'MinPeakProminence', threshold);

        % Estimate the bandwidth (Gamma) for each rho peak and add points around it
        for i = 1:length(pks)
            peak_height = pks(i);
            peak_position = E(locs(i));

            % Estimate Gamma (HWHM)
            Gamma = 1 / peak_height;  % Assuming A/pi = 1 for simplicity

            % Add points around the peak based on the estimated Gamma
            new_points = linspace(peak_position - 5*Gamma, peak_position + 5*Gamma, 100);
            E = [E, new_points];
        end

        % Sort E values and recalculate results
        E = sort(unique(E));
        results = arrayfun(@(E) calculation(E, H_total, eta, leads_info,Temperature), E, 'UniformOutput', false);

        % Find rapid changes in rho_values
        rho_electron_values = cellfun(@(res) res.rho_electron, results);
        small_constant = 1e-6;  % to prevent division by zero
        diff_rho_electron = diff(rho_electron_values);
        change_ratio = abs(diff_rho_electron) ./ (abs(rho_electron_values(1:end-1)) + small_constant);
        rough_indices = find(change_ratio > threshold);

        % If no rapid changes are found or max iterations reached, exit the loop
        if isempty(rough_indices) || iteration_counter > max_iterations
            break;
        end

        % Add finer energy points around high variation areas
        for idx = rough_indices
            num_new_points = min(10, round(change_ratio(idx) / threshold));
            new_points = linspace(E(idx), E(idx+1), num_new_points);
            new_points = new_points(2:end-1);  % Avoid duplicating existing points
            E = [E, new_points];
            new_results = arrayfun(@(E) calculation(E, H_total, eta, leads_info,Temperature), new_points, 'UniformOutput', false);
            results = [results, new_results];
        end

        % Sort arrays based on E for plotting and further calculations
        [E, idx] = sort(E);
        results = results(idx);
    end

    % Construct the final results_struct
    results_struct = struct();
    results_struct.E = E;
    results_struct.rho_jj = cellfun(@(res) res.rho_jj, results, 'UniformOutput', false);
    results_struct.rho_electron_values = cellfun(@(res) res.rho_electron, results);
    results_struct.transmission = cellfun(@(res) res.transmission, results, 'UniformOutput', false);
    results_struct.rho_hole = cellfun(@(res) res.rho_hole, results);
    results_struct.andreev = cellfun(@(res) res.andreev, results, 'UniformOutput', false);
    results_struct.current = cellfun(@(res) res.current, results, 'UniformOutput', false);
    results_struct.noise = cellfun(@(res) res.noise, results, 'UniformOutput', false);

    % Initialize matrices to store the integrated quantities for all combinations
    numLeads = numel(leads_info);
    results_struct.int_current = zeros(1,numLeads);
    results_struct.int_noise = zeros(numLeads);


    % Integrate quantities over energy for all lead combinations
    for i = 1:numLeads
        for j = 1:numLeads
            % Extract data for all combinations
            noise_ij = cellfun(@(x) x(i, j), results_struct.noise);
            results_struct.int_noise(i, j) = 0.5*trapz(results_struct.E, noise_ij);
        end
        current_i = cellfun(@(x) x(i), results_struct.current);
        results_struct.int_current(i) = 0.5*trapz(results_struct.E, current_i);
    end
end
