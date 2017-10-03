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
HELPERFUNPATH = 'scripts';
addpath(HELPERFUNPATH);

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

% the data strings are stored in `DATAVARNAME`
DATAVARNAME = 'data';
% the original data are stored in format `DATAFORMAT`
DATAFORMAT = '.csv';
% configuration path and reading arguments
CONFIGPATH = 'config';
READPARAS = {'Encoding', 'UTF-8', 'Delimiter', '\t'};
% metavartype settings
METAVARNAMES = {'Taskname', 'excerciseId', 'userId', 'name', 'sex', 'school', 'grade', 'cls', 'birthDay', 'createTime'};
METAVARTYPES = {'string', 'double', 'double', 'string', 'categorical', 'string', 'string', 'string', 'datetime', 'datetime'};
% valid 'sex' characters
SEXMALE = {'male', 'Male', 'MALE', 'm', 'M', 'ÄÐ'};
SEXFEMALE = {'female', 'Female', 'FEMALE', 'f', 'F', 'Å®'};
SEXES = {'male', 'female'};

% load settings
settings = readtable(fullfile(CONFIGPATH, 'settings.csv'), READPARAS{:});
para = readtable(fullfile(CONFIGPATH, 'para.csv'), READPARAS{:});
taskNameStore = readtable(fullfile(CONFIGPATH, 'taskname.csv'), READPARAS{:});

% throw an error when the specified path is not found
if ~exist(datapath, 'dir')
    fprintf(logfid, '[%s] Error: specified data path %s does not exist.\n', ...
        datestr(now),datapath);
    fclose(logfid);
    rmpath(HELPERFUNPATH)
    error('UDF:PREPROC:DATAFILEWRONG', 'Data path %s not found, please check!', datapath)
