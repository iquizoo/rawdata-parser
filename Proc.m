function resdata = Proc(dataExtract, varargin)
%PROC Does some basic computation on data.
%   RESDATA = PROC(DATA) does some basic analysis to the output of function
%   readsht. Including basic analysis.
%
%   See also PREPROC, SNGPROC.

%Zhang, Liang. 04/14/2016, E-mail:psychelzh@gmail.com.

% start stopwatch.
tic

% open a log file
logfid = fopen('proc(AutoGen).log', 'a');
fprintf(logfid, '[%s] Start processing.\n', datestr(now));

% parse and check input arguments.
par = inputParser;
addParameter(par, 'TaskNames', '', @(x) ischar(x) | iscellstr(x) | isstring(x))
addParameter(par, 'DisplayInfo', 'text', @ischar)
addParameter(par, 'DebugEntry', [], @isnumeric)
addParameter(par, 'Method', 'full', @ischar)
addParameter(par, 'RemoveAbnormal', true, @(x) islogical(x) | isnumeric(x))
parse(par, varargin{:});
tasks = cellstr(par.Results.TaskNames); % for table construction
prompt = lower(par.Results.DisplayInfo);
dbentry = par.Results.DebugEntry;
method = par.Results.Method;
rmanml = par.Results.RemoveAbnormal;
% remove empty task names from input parameter `tasks`
emptyTaskNameIdx = cellfun(@isempty, tasks);
tasks(emptyTaskNameIdx) = [];
% when debugging, only one task should be specified
if (all(emptyTaskNameIdx) || length(tasks) > 1) && ~isempty(dbentry)
    fprintf(logfid, '[%s] Error, not enough input parameters.\n', datestr(now));
    fclose(logfid);
    error('UDF:PREPROC:DEBUGWRONGPAR', 'Task name must be set when debugging.');
end

% load settings and get the task name mappings
configpath = 'config';
readparas = {'FileEncoding', 'UTF-8', 'Delimiter', '\t'};
settings      = readtable(fullfile(configpath, 'settings.csv'), readparas{:});
tasknamestore = readtable(fullfile(configpath, 'taskname.csv'), readparas{:});
% setting name (TaskName) -> name used for settings
% original name (TaskOrigName) -> name used in raw data store
% chinese name (TaskCNName) -> name used in iquizoo product (in CN)
% ID name (taskIDName) -> name used for identifying the same task (in EN)
tasknameMapO  = containers.Map(tasknamestore.TaskOrigName, tasknamestore.TaskName);
tasknameMapC  = containers.Map(tasknamestore.TaskCNName, tasknamestore.TaskName);
taskIDNameMap = containers.Map(settings.TaskName, settings.TaskIDName);

% display notation message.
fprintf('Now do some basic computation and transformation to the extracted data.\n');
% remove tasks without any data from the input data table
dataExtract(cellfun(@isempty, dataExtract.Data), :) = [];

% get the list of to-be-processed `tasks` in the form of original name
% set to process all the task if `tasks` is not specified
if all(emptyTaskNameIdx), tasks = dataExtract.TaskName; end
% transformation of task names in case of different specification
tasks = dataExtract.TaskName(ismember(dataExtract.TaskName, tasks) | ...
    ismember(dataExtract.TaskIDName, tasks));
% remove not existing tasks
dataExisted = ismember(tasks, dataExtract.TaskName);
if ~all(dataExisted)
    fprintf('Oops! Data of these tasks you specified are not found, will remove these tasks...\n');
    disp(tasks(~dataExisted))
    tasks(~dataExisted) = [];
end

% use `taskNames` to store all the setting names
taskNames = tasks;
%  1. transform specific names to settings task names (in CN)
taskNames(ismember(tasks, tasknamestore.TaskOrigName)) = ...
    values(tasknameMapO, taskNames(ismember(tasks, tasknamestore.TaskOrigName)));
%  2. transform settings task names to ID names
taskNames(ismember(tasks, tasknamestore.TaskCNName)) = ...
    values(tasknameMapC, taskNames(ismember(tasks, tasknamestore.TaskCNName)));

% count all the to-be-processed tasks
task4processIdx = find(ismember(dataExtract.TaskName, tasks));
ntasks4process = length(task4processIdx);
fprintf('OK! The total jobs are composed of %d task(s), though some may fail...\n', ...
    ntasks4process);

