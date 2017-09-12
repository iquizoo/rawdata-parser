function dataExtract = Preproc(datapath, varargin)
%PREPROC calls sngproc to do some basic analysis.
%   dataExtract = Preproc(datapath) preprocesses all the tasks in the
%   directory specified by datapath.
%
%   dataExtract = Preproc(datapath, Name, Value) provides parameter input
%   values by Name, Value pairs.
%
%   Possible pairs are as follows:
%         'TaskNames' - specifies tasks as a vector of
%                       TaskID/TaskOrigName/TaskName/TaskIDName: TaskID is
%                       the identifier number of one task, TaskOrigName is
%                       the original name (in raw data), TaskName is the
%                       name (abstracted one) used in settings, TaskIDName
%                       is the identifier English name for each task.
%                       Notice: only TaskID and TaskIDName is stored. And
%                       TaskOrigName and TaskID are unique which separates
%                       different editions of one task, but other names do
%                       not. When using TaskOrigName, please ensure all the
%                       names are original names.
%       'DisplayInfo' - specifies how the rate of process and other
%                       information is displayed when processing: either
%                       'text' or 'waitbar'.
%        'DebugEntry' - a number used for entry number for data when
%                       debugging.

% By Zhang, Liang. 2015/11/27.
%
% Modified to use in another problem.
% Modification completed at 2016/04/13.
%
% 2017/09/10:
%   Modified logic to store data in .txt files.

% start stopwatch.
tic

% open a log file
logfid = fopen('preproc(AutoGen).log', 'a');
fprintf(logfid, '[%s] Start preprocessing path: %s\n', datestr(now), datapath);

% load settings, parameters, task names, etc.
configpath = 'config';
readparas = {'FileEncoding', 'UTF-8', 'Delimiter', '\t'};
settings = readtable(fullfile(configpath, 'settings.csv'), readparas{:});
para = readtable(fullfile(configpath, 'para.csv'), readparas{:});
tasknames = readtable(fullfile(configpath, 'taskname.csv'), readparas{:});
% metavars options
metavarsOfChk = {'Taskname', 'userId', 'name', 'gender|sex', 'school', 'grade', 'cls', 'birthDay', 'createDate|createTime', 'conditions'};
metavarsOfChkClass = {'cell', 'double', 'cell', 'cell', 'cell', 'cell', 'cell', 'datetime', 'datetime', 'cell'};
% taskname and conditions are thrown away when storing metadata
outMetaVarsIdx = 2:9;

% parse and check input arguments
par = inputParser;
addParameter(par, 'TaskNames', '', @(x) ischar(x) | iscellstr(x) | isstring(x) | isnumeric(x))
addParameter(par, 'DisplayInfo', 'text', @ischar)
addParameter(par, 'DebugEntry', [], @isnumeric)
parse(par, varargin{:});
taskInputNames = par.Results.TaskNames;
prompt = lower(par.Results.DisplayInfo);
dbentry = par.Results.DebugEntry;
% throw an error when the specified path is not found
if ~exist(datapath, 'dir')
    fprintf(logfid, '[%s] Error: specified data path %s does not exist.\n', ...
        datestr(now),datapath);
    fclose(logfid);
    error('UDF:PREPROC:DATAFILEWRONG', 'Data path %s not found, please check!', datapath)
end
% check input task names validity and get the required taskIDs and
% taskIDNames
if isnumeric(taskInputNames)
    fprintf('Detected tasks are specified in numeric type. Checking validity.\n')
    [isValid, loc] = ismember(taskInputNames, tasknames.TaskID);
    if ~all(isValid)
        warning('UDF:PREPROC:InvalidTaskID', ...
            'Some task identifiers are invalid, and will not be preprocessed. Please check!')
        fprintf('Invalid task identifier:\n')
        disp(taskInputNames(~isValid))
        taskInputNames(~isValid) = [];
        loc(~isValid) = [];
    end
    taskIDs = taskInputNames;
    taskIDNames = tasknames.TaskIDName(loc);
