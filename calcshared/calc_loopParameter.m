function [int_current,int_noise] = calc_loopParameter(H_total, E_sample_values, paramsdata, stepValue)
% Usage:calc_loopParameter(paramsdata, stepValue)
%
    % use eval inside parfor function is permitted, dynamically decides which
    % variable to loop
    assign_parameters(paramsdata)
    variableList = strsplit(variableToUpdate, ','); % This splits the string into a cell array of strings
    for idx = 1:length(variableList)
        eval(sprintf('%s = %f;', variableList{idx}, stepValue));
    end

    % Define the lead structures
    muValues = [muLead1, muLead2, muLead3, muLead4];
    leads_info = setLeadMu(muValues, tLeadC, Temperature, Nx);

    [results_struct] = adaptive_rho_calculation2(E_sample_values, threshold, H_total, eta, leads_info,Temperature);
    int_current = results_struct.int_current;  % Store all current values for this step
    int_noise = results_struct.int_noise;   % Store all noise values for this step

end