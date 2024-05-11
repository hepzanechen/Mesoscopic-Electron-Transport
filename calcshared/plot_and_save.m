function plot_and_save(filePattern, terminal1, terminal2, plotCondition, dymlegend,strlegend,stepTemp)
    % Search for files that match the pattern in the specified subdirectory
    files = dir(filePattern);

    figure; % Create a new figure for plotting

    % Loop through each file
    for i = 1:length(files)
        data = load(files(i).name); % Load the data file
        results_struct = data.results_struct; % Extract the results_struct

        % Check the plot condition
        if eval(plotCondition)
            inxlegend = eval(dymlegend);

            % Noise subplot
            subplot(6, 1, 1); % First subplot in a 6x1 grid
            hold on; % Hold on to plot multiple lines
            noise_ij = cellfun(@(x) x(terminal1, terminal2), results_struct.noise);
            plot(results_struct.E, noise_ij, '-', 'DisplayName', sprintf('%s:%.2f',strlegend, inxlegend), 'LineWidth', 2);
            ylabel('Noise');
            legend('-DynamicLegend');
            title('Noise vs. Energy');
            xlim auto;
            ylim auto;
            grid on;

            % Andreev subplot
            subplot(6, 1, 2); % Second subplot in a 6x1 grid
            hold on;
            andreev_ij = cellfun(@(x) x(terminal1, terminal2), results_struct.andreev);
            plot(results_struct.E, andreev_ij, '-', 'DisplayName', sprintf('%s:%.2f',strlegend, inxlegend), 'LineWidth', 2);
            ylabel('Andreev Reflection');
            legend('-DynamicLegend');
            title('Andreev Reflection vs. Energy');
            xlim auto;
            ylim auto;
            grid on;

            % Transmission subplot
            subplot(6, 1, 3); % Third subplot in a 6x1 grid
            hold on;
            transmission_ij = cellfun(@(x) x(terminal1, terminal2), results_struct.transmission);
            plot(results_struct.E, transmission_ij, '-', 'DisplayName', sprintf('%s:%.2f',strlegend, inxlegend), 'LineWidth', 2);
            ylabel('Transmission');
            legend('-DynamicLegend');
            title('Transmission vs. Energy');
            xlim auto;
            ylim auto;
            grid on;

            % rho_electro subplot
            subplot(6, 1, 4); % Fourth subplot in a 6x1 grid
            hold on;
            plot(results_struct.E, results_struct.rho_electron_values, '-', 'DisplayName', sprintf('%s:%.2f',strlegend, inxlegend), 'LineWidth', 2);
            ylabel('Electron Density');
            legend('-DynamicLegend');
            title('Electron Density vs. Energy');
            xlim auto;
            ylim auto;
            grid on;

            % rho_hole subplot
            subplot(6, 1, 5); % Fifth subplot in a 6x1 grid
            hold on;
            plot(results_struct.E, results_struct.rho_hole, '-', 'DisplayName',sprintf('%s:%.2f',strlegend, inxlegend), 'LineWidth', 2);
            ylabel('Hole Density');
            legend('-DynamicLegend');
            title('Hole Density vs. Energy');
            xlim auto;
            ylim auto;
            grid on;

            % Current subplot
            subplot(6, 1, 6); % Sixth subplot in a 6x1 grid
            hold on;
            current_ij = cellfun(@(x) x(terminal1, terminal2), results_struct.current);
            plot(results_struct.E, current_ij, '-', 'DisplayName', sprintf('%s:%.2f',strlegend, inxlegend), 'LineWidth', 2);
            xlabel('Energy');
            ylabel('Current');
            legend('-DynamicLegend');
            title('Current vs. Energy');
            xlim auto;
            ylim auto;
            grid on;
        end
    end

    % Save the figure based on the filename
    fileFigName = strrep(filePattern, '*', 'all');
    savefig(sprintf('%s_termial%d_%d.fig', fileFigName, terminal1, terminal2));
end