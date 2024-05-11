function autoSetWorkers(excludeFiles, dirPaths)
    % Usage examples
    % autoSetWorkers;                   % Exclude only 'main.m' by default
    % autoSetWorkers({'otherScriptToExclude.m', 'anotherOne.m'});
    % autoSetWorkers([], {'/path/to/dir1', '/path/to/dir2'});
    % autoSetWorkers({'otherScriptToExclude.m', 'anotherOne.m'}, {'/path/to/dir1', '/path/to/dir2'});

    if nargin < 1
        excludeFiles = {};     % Default to an empty cell if no arguments are given
    end

    if nargin < 2
        dirPaths = {pwd,'/home/yanxiwu/test2nodelete/varymusi/calcshared/'};
    end

    % Ensure 'main.m' is always excluded if not specified
    if ~ismember('main.m', excludeFiles)
        excludeFiles{end+1} = 'main.m';
    end

    % Query the number of logical CPUs available on the system
    numCores = feature('numcores');

    % Determine the desired number of workers
    desiredNumWorkers = numCores;

    % Check for an existing parallel pool
    poolObj = gcp('nocreate');
    if isempty(poolObj) || poolObj.NumWorkers ~= desiredNumWorkers
        if ~isempty(poolObj)
            delete(poolObj);   % Close the existing pool
        end
        poolObj = parpool(desiredNumWorkers);   % Open a new pool with the desired number of workers
    end

    % Find and attach .m files in the specified directories, excluding specified files
    allFilesToAttach = {};
    for idx = 1:length(dirPaths)
        dirPath = dirPaths{idx};
        currentFolderFiles = dir(fullfile(char(dirPath), '*.m'));
        fileNames = {currentFolderFiles.name};
        filesToAttach = setdiff(fileNames, excludeFiles);
        allFilesToAttach = [allFilesToAttach, filesToAttach];
    end

    % Attach the necessary files to the pool
    if ~isempty(poolObj) && ~isempty(allFilesToAttach)
        addAttachedFiles(poolObj, allFilesToAttach);
        disp(['Attached files to the pool: ', strjoin(allFilesToAttach, ', ')]);
    else
        disp('No files were attached to the pool.');
    end
end
