function dataExtract = Preproc(datapath, varargin)
%PREPROC calls sngproc to do some basic analysis.
%
%   See also SNGPREPROC.

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

% parse and check input arguments
par = inputParser;
addParameter(par, 'TaskNames', '', @(x) ischar(x) | iscellstr(x))
addParameter(par, 'DisplayInfo', 'text', @ischar)
addParameter(par, 'DebugEntry', [], @isnumeric)
parse(par, varargin{:});
tasks    = cellstr(par.Results.TaskNames);
prompt   = lower(par.Results.DisplayInfo);
dbentry  = par.Results.DebugEntry;
% throw an error when the specified path is not found
if ~exist(datapath, 'dir')
    fprintf(logfid, '[%s] Error: specified data path %s does not exist.\n', ...
        datestr(now),datapath);
    fclose(logfid);
    error('UDF:PREPROC:DATAFILEWRONG', 'Data path %s not found, please check!', datapath)
end
% remove empty task names from input parameter `tasks`
emptyTaskNameIdx = cellfun(@isempty, tasks);
tasks(emptyTaskNameIdx) = [];
% when debugging, only one task should be specified
if (all(emptyTaskNameIdx) || length(tasks) > 1) && ~isempty(dbentry)
    fprintf(logfid, '[%s] Error, not enough input parameters.\n', datestr(now));
    fclose(logfid);
    error('UDF:PREPROC:DEBUGWRONGPAR', '(Only one) task name must be set when using debug mode.');
end

% load settings, parameters and task names.
configpath = 'config';
readparas = {'FileEncoding', 'UTF-8', 'Delimiter', '\t'};
settings      = readtable(fullfile(configpath, 'settings.txt'), readparas{:});
para          = readtable(fullfile(configpath, 'para.txt'), readparas{:});
tasknames     = readtable(fullfile(configpath, 'taskname.txt'), readparas{:});
% setting name (TaskName) -> name used for settings
% original name (TaskOrigName) -> name used in raw data store
% chinese name (TaskCNName) -> name used in iquizoo product (in CN)
% ID name (taskIDName) -> name used for identifying the same task (in EN)
tasknameMapO  = containers.Map(tasknames.TaskOrigName, tasknames.TaskName);
tasknameMapC  = containers.Map(tasknames.TaskCNName, tasknames.TaskName);
taskIDNameMap = containers.Map(tasknames.TaskName, tasknames.TaskIDName);

% get all the task names to be preprocessed
% get all the data file informations, which are named after task names
datafiles = dir(datapath);
datafiles([datafiles.isdir]) = []; % folder exclusion
% get all the task names
datafilenames = {datafiles.name}';
datatasks = strrep(datafilenames, '.txt', '');
% set to preprocess all the tasks if not specified
if all(emptyTaskNameIdx), tasks = datatasks'; end
% check the status of existence for the to-be-processed tasks
%  1. Checking the existence in the original data.
dataExisted = ismember(tasks, datatasks) & ...
    (ismember(tasks, tasknames.TaskOrigName) | ismember(tasks, tasknames.TaskCNName));
if ~all(dataExisted)
    fprintf('Oops! Data of these tasks you specified are not found, will remove these tasks...\n');
    disp(tasks(~dataExisted))
    tasks(~dataExisted) = []; %Remove not found tasks.
end
%  2. Checking the existence in the settings.
taskNameTrans = tasks;
taskNameTrans(ismember(tasks, tasknames.TaskOrigName)) = values(tasknameMapO, taskNameTrans(ismember(tasks, tasknames.TaskOrigName)));
taskNameTrans(ismember(tasks, tasknames.TaskCNName)) = values(tasknameMapC, taskNameTrans(ismember(tasks, tasknames.TaskCNName)));
setExistence = ismember(taskNameTrans, settings.TaskName);
if ~all(setExistence)
    fprintf('Oops! Settings of these tasks you specified are not found, will remove these tasks...\n');
    disp(tasks(~setExistence))
    tasks(~setExistence) = []; %Remove not found tasks.
    taskNameTrans(~setExistence) = [];
end

% preallocation
ntasks4process = length(tasks);
TaskName       = reshape(tasks, ntasks4process, 1);
TaskIDName     = cell(ntasks4process, 1);
Data           = cell(ntasks4process, 1);
Time2Preproc   = repmat(cellstr('TBE'), ntasks4process, 1);
dataExtract = table(TaskName, TaskIDName, Data, Time2Preproc);
%Display the information of processing.
fprintf('Here it goes! The total jobs are composed of %d task(s), though some may fail...\n', ...
    ntasks4process);
