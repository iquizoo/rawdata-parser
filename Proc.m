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

% add helper functions path
helperFunPath = 'utilis';
addpath(helperFunPath);

% display notation message.
fprintf('Now do some basic computation and transformation to the extracted data.\n');
% remove tasks without any data from the input data table
dataExtract(cellfun(@isempty, dataExtract.Data), :) = [];

% load settings, task names.
configpath = 'config';
readparas = {'FileEncoding', 'UTF-8', 'Delimiter', '\t'};
settings = readtable(fullfile(configpath, 'settings.csv'), readparas{:});
taskNameStore = readtable(fullfile(configpath, 'taskname.csv'), readparas{:});

% parse and check input arguments.
par = inputParser;
addParameter(par, 'TaskNames', '', @(x) ischar(x) | iscellstr(x) | isstring(x) | isnumeric(x))
addParameter(par, 'DisplayInfo', 'text', @ischar)
addParameter(par, 'DebugEntry', [], @isnumeric)
addParameter(par, 'Method', 'full', @ischar)
addParameter(par, 'RemoveAbnormal', true, @(x) islogical(x) | isnumeric(x))
parse(par, varargin{:});
taskInputNames = par.Results.TaskNames;
prompt = lower(par.Results.DisplayInfo);
dbentry = par.Results.DebugEntry;
method = par.Results.Method;
rmanml = par.Results.RemoveAbnormal;

% notice input name could be numeric array or cellstr type
inputNameIsEmpty = isempty(taskInputNames) || all(ismissing(taskInputNames));
% when debugging, only one task should be specified
if (inputNameIsEmpty || length(taskInputNames) > 1) && ~isempty(dbentry)
    fprintf(logfid, '[%s] Error, not enough input parameters.\n', datestr(now));
    fclose(logfid);
    error('UDF:PREPROC:DEBUGWRONGPAR', 'Task name must be set when debugging.');
end
% set to process all the tasks if not specified and not in debug mode
if inputNameIsEmpty
    fprintf('Detected no valid tasks are specified, will continue to process all tasks.\n');
    taskInputNames = dataExtract.TaskID;
end

% input task name validation and name transformation
[taskInputNames, ~, taskIDNames] = tasknamechk(taskInputNames, taskNameStore, dataExtract.TaskID);

% variables used for logging and rate of progress
ntasks4process = length(taskInputNames);
nprocessed = 0;
nignored = 0;
processed = true(ntasks4process, 1);

% add a field to record time used to process each task
dataExtract.Time2Proc = repmat(cellstr('TBE'), height(dataExtract), 1);

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

% display the message of processing.
fprintf('OK! The total jobs are composed of %d task(s), though some may fail...\n', ...
    ntasks4process);

% record the time elapsed when preparation is done
elapsedTime = toc;

