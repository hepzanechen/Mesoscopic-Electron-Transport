function assign_parameters(pramscell)
% Read the file into a cell array and assign
    varNames = pramscell(:, 1);
    varValues = pramscell(:, 2);
    for i = 1:numel(varNames)
    assignin('caller', varNames{i}, varValues{i});
    end
end