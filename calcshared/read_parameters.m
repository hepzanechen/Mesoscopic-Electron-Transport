function read_parameters(filename)
% Read the file into a cell array and assign
    data = readcell(filename);
    varNames = data(:, 1);
    varValues = data(:, 2);
    for i = 1:numel(varNames)
    assignin('base', varNames{i}, varValues{i});
    end
end