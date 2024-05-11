function calc_loopParameterVsE2(paramsdata, stepValue)
% Usage:calc_loopParameter(paramsdata, stepValue)
%
    % use eval inside parfor function is permitted, dynamically decides which
    % variable to loop
    assign_parameters(paramsdata)
    variableList = strsplit(variableToUpdate, ','); % This splits the string into a cell array of strings
    for idx = 1:length(variableList)
        eval(sprintf('%s = %f;', variableList{idx}, stepValue));
    end

    H_total = construct_Hamiltonian(paramsdata,stepValue);

    Eig_values = eig(H_total);
    ind = Eig_values >= E_start & Eig_values <= E_end;
    E_sample_values = unique([Eig_values(ind)', linspace(E_start, E_end, num_points)]);

    % Define the lead structures
    leads_info = setLeadMu(paramsdata,stepValue);

    [results_struct] = adaptive_rho_calculation2(E_sample_values, threshold, H_total, eta, leads_info,Temperature);

    filename=eval(filename);
    % Prepare the save command
    saveCmd = sprintf("save(filename,'%s');", strrep(variableToSave, ',', "','"));
    % Use eval to execute the command
    eval(saveCmd);

end