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

% add helper functions folder
helperFunPath = 'utilis';
addpath(helperFunPath);

% display notation message.
fprintf('Now extract information from raw data.\n');

% parse and check input arguments
par = inputParser;
addParameter(par, 'TaskNames', '', @(x) ischar(x) | iscellstr(x) | isstring(x) | isnumeric(x))
addParameter(par, 'DisplayInfo', 'text', @ischar)
addParameter(par, 'DebugEntry', [], @isnumeric)
parse(par, varargin{:});
taskInputNames = par.Results.TaskNames;
prompt = lower(par.Results.DisplayInfo);
dbentry = par.Results.DebugEntry;

% load settings, parameters, task names, etc.
configpath = 'config';
readparas = {'FileEncoding', 'UTF-8', 'Delimiter', '\t'};
settings = readtable(fullfile(configpath, 'settings.csv'), readparas{:});
para = readtable(fullfile(configpath, 'para.csv'), readparas{:});
taskNameStore = readtable(fullfile(configpath, 'taskname.csv'), readparas{:});
% metavars options
metavarNames = {'Taskname', 'userId', 'name', 'gender|sex', 'school', 'grade', 'cls', 'birthDay', 'createDate|createTime', 'conditions'};
metavarClasses = {'cell', 'double', 'cell', 'cell', 'cell', 'cell', 'cell', 'datetime', 'datetime', 'cell'};
% taskname and conditions are thrown away when storing metadata
outMetaVarsIdx = 2:9;

% throw an error when the specified path is not found
if ~exist(datapath, 'dir')
    fprintf(logfid, '[%s] Error: specified data path %s does not exist.\n', ...
        datestr(now),datapath);
    fclose(logfid);
    rmpath(helperFunPath)
    error('UDF:PREPROC:DATAFILEWRONG', 'Data path %s not found, please check!', datapath)