%Use a waitbar to tell the processing information.
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
%Sheet-wise processing.
for itask = 1:ntasks4process
    initialVars = who;
    curTaskName = TaskName{itask};
    curTaskNameTrans = taskNameTrans{itask};
    %Update prompt information.
    %Get the proportion of completion and the estimated time of arrival.
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
            msg = sprintf('Task: %s. %s', taskIDNameMap(curTaskNameTrans), msgSuff);
            waitbar(completePercent, hwb, msg);
        case 'text'
            if ~except
                fprintf(repmat('\b', 1, length(dispinfo)));
            end
            dispinfo = sprintf('Now processing %s (total: %d) task: %s(%s). %s\n', ...
                num2ord(nprocessed + 1), ntasks4process, curTaskName, taskIDNameMap(curTaskNameTrans), msgSuff);
            fprintf(dispinfo);
            except = false;
    end
    %Find out the setting of current task.
    locset = ismember(settings.TaskName, curTaskNameTrans);
    if ~any(locset)
        fprintf(logfid, ...
            '[%s] No settings specified for task %s. Continue to the next task.\n', ...
            datestr(now), curTaskNameTrans);
        %Increment of ignored number of tasks.
        nignored = nignored + 1;
        continue
    end
    %Unpdate processed tasks number.
    nprocessed = nprocessed + 1;
    %Read in all the information from the specified file.
    curTaskData = readtable(fullfile(datapath, [curTaskName, '.txt']), readparas{:});
    %Check if the data fields are in the correct type.
    % vars checking settings.
    varsOfChk = {'Taskname', 'userId', 'name', 'gender|sex', 'school', 'grade', 'cls', 'birthDay', 'createDate|createTime', 'conditions'};
    varsOfChkClass = {'cell', 'double', 'cell', 'cell', 'cell', 'cell', 'cell', 'datetime', 'datetime', 'cell'};
    curTaskVars = curTaskData.Properties.VariableNames;
    for ivar = 1:length(varsOfChk)
        curVarOpts = split(varsOfChk{ivar}, '|');
        curVar = intersect(curVarOpts, curTaskVars);
        curClass = varsOfChkClass{ivar};
        if ~isempty(curVar) %For better compatibility.
            curVar = curVar{:}; % get the data in the cell as a charater.
            varsOfChk{ivar} = curVar;
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
    %Get the setting of current task.
    curTaskSetting = settings(locset, :);
    %Store the taskIDName.
    dataExtract.TaskIDName(itask) = curTaskSetting.TaskIDName;
    %Get a table curTaskCfg to combine two variables: conditions and para,
    %which are used in the function sngproc. See more in function sngproc.
    curTaskPara = para(ismember(para.TemplateToken, curTaskSetting.TemplateToken), :);
    if ~isempty(dbentry) % Read the debug entry only.
        curTaskData = curTaskData(dbentry, :);
        dbstop in sngpreproc
    end
    % construct a table for preprocessing using @sngpreproc.
    curTaskCfg = table;
    curTaskCfg.conditions = curTaskData.conditions;
    curTaskCfg.para = repmat({curTaskPara}, height(curTaskCfg), 1);
    cursplit = rowfun(@sngpreproc, curTaskCfg, 'OutputVariableNames', {'splitRes', 'status'});
    if isempty(cursplit)
        warning('UDF:PREPROC:DATAMISMATCH', 'No data found for task %s. Will keep it empty.', curTaskNameTrans);
        fprintf(logfid, ...
            '[%s] No data found for task %s.\r\n', datestr(now), curTaskNameTrans);
        except = true;
    else
        curTaskRes = cat(1, cursplit.splitRes{:});
        curTaskRes.status = cursplit.status;
        %Generate some warning according to the status.
        if any(cursplit.status ~= 0)
            except = true;
            warning('UDF:PREPROC:DATAMISMATCH', 'Oops! Data mismatch in task %s.', curTaskNameTrans);
            if any(cursplit.status == -1) %Data mismatch found.
                fprintf(logfid, ...
                    '[%s] Data mismatch encountered in task %s. Normally, its format is ''%s''.\r\n', ...
                    datestr(now), curTaskNameTrans, curTaskPara.VariablesNames{:});
            end
            if any(cursplit.status == -2) %Parameters for this task not found.
                fprintf(logfid, ...
                    '[%s] No parameters specification found in task %s.\r\n', ...
                    datestr(now), curTaskNameTrans);
            end
        end
        %Use curTaskRes as the results variable store. And store the TaskIDName
        %from settings, which is usually used in the following analysis.
        %out meta vars index.
        outMetaVarsIdx = 2:9;
        curTaskRes = curTaskData(:, ismember(curTaskVars, varsOfChk(outMetaVarsIdx)));
        %Store the spitting results.
        curTaskSplitRes = cat(1, cursplit.splitRes{:});
        curTaskSplitResVars = curTaskSplitRes.Properties.VariableNames;
        for ivar = 1:length(curTaskSplitResVars)
            curTaskRes.(curTaskSplitResVars{ivar}) = curTaskSplitRes.(curTaskSplitResVars{ivar});
        end
        curTaskSpVarOpts = strsplit(curTaskSetting.PreSpVar{:});
        curTaskSpecialVar = intersect(curTaskVars, curTaskSpVarOpts);
        for ivar = 1:length(curTaskSpecialVar)
            curTaskRes.(curTaskSpecialVar{ivar}) = curTaskData.(curTaskSpecialVar{ivar});
        end
        curTaskRes.status = cursplit.status;
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
