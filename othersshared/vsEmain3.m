addpath('/home/yanxiwu/test2nodelete/varymusi/calcshared/');
autoSetWorkers()

%% read parameters relating to system configuration in each one's own folder
paramsFilename ="params";
% preparet to pass paramsdata cell to each parfor
paramsdata = readcell(paramsFilename);
% extract params to base ws
assign_parameters(paramsdata);
%% calcuate and store data .mat
parfor i = 1:numSteps
    % Calculate the actual temperature value
    stepValue = startTemp + (i-1) * stepTemp;
    calc_loopParameterVsE3(paramsdata,stepValue);
end

%% plot by reading .mat
filePattern = eval(filePattern);

for terminali = 1:numLeads
    for terminalj = 1:numLeads
        plot_and_save(filePattern, terminali, terminalj, plotCondition, dymLegend, strLegend,stepTemp);
    end
end