end
% get all the data file informations, which are named after task IDs
dataFiles = dir(fullfile(datapath, ['*', DATAFORMAT]));
% get all the task ids
[~, dataTaskIDs] = cellfun(@fileparts, {dataFiles.name}', 'UniformOutput', false);
dataTaskIDs = str2double(dataTaskIDs);

% notice input name could be numeric array or cellstr type
inputNameIsEmpty = isempty(taskInputNames) || all(ismissing(taskInputNames));
inputNameNotSingle = (isnumeric(taskInputNames) && length(taskInputNames) > 1) || ...
    (~isnumeric(taskInputNames) && length(cellstr(taskInputNames)) > 1);
% when debugging, only one task should be specified
if (inputNameIsEmpty || inputNameNotSingle) && ~isempty(dbentry)
    fprintf(logfid, '[%s] Error, not enough input parameters.\n', datestr(now));
    fclose(logfid);
    rmpath(HELPERFUNPATH)
    error('UDF:PREPROC:DEBUGWRONGPAR', '(Only one) task name must be set when using debug mode.');
end
% set to preprocess all the tasks if not specified and not in debug mode
if inputNameIsEmpty
    fprintf('Detected no valid tasks are specified, will continue to process all tasks.\n');
    taskInputNames = dataTaskIDs;
end

% input task name validation and name transformation
[taskInputNamesFull, taskIDs, taskIDNames] = tasknamechk(taskInputNames, taskNameStore, dataTaskIDs);

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
% variables for progressing statistics
ntasks4process = length(taskInputNamesFull);
nprocessed = 0;

% display the information of processing.
fprintf('Here it goes! The total jobs are composed of %d task(s), though some may fail...\n', ...
    ntasks4process);

% preallocation
dataExtract = table(taskIDs, taskIDNames, ...
    cell(ntasks4process, 1), repmat(cellstr('TBE'), ntasks4process, 1), ...
    'VariableNames', {'TaskID', 'TaskIDName', 'Data', 'Time2Preproc'});

% record the time elapsed when preparation is done
prepartionTime = toc;

% preprocess task by task
for itask = 1:ntasks4process
    initialVars = who;

    % get current task names
    if isnumeric(taskInputNamesFull)
        curTaskInputName = num2str(taskInputNamesFull(itask));
    else
        curTaskInputName = taskInputNamesFull{itask};
    end
    curTaskID = taskIDs(itask);
    curTaskIDName = taskIDNames{itask};
    curTaskDispName = sprintf('%s(%s)', curTaskInputName, curTaskIDName);

    % update prompt information.
    completePercent = nprocessed / ntasks4process;
    elapsedTime = toc - prepartionTime;
    if nprocessed == 0
        msgSuff = 'Please wait...';
    else
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
        continue
    end
    curTaskSetting = settings(locset, :);

    % read raw data file.
    curTaskFile = fullfile(datapath, [num2str(curTaskID), '.csv']);
    opts = detectImportOptions(curTaskFile, READPARAS{:});
    opts = setvartype(opts, METAVARNAMES, METAVARTYPES);
    curTaskData = readtable(curTaskFile, opts);
    % when in debug mode, read the debug entry only
    if ~isempty(dbentry)
        curTaskData = curTaskData(dbentry, :);
        fprintf(logfid, '[%s] Begin to debug, recording can be misleading.', datestr(now));
        dbstop in sngpreproc
    end

    % extract data string and replace it with the generated one
    curTaskDatastr = curTaskData.(DATAVARNAME);
    curTaskData.(DATAVARNAME) = [];
    % check data string, warning if it is empty
    if all(cellfun(@isempty, curTaskDatastr))
        warning('UDF:PREPROC:DATAMISMATCH', 'No data found for task %s. Will keep it empty.', ...
            curTaskDispName);
        fprintf(logfid, ...
            '[%s] No data found for task %s.\n', ...
            datestr(now), curTaskDispName);
        except = true;
    else
        curTaskPara = para(ismember(para.TemplateToken, curTaskSetting.TemplateToken), :);
        [trialrec, status] = cellfun(@(datastr) sngpreproc(datastr, curTaskPara), curTaskDatastr);
        curTaskData = [curTaskData, cat(1, trialrec{:})]; %#ok<AGROW>
        % generate some warning and logs according to the status.
        if any(status ~= 0)
            except = true;
            warning('UDF:PREPROC:DATAMISMATCH', 'Data mismatch encountered in task %s.', curTaskDispName);
            % parameter settings for this task not found.
            if any(status == -1)
                fprintf(logfid, ...
                    '[%s] No parameter settings specification found in task %s.\n', ...
                    datestr(now), curTaskDispName);
            end
            % data missing for some subjects
            if any(status == -2)
                fprintf(logfid, ...
                    '[%s] Data for some users lost in task %s.\n', ...
                    datestr(now), curTaskDispName);
            end
            % data ill-formatted
            if any(status == -3)
                fprintf(logfid, ...
                    '[%s] Data are ill-formatted for some users in task %s.\n', ...
                    datestr(now), curTaskDispName);
            end
        end
        curTaskData.status = status;
    end
    
    % check all the real metadata
    for iMetavar = 1:length(METAVARNAMES)
        curMetavarName = METAVARNAMES{iMetavar};
        curMetadata = curTaskData.(curMetavarName);
        metaTypeTransFailed = false;
        switch curMetavarName
            case {'name', 'school'}
                % remove spaces in the names because they are in Chinese
                curMetadata = regexprep(curMetadata, '\s+', '');
            case {'grade', 'cls'}
                % try to transform non-digit string to digit string
                nondigitLoc = ~cellfun(@all, isstrprop(curMetadata, 'digit', 'ForceCellOutput', true));
                nondigitMetadata = curMetadata(nondigitLoc);
                transMetadata = cellfun(@cn2digit, nondigitMetadata);
                nanTransLoc = isnan(transMetadata);
                if any(nanTransLoc)
                    % some entries cannot be correctly transformed
                    metaTypeTransFailed = true;
                    msg = 'Failing: string to numeric, will use raw string for NaN locations.';
                end
                transMetadata(nanTransLoc) = nondigitMetadata(nanTransLoc);
                transMetadata(~nanTransLoc) = string(transMetadata(~nanTransLoc));
                curMetadata(nondigitLoc) = transMetadata;
                % change grade and cls data to categorical type
                curMetadata = categorical(curMetadata);
            case 'sex'
                % merge certain sex categories
                curMetadata = mergecats(curMetadata, SEXMALE);
                curMetadata = mergecats(curMetadata, SEXFEMALE);
                % remove all categories not in 'SEXES'
                curMetadata = setcats(curMetadata, SEXES);
        end
        % display warning/error message in case failed
        if metaTypeTransFailed
            fprintf(logfid, ...
                '[%s] Some cases of `%s` metadata failed to transform. %s\n', ...
                datestr(now), curMetavarName, msg);
        end
        curTaskData.(curMetavarName) = curMetadata;
    end

    % store names, data and preprocess time
    dataExtract.TaskID(itask) = curTaskID;
    dataExtract.TaskIDName{itask} = curTaskIDName;
    dataExtract.Data{itask} = curTaskData;
    dataExtract.Time2Preproc{itask} = seconds2human(toc - elapsedTime, 'full');

    % clear redundant variables to save storage
    clearvars('-except', initialVars{:});
end
% display information of completion.
fprintf('Congratulations! %d (succeeded) /%d (in total) preprocessing task(s) completed this time.\n', nprocessed, ntasks4process);
fprintf('Returning without error!\nTotal time used: %s\n', seconds2human(toc, 'full'));
% log the success
fprintf(logfid, '[%s] Completed preprocessing without error.\n', datestr(now));
fclose(logfid);
if strcmp(prompt, 'waitbar'), delete(hwb); end
rmpath(HELPERFUNPATH);