end
% get all the data file informations, which are named after task IDs
dataFiles = dir(datapath);
dataFiles([dataFiles.isdir]) = []; % folder exclusion
% get all the task ids
[~, dataTaskIDs] = cellfun(@fileparts, {dataFiles.name}', 'UniformOutput', false);
dataTaskIDs = str2double(dataTaskIDs);

% notice input name could be numeric array or cellstr type
inputNameIsEmpty = isempty(taskInputNames) || all(ismissing(taskInputNames));
% when debugging, only one task should be specified
if (inputNameIsEmpty || length(taskInputNames) > 1) && ~isempty(dbentry)
    fprintf(logfid, '[%s] Error, not enough input parameters.\n', datestr(now));
    fclose(logfid);
    rmpath(helperFunPath)
    error('UDF:PREPROC:DEBUGWRONGPAR', '(Only one) task name must be set when using debug mode.');
end
% set to preprocess all the tasks if not specified and not in debug mode
if inputNameIsEmpty
    fprintf('Detected no valid tasks are specified, will continue to process all tasks.\n');
    taskInputNames = dataTaskIDs;
end

% input task name validation and name transformation
[taskInputNames, taskIDs, taskIDNames] = tasknamechk(taskInputNames, taskNameStore, dataTaskIDs);

% variables for progressing statistics
ntasks4process = length(taskInputNames);
nprocessed = 0;
nignored = 0;

% preallocation
dataExtract = table(taskIDs, taskIDNames, ...
    cell(ntasks4process, 1), repmat(cellstr('TBE'), ntasks4process, 1), ...
    'VariableNames', {'TaskID', 'TaskIDName', 'Data', 'Time2Preproc'});

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

% display the information of processing.
fprintf('Here it goes! The total jobs are composed of %d task(s), though some may fail...\n', ...
    ntasks4process);

% record the time elapsed when preparation is done
elapsedTime = toc;

% preprocess task by task
for itask = 1:ntasks4process
    initialVars = who;

    % get current task names
    if isnumeric(taskInputNames)
        curTaskInputName = num2str(taskInputNames(itask));
    else
        curTaskInputName = taskInputNames{itask};
    end
    curTaskID = taskIDs(itask);
    curTaskIDName = taskIDNames{itask};
    curTaskDispName = sprintf('%s(%s)', curTaskInputName, curTaskIDName);

    % update prompt information.
    completePercent = nprocessed / ntasks4process;
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
                num2ord(nprocessed + 1), ntasks4process, ...
                curTaskDispName, msgSuff);
            fprintf(dispinfo);
            except = false;
    end
    % record progress in log file
    fprintf(logfid, '[%s] %s', datestr(now), dispinfo);
    % update processed tasks number.
    nprocessed = nprocessed + 1;

    % find out the setting of current task.
    locset = ismember(settings.TaskIDName, curTaskIDName);
    if ~any(locset)
        fprintf(logfid, ...
            '[%s] No settings specified for task %s. Continue to the next task.\n', ...
            datestr(now), curTaskDispName);
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
        fprintf(logfid, '[%s] Begin to debug, recording can be misleading.', datestr(now));
        dbstop in sngpreproc
    end

    % checking metadata type
    curTaskMetavarsRaw = curTaskData.Properties.VariableNames;
    curTaskMetavarsOpts = metavarNames;
    for imetavar = 1:length(curTaskMetavarsOpts)
        curMetavarOpts = split(curTaskMetavarsOpts{imetavar}, '|');
        curMetavarName = intersect(curMetavarOpts, curTaskMetavarsRaw);
        curMetavarClass = metavarClasses{imetavar};
        % check existed metavars only, will transform data to expected type
        if ~isempty(curMetavarName)
            curTaskMetavarsOpts(imetavar) = curMetavarName;
            curMetadataOrig = curTaskData.(curMetavarName{:});
            curMetadataTrans = curMetadataOrig;
            if ~isa(curMetadataOrig, curMetavarClass)
                switch curMetavarClass
                    case 'cell'
                        curMetadataTrans = num2cell(curMetadataOrig);
                    case 'double'
                        curMetadataTrans = str2double(curMetadataOrig);
                    case 'datetime'
                        if isnumeric(curMetadataOrig)
                            % not very good implementation
                            curMetadataOrig = repmat({''}, size(curMetadataOrig));
                        end
                        curMetadataTrans = datetime(curMetadataOrig);
                end
            end
            curTaskData.(curMetavarName{:}) = curMetadataTrans;
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
    % generate a table to store all the results
    curTaskRes = curTaskData(:, ismember(curTaskMetavarsRaw, curTaskMetavarsOpts(outMetaVarsIdx)));

    % check preprocessed results, warning if result is empty
    if isempty(curTaskPreRes)
        warning('UDF:PREPROC:DATAMISMATCH', 'No data found for task %s. Will keep it empty.', ...
            curTaskDispName);
        fprintf(logfid, ...
            '[%s] No data found for task %s.\r\n', ...
            datestr(now), curTaskDispName);
        except = true;
    else
        % generate some warning according to the status.
        if any(curTaskPreRes.status ~= 0)
            except = true;
            warning('UDF:PREPROC:DATAMISMATCH', 'Oops! Data mismatch in task %s.', curTaskDispName);
            if any(curTaskPreRes.status == -1) %Data mismatch found.
                fprintf(logfid, ...
                    '[%s] Data mismatch encountered in task %s. Normally, its format is ''%s''.\r\n', ...
                    datestr(now), curTaskDispName, curTaskPara.VariablesNames{:});
            end
            if any(curTaskPreRes.status == -2) %Parameters for this task not found.
                fprintf(logfid, ...
                    '[%s] No parameters specification found in task %s.\r\n', ...
                    datestr(now), curTaskDispName);
            end
        end

        % store the splitting results.
        curTaskRes = [curTaskRes, cat(1, curTaskPreRes.splitRes{:})]; %#ok<AGROW>

        % store special variables, e.g., 'alltime'
        curTaskSpVarOpts = strsplit(curTaskSetting.PreSpVar{:});
        curTaskSpVarNames = intersect(curTaskMetavarsRaw, curTaskSpVarOpts);
        curTaskRes = [curTaskRes, curTaskData(:, curTaskSpVarNames)]; %#ok<AGROW>

        % store the status of preprocessing
        curTaskRes.status = curTaskPreRes.status;
    end

    % store names, data and preprocess time
    dataExtract.TaskID(itask) = curTaskID;
    dataExtract.TaskIDName{itask} = curTaskIDName;
    dataExtract.Data{itask} = curTaskRes;
    dataExtract.Time2Preproc{itask} = seconds2human(toc - elapsedTime, 'full');

    % clear redundant variables to save storage
    clearvars('-except', initialVars{:});
end
% display information of completion.
fprintf('Congratulations! %d (succeeded) /%d (in total) preprocessing task(s) completed this time.\n', nprocessed - nignored, ntasks4process);
fprintf('Returning without error!\nTotal time used: %s\n', seconds2human(toc, 'full'));
% log the success
fprintf(logfid, '[%s] Completed preprocessing without error.\n', datestr(now));
fclose(logfid);
if strcmp(prompt, 'waitbar'), delete(hwb); end
rmpath(helperFunPath);