% process extracted data task-wise
for itask = 1:ntasks4process
    initialVarsTask = who;

    % get current task names and index in dataExtract
    if isnumeric(taskInputNames)
        curTaskInputName = num2str(taskInputNames(itask));
    else
        curTaskInputName = taskInputNames{itask};
    end
    curTaskIDName = taskIDNames{itask};
    curTaskDispName = sprintf('%s(%s)', curTaskInputName, curTaskIDName);
    curtaskidx = ismember(dataExtract.TaskIDName, curTaskIDName);

    % get current task index in raw data and extract current task data
    curTaskData = dataExtract.Data{curtaskidx};
    if ~isempty(dbentry)
        % DEBUG MODE: read the debug entry only
        curTaskData = curTaskData(dbentry, :);
        dbstop in sngproc
    end

    % name setting and analysis preparation
    curTaskSetting = settings(ismember(settings.TaskIDName, curTaskIDName), :);
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
            msg = sprintf('Task(%d/%d): %s. %s', itask, ntasks4process, curTaskIDName, msgSuff);
            waitbar(completePercent, hwb, msg);
        case 'text'
            if ~except
                fprintf(repmat('\b', 1, length(dispinfo)));
            end
            dispinfo = sprintf('Now processing %s (total: %d) task: %s. %s\n', ...
                num2ord(nprocessed + 1), ntasks4process, curTaskDispName, msgSuff);
            fprintf(dispinfo);
            except = false;
    end
    % record progress in log file
    fprintf(logfid, '[%s] %s', datestr(now), dispinfo);
    % processed tasks count
    nprocessed = nprocessed + 1;

    % get the number of conditions and subjects for future use
    nanavar = length(anaVars);
    nsubj = height(curTaskData);

    % preallocation
    anares = cell(nsubj, nanavar);
    curTaskData.res = cell(nsubj, 1);
    curTaskData.index = nan(nsubj, 1);

    % some tasks (e.g., divAtten) have data of multiple conditions stored
    % in multiple variables, it is useful to process them condition
    % (variable) by condition
    for ianavar = 1:nanavar
        curAnaVar = anaVars{ianavar};
        curMrgCond = mrgCond{ianavar};

        % skip when data not correct recorded
        if isempty(curAnaVar) ...
                || ~ismember(curAnaVar, curTaskData.Properties.VariableNames) ...
                || all(cellfun(@isempty, curTaskData.(curAnaVar)))
            fprintf(logfid, ...
                '[%s] No correct recorded data is found in task %s. Will ignore this task. Aborting...\n', ...
                datestr(now), curTaskDispName);
            warning('No correct recorded data is found in task %s. Will ignore this task. Aborting...', ...
                curTaskDispName);
            nignored = nignored + 1;
            processed(itask) = false;
            except   = true;
            continue
        end

        % preparation: construct input arguments for sngproc
        %  1. parameters
        %   1.1 common parameters
        procPara = {'TaskSetting', curTaskSetting, 'Condition', curMrgCond, 'Method', method, 'RemoveAbnormal', rmanml};
        %   1.2 specific parameters
        switch curTaskIDName
            case {'Symbol', 'Orthograph', 'Tone', 'Pinyin', 'Lexic', 'Semantic', ...%langTasks
                    'GNGLure', 'GNGFruit', ...%some of otherTasks in NSN.
                    'Flanker', ...%Conflict
                    }
                % get taskSTIMMap (STIM->SCat) for these tasks.
                curTaskEncode  = readtable(fullfile(configpath, [curTaskIDName, '.csv']), readparas{:});
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
        anares(:, ianavar) = rowfun(@(varargin) sngproc(varargin{:}, procPara{:}), ...
            curTaskData, 'InputVariables', curAnaVars, ...
            'ExtractCellContents', true, 'OutputFormat', 'cell');
    end

    % in case of multiple conditions, merge multiple conditions
    if nanavar > 1
        anares = arrayfun(@(isubj) {horzcat(anares{isubj, :})}, 1:nsubj);
    end

    % deal with empty results
    emptySubIdx = cellfun(@isempty, anares);
    % skip if all the results are empty
    if all(emptySubIdx)
        fprintf(logfid, ...
            '[%s] No valid results found in task %s. Will ignore this task. Aborting...\n', ...
            datestr(now), curTaskDispName);
        warning('No valid results found in task %s. Will ignore this task. Aborting...', curTaskDispName);
        nignored = nignored + 1;
        processed(itask) = false;
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
    dataExtract.Time2Proc{curtaskidx} = seconds2human(toc - elapsedTime, 'full');

    % clear redundant variables to save storage
    clearvars('-except', initialVarsTask{:});
end

% remove all the not processed tasks
resdata = dataExtract(ismember(dataExtract.TaskIDName, taskIDNames(processed)), :);

% display information of completion.
fprintf('Congratulations! %d (succeeded) /%d (in total) processing task(s) completed this time.\n', nprocessed - nignored, ntasks4process);
fprintf('Returning without error!\nTotal time used: %s\n', seconds2human(toc, 'full'));

% log the success
fprintf(logfid, '[%s] Completed processing without error.\n', datestr(now));
fclose(logfid);
if strcmp(prompt, 'waitbar'), delete(hwb); end
rmpath(helperFunPath);