else
    fprintf('Detected tasks are specified in charater/string type. Checking validity.\n')
    % change tasks to a row cellstr vector if necessary
    taskInputNames = cellstr(taskInputNames);
    taskInputNames = reshape(taskInputNames, numel(taskInputNames), 1);
    % remove empty task name string
    taskInputNames(ismissing(taskInputNames)) = [];
    if all(ismember(taskInputNames, tasknames.TaskOrigName))
        % the task names are specified by original names
        [isValid, loc] = ismember(taskInputNames, tasknames.TaskOrigName);
        % remove non-matching task names from input task names
        if ~all(isValid)
            warning('UDF:PREPROC:InvalidTaskNameString', ...
                'Some task name strings are invalid, and will not be preprocessed. Please check!')
            fprintf('Invalid task name strings:\n')
            disp(taskInputNames(~isValid))
            taskInputNames(~isValid) = [];
            loc(~isValid) = [];
        end
        taskIDs = tasknames.TaskID(loc);
        taskIDNames = tasknames.TaskIDName(loc);
    else
        % the task names are not specified by IDs and original names
        % check the location for each kind of task names
        [isvalidTaskName, locTaskName] = ismember(taskInputNames, tasknames.TaskName);
        [isvalidTaskCNName, locTaskCNName] = ismember(taskInputNames, tasknames.TaskCNName);
        [isvalidTaskIDName, locTaskIDName] = ismember(taskInputNames, tasknames.TaskIDName);
        % task name is valid if any kind of task names matches
        isValid = isvalidTaskName | isvalidTaskCNName | isvalidTaskIDName;
        % remove non-matching task names from input task names
        if ~all(isValid)
            warning('UDF:PREPROC:InvalidTaskNameString', ...
                'Some task name strings are invalid, and will not be preprocessed. Please check!')
            fprintf('Invalid task name strings:\n')
            disp(taskInputNames(~isValid))
            taskInputNames(~isValid) = [];
        end
        % get the locations for each valid input task name
        locstore = num2cell([locTaskName, locTaskCNName, locTaskIDName], 2);
        loc = cellfun(@(x) unique(x(x ~= 0)), locstore);
        % get the ID and IDName
        taskIDs = tasknames.TaskID(loc);
        taskIDNames = tasknames.TaskIDName(loc);
    end
end

% when debugging, only one task should be specified
if (isempty(taskIDNames) || length(taskIDNames) > 1) && ~isempty(dbentry)
    fprintf(logfid, '[%s] Error, not enough input parameters.\n', datestr(now));
    fclose(logfid);
    error('UDF:PREPROC:DEBUGWRONGPAR', '(Only one) task name must be set when using debug mode.');
end

