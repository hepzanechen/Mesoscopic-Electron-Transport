addpath('/home/yanxiwu/test2nodelete/varymusi/calcshared/');
autoSetWorkers()

%% read parameters relating to system configuration in each one's own folder
paramsFilename ="params";
% preparet to pass paramsdata cell to each parfor
paramsdata = readcell(paramsFilename);
% extract params to base ws
assign_parameters(paramsdata);
%% calcuate and store data .mat



%% Below is system specific-------------------------------------------------------------------------------------------
H_total = construct_Hamiltonian(paramsdata);

Eig_values = eig(H_total);
ind = Eig_values >= E_start & Eig_values <= E_end;
E_sample_values = unique([Eig_values(ind)', linspace(E_start, E_end, num_points)]);

%E_sample_values = unique([Eig_values', linspace(E_start, E_end, num_points)]);
muValues = [muLead1, muLead2End, muLead3, muLead4];
leads_info = setLeadMu(muValues, tLeadC, Temperature, Nx);

%% Before varing Leadmu try to find the adapative Mu grid
[results_struct] = adaptive_rho_calculation2(E_sample_values, threshold, H_total, eta, leads_info,Temperature);
filename = eval(filename);
%% Above is system specific------------------------------------------------------------------------------------------



save(filename+".mat",'H_total','leads_info','results_struct');
current = cellfun(@(x) x(1), results_struct.current);  % Extract the current for lead 1 as an example
E=results_struct.E;
[currentPeaks, locsPeaks] = findpeaks(abs(current));
% Initialize the refined grid array within the specific range
initialRange = [muLead2Start:muStep:muLead2End];
E_refined = initialRange;
% Ensure that we only consider peaks within the initial range
validPeaksIdx = find(E(locsPeaks) >= min(initialRange) & E(locsPeaks) <= max(initialRange));
locsPeaksInRange = locsPeaks(validPeaksIdx);

for i = 1:length(locsPeaksInRange)
    peakValue = currentPeaks(validPeaksIdx(i));
    thresholdValue = 0.1 * peakValue; % 10% of the peak value

    % Search for the threshold crossing points to the left of the peak
    leftSide = current(1:locsPeaksInRange(i));
    leftIdx = find(leftSide < thresholdValue, 1, 'last');

    % If not found on the left or outside the initial range, adjust leftIdx accordingly
    if isempty(leftIdx) || E(leftIdx) < min(initialRange)
        leftIdx = find(E >= min(initialRange), 1, 'first');
    end

    % Do the same for the right side
    rightSide = current(locsPeaksInRange(i):end);
    rightIdxTemp = find(rightSide < thresholdValue, 1, 'first');

    % Adjust right index to be relative to the whole array
    rightIdx = locsPeaksInRange(i) + rightIdxTemp - 1;

    % If not found on the right or outside the initial range, adjust rightIdx accordingly
    if isempty(rightIdxTemp) || E(rightIdx) > max(initialRange)
        rightIdx = find(E <= max(initialRange), 1, 'last');
    end

    % Generate a refined grid between E1 and E2 with higher density
    E1 = E(leftIdx);
    E2 = E(rightIdx);
    refinedGrid = linspace(E1, E2, 50); % 20 points for higher density, adjust as needed

    % Add the refined grid to E_refined, ensuring it's within the initial range
    E_refined = [E_refined, refinedGrid(refinedGrid >= min(initialRange) & refinedGrid <= max(initialRange))];
end

% Remove duplicates and sort the refined grid to ensure it's within the initial range
E_refined = unique(E_refined);


%% Varing Leadmu
% Calculate the number of steps
numSteps = length(E_refined);
numLeads=length(leads_info);
% Assuming numLeads is defined and numSteps is defined
intCurrents = zeros(numLeads,numSteps);  % Store int_current for each lead and each step
intNoises = zeros(numLeads, numLeads,numSteps);    % Store int_noise for each lead pair and each step

parfor i = 1:numSteps
    Lead2mu=E_refined(i);
    [int_current,int_noise] = calc_loopParameter(H_total,E_sample_values, paramsdata, Lead2mu)
    % Collect necessary values for intCurrents and intNoises
    intCurrents(:, i) = int_current;  % Store all current values for this step
    intNoises(:, :, i) = int_noise;   % Store all noise values for this step

end


save(filename+'.mat', 'intCurrents', 'intNoises','E_refined',"-append");


for i = 1:numLeads
    for j = 1:numLeads
        % Plot Integrated Noise vs. Current for current leads
        figure;
        scatter(intCurrents(i,:), squeeze(intNoises(i, j,:)), 'filled');
        xlabel(sprintf('Integrated Current (Lead %d)', i));
        ylabel(sprintf('Integrated Noise (Lead %d, Lead %d)', i, j));
        title(sprintf('Integrated Noise vs. Current Across Steps (Lead %d and Lead %d)', i, j));
        grid on;

        % Save the figure with a unique filename
        savefig(sprintf('CurrentvsNoise_Lead_%d_%d_%s.fig', i, j, filename));

        % Create subplots for intCurrents and intNoise vs. Lead2mu
        figure;

        % Plot intCurrents vs. Lead2mu
        subplot(2, 1, 1);
        plot(E_refined, intCurrents(i,:), 'LineWidth', 1.5);
        xlabel('Lead2mu ');
        ylabel(sprintf('Integrated Current (Lead %d)', i));
        title(sprintf('Integrated Current vs. Lead2mu (Lead %d)', i));
        grid on;

        % Plot intNoise vs. Lead2mu
        subplot(2, 1, 2);
        plot(E_refined, squeeze(intNoises(i, j,:)), 'LineWidth', 1.5);
        xlabel('Lead2mu ');
        ylabel(sprintf('Integrated Noise (Lead %d, Lead %d)', i, j));
        title(sprintf('Integrated Noise vs. Lead2mu (Lead %d and Lead %d)', i, j));
        grid on;

        % Adjust the spacing between subplots
%        tight_layout();

        % Save the figure with a unique filename
        savefig(sprintf('CurrentNoisevsE_Lead_%d_%d_%s.fig', i, j, filename));
    end
end