%Determine the prompt type and initialize for prompt.
switch prompt
    case 'waitbar'
        hwb = waitbar(0, 'Begin processing the tasks specified by users...Please wait...', ...
            'Name', 'Process the data extracted of CCDPro',...
            'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
        setappdata(hwb, 'canceling', 0)
    case 'text'
        except  = false;
        dispinfo = '';
end

% variables used for logging and rate of progress
nprocessed = 0;
nignored = 0;
elapsedTime = toc;

% add a field to record time used to process each task
dataExtract.Time2Proc = repmat(cellstr('TBE'), height(dataExtract), 1);

% add helper functions path
anafunpath = 'utilis';
addpath(anafunpath);

% process extracted data task-wise
for itask = 1:ntasks4process
    initialVarsTask = who;
    curtaskidx = task4processIdx(itask);

    % extract current task data
    if ~isempty(dbentry)
        % DEBUG MODE: read the debug entry only
        curTaskData = dataExtract.Data{curtaskidx}(dbentry, :);
        dbstop in sngproc
    else
        curTaskData = dataExtract.Data{curtaskidx};
    end

    % name setting and analysis preparation
    curTaskOrigName = dataExtract.TaskName{curtaskidx};
    curTaskName = taskNames{itask};
    curTaskSetting = settings(ismember(settings.TaskName, curTaskName), :);
    curTaskName = curTaskSetting.TaskIDName{:};
    % get all the analysis variables.
    anaVars = strsplit(curTaskSetting.AnalysisVars{:});
    % merge conditions
    mrgCond = strsplit(curTaskSetting.MergeCond{:});

    % prompt setting
    %  1. get the proportion of completion and estimated time of arrival
    completePercent = nprocessed / ntasks4process;
    if nprocessed == 0
        msgSuff = 'Please wait...';
    else
        elapsedTime = toc;
        eta = seconds2human(elapsedTime * (1 - completePercent) / completePercent, 'full');
        msgSuff = strcat('TimeRem:', eta);
    end
    %  2. update prompt message
    switch prompt
        case 'waitbar'
            % Check for Cancel button press
            if getappdata(hwb, 'canceling')
                fprintf('%d basic analysis task(s) completed this time. User canceled...\n', nprocessed);
                break
            end
            %Update message in the waitbar.
            msg = sprintf('Task(%d/%d): %s. %s', itask, ntasks4process, taskIDNameMap(curTaskName), msgSuff);
            waitbar(completePercent, hwb, msg);
        case 'text'
            if ~except
                fprintf(repmat('\b', 1, length(dispinfo)));
            end
            dispinfo = sprintf('Now processing %s (total: %d) task: %s(%s). %s\n', ...
                num2ord(nprocessed + 1), ntasks4process, curTaskOrigName, taskIDNameMap(curTaskName), msgSuff);
            fprintf(dispinfo);
            except = false;
    end
    % processed tasks count
    nprocessed = nprocessed + 1;

    % get the number of conditions and subjects for future use
    nvar = length(anaVars);
    nsubj = height(curTaskData);

    % preallocation
    anares = cell(nsubj, nvar);
    curTaskData.res = cell(nsubj, 1);
    curTaskData.index = nan(nsubj, 1);

    % some tasks (e.g., divAtten) have data of multiple conditions stored
    % in multiple variables, it is useful to process them condition
    % (variable) by condition
    for ivar = 1:nvar
        curAnaVar = anaVars{ivar};
        curMrgCond = mrgCond{ivar};

        % skip when data not correct recorded
        if isempty(curAnaVar) ...
                || ~ismember(curAnaVar, curTaskData.Properties.VariableNames) ...
                || all(cellfun(@isempty, curTaskData.(curAnaVar)))
            fprintf(logfid, ...
                '[%s] No correct recorded data is found in task %s. Will ignore this task. Aborting...\n', ...
                datestr(now), curTaskName);
            warning('No correct recorded data is found in task %s. Will ignore this task. Aborting...', ...
                curTaskName);
            nignored = nignored + 1;
            except   = true;
            continue
        end

        % preparation: construct input arguments for sngproc
        %  1. parameters
        %   1.1 common parameters
        procPara = {'TaskSetting', curTaskSetting, 'Condition', curMrgCond, 'Method', method, 'RemoveAbnormal', rmanml};
        %   1.2 specific parameters
        switch curTaskName
            case {'Symbol', 'Orthograph', 'Tone', 'Pinyin', 'Lexic', 'Semantic', ...%langTasks
                    'GNGLure', 'GNGFruit', ...%some of otherTasks in NSN.
                    'Flanker', ...%Conflict
                    }
                % get taskSTIMMap (STIM->SCat) for these tasks.
                curTaskEncode  = readtable(fullfile(configpath, [curTaskName, '.csv']), readparas{:});
                curTaskSTIMMap = containers.Map(curTaskEncode.STIM, curTaskEncode.SCat);
                procPara       = [procPara, {'StimulusMap', curTaskSTIMMap}]; %#ok<AGROW>
            case {'SemanticMemory'}
                % set stimulus category for each trial of this task
                if strcmp(curAnaVar, 'TEST')
                    oldStims = cellfun(@(tbl) tbl.STIM, curTaskData.STUDY, 'UniformOutput', false);
                    testStims = cellfun(@(tbl) tbl.STIM, curTaskData.TEST, 'UniformOutput', false);
                    for isubj = 1:nsubj
                        SCat = double(ismember(testStims{isubj}, oldStims{isubj}));
                        if isempty(SCat)
                            curTaskData.TEST{isubj}.SCat = zeros(0, 1);
                        else
                            curTaskData.TEST{isubj}.SCat = SCat;
                        end
                    end
                end
        end
        %  2. analysis variables in which data is stored
        spAnaVar = strsplit(curTaskSetting.PreSpVar{:}); % special variables, can be empty
        curAnaVars = horzcat(curAnaVar, spAnaVar);
        curAnaVars(cellfun(@isempty, curAnaVars)) = [];

        % begin processing not by a for loop but `rowfun`
        anares(:, ivar) = rowfun(@(varargin) sngproc(varargin{:}, procPara{:}), ...
            curTaskData, 'InputVariables', curAnaVars, ...
            'ExtractCellContents', true, 'OutputFormat', 'cell');
    end
    % in case of multiple conditions, merge multiple conditions
    if nvar > 1
        anares = arrayfun(@(isubj) {horzcat(anares{isubj, :})}, 1:nsubj);
    end

    % deal with empty results
    emptySubIdx = cellfun(@isempty, anares);
    % skip if all the results are empty
    if all(emptySubIdx)
        fprintf(logfid, ...
            '[%s] No valid results found in task %s. Will ignore this task. Aborting...\n', ...
            datestr(now), curTaskName);
        warning('No valid results found in task %s. Will ignore this task. Aborting...', curTaskName);
        nignored = nignored + 1;
        except   = true;
        continue
    end
    % remove empty results
    anares(emptySubIdx) = [];
    restbl = cat(1, anares{:});
    allresvars = restbl.Properties.VariableNames;
    % get the ultimate index (now only support one index)
    ultIndexVar = curTaskSetting.UltimateIndex{:};
    ultIndex    = nan(height(restbl), 1);
    if ~isempty(ultIndexVar)
        switch ultIndexVar
            case 'ConflictUnion'
                conflictCondVars = strsplit(curTaskSetting.VarsCond{:});
                conflictVars = strcat(strsplit(curTaskSetting.VarsCat{:}), '_', conflictCondVars{end});
                restbl{rowfun(@(x) any(isnan(x), 2), restbl, ...
                    'InputVariables', conflictVars, ...
                    'SeperateInputs', false, ...
                    'OutputFormat', 'uniform'), :} = nan;
                conflictZ = varfun(@(x) (x - nanmean(x)) / nanstd(x), restbl, 'InputVariables', conflictVars);
                ultIndex = rowfun(@(varargin) sum([varargin{:}]), conflictZ, 'OutputFormat', 'uniform');
            case 'dprimeUnion'
                indexMateVar = ~cellfun(@isempty, regexp(allresvars, 'dprime', 'once'));
                ultIndex = rowfun(@(varargin) sum([varargin{:}]), restbl, 'InputVariables', indexMateVar, 'OutputFormat', 'uniform');
            otherwise
                ultIndex = restbl.(ultIndexVar);
        end
    end
    % store analysis results
    curTaskData.res(~emptySubIdx) = anares;
    curTaskData.index(~emptySubIdx) = ultIndex;
    dataExtract.Data{curtaskidx} = curTaskData;
    % store the time used
    curTaskTimeUsed = toc - elapsedTime;
    dataExtract.Time2Proc{curtaskidx} = seconds2human(curTaskTimeUsed, 'full');
    clearvars('-except', initialVarsTask{:});
end

% remove tasks having no results (skipped when processing)
resdata = dataExtract(task4processIdx, :);
resdata(cellfun(@(tbl) ~ismember('res', tbl.Properties.VariableNames), resdata.Data), :) = [];
% display information of completion.
usedTimeSecs = toc;
usedTimeHuman = seconds2human(usedTimeSecs, 'full');
fprintf('Congratulations! %d basic analysis task(s) completed this time.\n', nprocessed - nignored);
fprintf('Returning without error!\nTotal time used: %s\n', usedTimeHuman);
% log the success
fprintf('[%s] Completed processing without error.', datestr(now));
fclose(logfid);
if strcmp(prompt, 'waitbar'), delete(hwb); end
rmpath(anafunpath);