% get all the task names to be preprocessed
% get all the data file informations, which are named after task IDs
dataFiles = dir(datapath);
dataFiles([dataFiles.isdir]) = []; % folder exclusion
% get all the task names
[~, dataTaskIDs] = cellfun(@fileparts, {dataFiles.name}', 'UniformOutput', false);
dataTaskIDs = str2double(dataTaskIDs);
% set to preprocess all the tasks if not specified
if isempty(taskIDNames)
    taskInputNames = dataTaskIDs;
    taskIDs = dataTaskIDs;
    % suppose all the task IDs in the raw data are recorded in the settings
    taskIDNames = tasknames.TaskIDName(ismember(tasknames.TaskID, taskIDs));
end
% check whether data for the to-be-processed tasks exist or not
dataIsExisted = ismember(taskIDs, dataTaskIDs);
if ~all(dataIsExisted)
    fprintf('Oops! Data of these tasks you specified are not found, will remove these tasks...\n')
    disp(taskInputNames(~dataIsExisted))
    taskInputNames(~dataIsExisted) = [];
    taskIDs(~dataIsExisted) = [];
    taskIDNames(~dataIsExisted) = [];
end

% preallocation
ntasks4process = length(taskInputNames);
dataExtract = table(taskIDs, taskIDNames, ...
    cell(ntasks4process, 1), repmat(cellstr('TBE'), ntasks4process, 1), ...
    'VariableNames', {'TaskID', 'TaskIDName', 'Data', 'Time2Preproc'});
% display the information of processing.
fprintf('Here it goes! The total jobs are composed of %d task(s), though some may fail...\n', ...
    ntasks4process);

% rate of progress display initialization
switch prompt
    case 'waitbar'
        hwb = waitbar(0, 'Begin processing the tasks specified by users...Please wait...', ...
            'Name', 'Preprocess raw data of CCDPro',...
            'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
        setappdata(hwb, 'canceling', 0)
    case 'text'
        except  = false;
        dispinfo = '';
end
nprocessed = 0;
nignored = 0;
elapsedTime = toc;

% add helper functions folder
anafunpath = 'utilis';
addpath(anafunpath);

% preprocess task by task
for itask = 1:ntasks4process
    initialVars = who;
    curTaskID = taskIDs(itask);
    curTaskIDName = taskIDNames{itask};

    % update prompt information.
    completePercent = nprocessed / (ntasks4process - nignored);
    if nprocessed == 0
        msgSuff = 'Please wait...';
    else
        elapsedTime = toc;
        eta = seconds2human(elapsedTime * (1 - completePercent) / completePercent, 'full');
        msgSuff = strcat('TimeRem:', eta);
    end
    switch prompt
        case 'waitbar'
            % Check for Cancel button press.
            if getappdata(hwb, 'canceling')
                fprintf('User canceled...\n');
                break
            end
            %Update message in the waitbar.
            msg = sprintf('Task: %s. %s', curTaskIDName, msgSuff);
            waitbar(completePercent, hwb, msg);
        case 'text'
            if ~except
                fprintf(repmat('\b', 1, length(dispinfo)));
            end
            dispinfo = sprintf('Now processing %s (total: %d) task: %s. %s\n', ...
                num2ord(nprocessed + 1), ntasks4process, curTaskIDName, msgSuff);
            fprintf(dispinfo);
            except = false;
    end
    % update processed tasks number.
    nprocessed = nprocessed + 1;

    % find out the setting of current task.
    locset = ismember(settings.TaskIDName, curTaskIDName);
    if ~any(locset)
        fprintf(logfid, ...
            '[%s] No settings specified for task %s. Continue to the next task.\n', ...
            datestr(now), curTaskIDName);
        %Increment of ignored number of tasks.
        nignored = nignored + 1;
        continue
    end
    curTaskSetting = settings(locset, :);

    % read raw data file.
    curTaskData = readtable(fullfile(datapath, [num2str(curTaskID), '.csv']), readparas{:});
    % when in debug mode, read the debug entry only
    if ~isempty(dbentry)
        curTaskData = curTaskData(dbentry, :);
        dbstop in sngpreproc
    end

    % checking metadata type
    curTaskMetavarsRaw = curTaskData.Properties.VariableNames;
    curTaskMetavars = metavarsOfChk;
    for ivar = 1:length(curTaskMetavars)
        curVarOpts = split(curTaskMetavars{ivar}, '|');
        curVar = intersect(curVarOpts, curTaskMetavarsRaw);
        curClass = metavarsOfChkClass{ivar};
        if ~isempty(curVar) % for better compatibility.
            curVar = curVar{:}; % get the data in the cell as a charater.
            curTaskMetavars{ivar} = curVar;
            if ~isa(curTaskData.(curVar), curClass)
                switch curClass
                    case 'cell'
                        curTaskData.(curVar) = num2cell(curTaskData.(curVar));
                    case 'double'
                        curTaskData.(curVar) = str2double(curTaskData.(curVar));
                    case 'datetime'
                        if isnumeric(curTaskData.(curVar))
                            curTaskData.(curVar) = repmat({''}, size(curTaskData.(curVar)));
                        end
                        curTaskData.(curVar) = datetime(curTaskData.(curVar));
                end
            end
        end
    end

    % generate a table to combine two variables: conditions and para, which
    % are used in the function sngproc. See more in function sngproc.
    curTaskCfg = table;
    %  1. conditions
    curTaskCfg.conditions = curTaskData.conditions;
    %  2. parameters
    curTaskPara = para(ismember(para.TemplateToken, curTaskSetting.TemplateToken), :);
    curTaskCfg.para = repmat({curTaskPara}, height(curTaskCfg), 1);

    % preprocessing the recorded data
    curTaskPreRes = rowfun(@sngpreproc, curTaskCfg, 'OutputVariableNames', {'splitRes', 'status'});

    % check preprocessed results.
    if isempty(curTaskPreRes)
        warning('UDF:PREPROC:DATAMISMATCH', 'No data found for task %s. Will keep it empty.', curTaskIDName);
        fprintf(logfid, ...
            '[%s] No data found for task %s.\r\n', datestr(now), curTaskIDName);
        except = true;
    else
        %Generate some warning according to the status.
        if any(curTaskPreRes.status ~= 0)
            except = true;
            warning('UDF:PREPROC:DATAMISMATCH', 'Oops! Data mismatch in task %s.', curTaskIDName);
            if any(curTaskPreRes.status == -1) %Data mismatch found.
                fprintf(logfid, ...
                    '[%s] Data mismatch encountered in task %s. Normally, its format is ''%s''.\r\n', ...
                    datestr(now), curTaskIDName, curTaskPara.VariablesNames{:});
            end
            if any(curTaskPreRes.status == -2) %Parameters for this task not found.
                fprintf(logfid, ...
                    '[%s] No parameters specification found in task %s.\r\n', ...
                    datestr(now), curTaskIDName);
            end
        end

        % generate a table to store all the results
        curTaskRes = curTaskData(:, ismember(curTaskMetavarsRaw, curTaskMetavars(outMetaVarsIdx)));
        % store the splitting results.
        curTaskSplitRes = cat(1, curTaskPreRes.splitRes{:});
        curTaskSplitResVars = curTaskSplitRes.Properties.VariableNames;
        for ivar = 1:length(curTaskSplitResVars)
            curTaskRes.(curTaskSplitResVars{ivar}) = curTaskSplitRes.(curTaskSplitResVars{ivar});
        end
        curTaskSpVarOpts = strsplit(curTaskSetting.PreSpVar{:});
        curTaskSpecialVar = intersect(curTaskMetavarsRaw, curTaskSpVarOpts);
        for ivar = 1:length(curTaskSpecialVar)
            curTaskRes.(curTaskSpecialVar{ivar}) = curTaskData.(curTaskSpecialVar{ivar});
        end
        curTaskRes.status = curTaskPreRes.status;

        % store names and data.
        dataExtract.TaskID(itask) = curTaskID;
        dataExtract.TaskIDName{itask} = curTaskIDName;
        dataExtract.Data{itask} = curTaskRes;
    end
    %Record the time used for each task.
    curTaskTimeUsed = toc - elapsedTime;
    dataExtract.Time2Preproc{itask} = seconds2human(curTaskTimeUsed, 'full');
    clearvars('-except', initialVars{:});
end
%Display information of completion.
usedTimeSecs = toc;
usedTimeHuman = seconds2human(usedTimeSecs, 'full');
fprintf('Congratulations! %d preprocessing task(s) completed this time.\n', nprocessed);
fprintf('Returning without error!\nTotal time used: %s\n', usedTimeHuman);
fclose(logfid);
if strcmp(prompt, 'waitbar'), delete(hwb); end
rmpath(anafunpath);
