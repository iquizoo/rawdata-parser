function res = Proc(data, varargin)
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
HELPERFUNPATH = 'scripts';
addpath(HELPERFUNPATH);

% display notation message.
fprintf('Now do some basic computation and transformation to the extracted data.\n');
% remove tasks without any data from the input data table
data(cellfun(@isempty, data.Data), :) = [];

% load settings, task names.
CONFIGPATH = 'config';
READPARAS = {'Encoding', 'UTF-8', 'Delimiter', '\t'};
settings = readtable(fullfile(CONFIGPATH, 'settings.csv'), READPARAS{:});
taskNameStore = readtable(fullfile(CONFIGPATH, 'taskname.csv'), READPARAS{:});
% key metavars
KEYMETAVARS = {'userId', 'createTime'};

% parse and check input arguments.
par = inputParser;
addParameter(par, 'TaskNames', '', @(x) ischar(x) | iscellstr(x) | isstring(x) | isnumeric(x))
addParameter(par, 'DisplayInfo', 'text', @ischar)
addParameter(par, 'DebugEntry', [], @isnumeric)
addParameter(par, 'Method', 'full', @ischar)
addParameter(par, 'RemoveAbnormal', false, @(x) islogical(x) | isnumeric(x))
parse(par, varargin{:});
taskInputNames = par.Results.TaskNames;
prompt = lower(par.Results.DisplayInfo);
dbentry = par.Results.DebugEntry;
method = par.Results.Method;
rmanml = par.Results.RemoveAbnormal;

% notice input name could be numeric array or cellstr type
inputNameIsEmpty = isempty(taskInputNames) || all(ismissing(taskInputNames));
inputNameNotSingle = (isnumeric(taskInputNames) && length(taskInputNames) > 1) || ...
    (~isnumeric(taskInputNames) && length(cellstr(taskInputNames)) > 1);
% when debugging, only one task should be specified
if (inputNameIsEmpty || inputNameNotSingle) && ~isempty(dbentry)
    fprintf(logfid, '[%s] Error, not enough input parameters.\n', datestr(now));
    fclose(logfid);
    error('UDF:PREPROC:DEBUGWRONGPAR', '(Only one) task name must be set when debugging.');
end
% set to process all the tasks if not specified and not in debug mode
if inputNameIsEmpty
    fprintf('Detected no valid tasks are specified, will continue to process all tasks.\n');
    taskInputNames = data.TaskID;
end

% input task name validation and name transformation
[taskInputNames, taskIDs, taskIDNames] = tasknamechk(taskInputNames, taskNameStore, data.TaskID);

% variables used for logging and rate of progress
ntasks4process = length(taskInputNames);
nprocessed = 0;
nignored = 0;
processed = true(ntasks4process, 1);

% add a field to record time used to process each task
data.Time2Proc = repmat(cellstr('TBE'), height(data), 1);

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
prepartionTime = toc;

% process extracted data task-wise
for itask = 1:ntasks4process
    initialVarsTask = who;

    % get current task names and index in dataExtract
    if isnumeric(taskInputNames)
        curTaskInputName = num2str(taskInputNames(itask));
    else
        curTaskInputName = taskInputNames{itask};
    end
    curTaskID = taskIDs(itask);
    curTaskIDName = taskIDNames{itask};
    curTaskDispName = sprintf('%s(%s)', curTaskInputName, curTaskIDName);
    curtaskidx = ismember(data.TaskID, curTaskID);

    % get current task index in raw data and extract current task data
    curTaskData = data.Data{curtaskidx};
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
    elapsedTime = toc - prepartionTime;
    if nprocessed == 0
        msgSuff = 'Please wait...';
    else
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

    nonRTRecTasks = {...
        'Reading', ...
        'SusAtten', ...
        'ForSpan', 'BackSpan', 'SpatialSpan', 'MemoryTail', ...
        'Jigsaw1', 'Jigsaw2', ...
        'BART', 'TMT'};
    if ismember(curTaskIDName, nonRTRecTasks)
        switch curTaskIDName
            case {'SusAtten', 'ForSpan', 'BackSpan', 'SpatialSpan'} % Span
                % Some of the recording does not include SLen (Stimuli
                % Length) as one of their variable, get it here.
                if ~ismember('SLen', curTaskData.Properties.VariableNames)
                    if ~isempty(curTaskData)
                        curTaskData.SLen = cellfun(@length, curTaskData.SSeries);
                    else
                        curTaskData.SLen = zeros(0);
                    end
                end
            case 'Reading'
                if ~exist('TotalTime', 'var')
                    TotalTime = 5 * 60 * 1000; % 5 min
                end
            case 'TMT'
                curTaskData.SCat = cellfun(@length, curTaskData.STIM);
        end
    else
        % Unifying modification to some of the variables in RECORD.
        %    1. For ACC: incorrect -> 0, missing -> -1, correct -> 1.
        %    2. For SCat: (unify in order that 0 represents no response is
        %    required)
        %      2.1 nontarget -> 0, target -> 1.
        %      2.2 congruent -> 1, incongruent -> 2 (originally 0).
        %      2.3 left(target-like) -> 1, right(nontarget-like) -> 2.
        %      2.4 old -> 1, similar -> 2, new -> 3 (originally 0).
        %      2.5 complex -> 1 (means all trials need a response).
        %    3. For Score: incorrect -> -1, missing -> 0, correct -> 1.
        switch curTaskIDName
            case {'Symbol', 'Orthograph', 'Tone', 'Pinyin', 'Lexic', 'Semantic', ...% langTasks
                    'GNGLure', 'GNGFruit', ...% GNG tasks
                    'Flanker', ...% Part of EF tasks
                    } % SCat modification required tasks.
                % get taskSTIMMap (STIM->SCat) for these tasks.
                curTaskEncode  = readtable(fullfile(CONFIGPATH, [curTaskIDName, '.csv']), READPARAS{:});
                curTaskSTIMMap = containers.Map(curTaskEncode.STIM, curTaskEncode.SCat);
                % left -> 1, right -> 2.
                assert(~isempty(curTaskSTIMMap), ...
                    'UDF:CCDPRO:SNGPROC:STIMULUSMAP', 'Stimulus map must be specified.');
                curTaskData = mapSCat(curTaskData, curTaskSTIMMap);
                % Get the total used time (unit: ms).
                if ~exist('TotalTime', 'var')
                    TotalTime = sum(curTaskData.RT);
                end
            case {'SpeedAdd', 'SpeedSubtract', ...% Math tasks
                    'DigitCmp', 'Subitizing', ...% Another two math tasks.
                    }
                % All the trials require response.
                stimvars = {'S1', 'S2'};
                curTaskData.SCat = rowfun(@(x, y) abs(x - y), curTaskData, 'InputVariables', stimvars, 'OutputFormat', 'uniform');
                % Get the total used time (unit: min).
                if ~exist('TotalTime', 'var')
                    TotalTime = sum(curTaskData.RT);
                end
            case {'SRT', 'CRT'}
                % All the trials require response.
                curTaskData.SCat = ones(height(curTaskData), 1);
                % Transform: 'l'/'1' -> 1 , 'r'/'2' -> 2, then fix ACC record.
                curTaskData.STIM = (ismember(curTaskData.STIM,  'r') | ismember(curTaskData.STIM,  '2')) + 1;
                curTaskData.ACC = curTaskData.STIM == curTaskData.Resp;
            case {'SRTWatch', 'SRTBread', ... % Two alternative SRT task.
                    'AssocMemory', ... %  Exclude 'SemanticMemory', ...% Memory task.
                    }
                % All the trials require response.
                curTaskData.SCat = ones(height(curTaskData), 1);
            case {'DRT', ...% DRT
                    'DivAtten1', 'DivAtten2', ...% DA
                    }
                % Find out the no-go stimulus.
                NGSTIM = findNG(curTaskData, curTaskSetting.NRRT);
                % For SCat: Go -> 1, NoGo -> 0.
                curTaskData.SCat = ~ismember(curTaskData.STIM, NGSTIM);
            case 'CPT2'
                % Note: only 'C' following 'B' is Go(target) trial.
                % Get all the candidate go trials.
                GoTrials = find(strcmp(curTaskData.STIM, 'C'));
                % 'C' appears at the first trial will not be a target.
                GoTrials(GoTrials == 1) = [];
                % 'C's that are not following 'B' should be excluded.
                isFollowB = strcmp(curTaskData.STIM(GoTrials - 1) , 'B');
                GoTrials(~isFollowB) = [];
                % Add a field 'SCat', 1 -> go, 0 -> nogo.
                curTaskData.SCat = zeros(height(curTaskData), 1);
                curTaskData.SCat(GoTrials) = 1;
            case {'NumStroop', 'Stroop1', 'Stroop2'}
                % Replace SCat 0 with 2.
                curTaskData.SCat(curTaskData.SCat == 0) = 2;
            case {'PicMemory', 'WordMemory', 'SymbolMemory'}
                % Replace SCat 0 with 3.
                curTaskData.SCat(curTaskData.SCat == 0) = 3;
            case {'Nback1', 'Nback2'} % Nback
                % Remove trials that no response is needed.
                curTaskData(curTaskData.CResp == -1, :) = [];
                % All the trials require response.
                curTaskData.SCat = ones(height(curTaskData), 1);
            case 'TaskSwitching'
                curTaskData.SCat(1) = 0;
            case 'DCCS'
                curTaskData.SCat(1:12:48) = 0;
            case {'Filtering', 'Filtering2'}
                % set the ACC of no response trials as -1.
                curTaskData.ACC(curTaskData.Resp == -1) = -1;
                if ~all(ismember(curTaskData.SCat, 1:3))
                    for row = 1:height(curTaskData)
                        ntar = curTaskData.NTar(row);
                        ndis = curTaskData.NDis(row);
                        if ntar == 2 && ndis == 2
                            SCat = 1;
                        elseif ntar == 4 && ndis == 0
                            SCat = 2;
                        else
                            SCat = 3;
                        end
                        curTaskData.SCat(row) = SCat;
                    end
                end
        end % switch
        % Set the ACC of abnormal trials (RT) as -1.
        curTaskData.ACC((curTaskData.RT < curTaskSetting.RTmin & curTaskData.RT ~= 0) | ... % Too short RTs
            (curTaskData.RT > curTaskSetting.RTmax & curTaskData.RT ~= curTaskSetting.NRRT)) = -1; % Too long RTs
        % Set the ACC of no response trials which require response as -1 for
        % those tasks which need a response for each trial.
        if curTaskSetting.RespRequired
            curTaskData.ACC(curTaskData.RT == curTaskSetting.NRRT & curTaskData.SCat ~= 0) = -1;
        end
    end

    %% FIX ME: adapt to the new flattening structure
    % get the number of conditions and subjects for future use
    nanavar = length(anaVars);
    nuser = height(curTaskData);

    % preallocation
    anares = cell(nuser, nanavar);

    % some tasks (e.g., divAtten) have data of multiple conditions stored
    % in multiple variables, it is useful to process them condition
    % (variable) by condition
    for ianavar = 1:nanavar
        initialVarsCond = who;
        curAnaVars = anaVars{ianavar};
        curMrgCond = mrgCond{ianavar};

        % skip when data not correct recorded
        if isempty(curAnaVars) ...
                || ~ismember(curAnaVars, curTaskData.Properties.VariableNames) ...
                || all(cellfun(@isempty, curTaskData.(curAnaVars)))
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
                curTaskEncode  = readtable(fullfile(CONFIGPATH, [curTaskIDName, '.csv']), READPARAS{:});
                curTaskSTIMMap = containers.Map(curTaskEncode.STIM, curTaskEncode.SCat);
                procPara       = [procPara, {'StimulusMap', curTaskSTIMMap}]; %#ok<AGROW>
            case {'SemanticMemory'}
                % set stimulus category for each trial of this task
                if strcmp(curAnaVars, 'TEST')
                    oldStims = cellfun(@(tbl) tbl.STIM, curTaskData.STUDY, 'UniformOutput', false);
                    testStims = cellfun(@(tbl) tbl.STIM, curTaskData.TEST, 'UniformOutput', false);
                    for iuser = 1:nuser
                        SCat = double(ismember(testStims{iuser}, oldStims{iuser}));
                        if isempty(SCat)
                            curTaskData.TEST{iuser}.SCat = zeros(0, 1);
                        else
                            curTaskData.TEST{iuser}.SCat = SCat;
                        end
                    end
                end
        end
        %  2. analysis variables in which data is stored
        spAnaVar = strsplit(curTaskSetting.PreSpVar{:});
        if ~isempty(spAnaVar{:})
            curAnaVars = horzcat(curAnaVars, spAnaVar); %#ok<AGROW>
        end

        % begin processing not by a for loop but `rowfun`
        anares(:, ianavar) = rowfun(@(varargin) sngproc(varargin{:}, procPara{:}), ...
            curTaskData, 'InputVariables', curAnaVars, ...
            'ExtractCellContents', true, 'OutputFormat', 'cell');

        % clear the vars in the loop only
        clearvars('-except', initialVarsCond{:})
    end
    % remove raw records and status (it is for the raw record only)
    curTaskData(:, horzcat(anaVars, 'status')) = [];
    % in case of multiple conditions, merge multiple conditions
    if nanavar > 1
        anares = arrayfun(@(isubj) {horzcat(anares{isubj, :})}, 1:nuser);
    end

    % deal with empty results
    emptyUserIdx = cellfun(@isempty, anares);
    % skip if all the results are empty
    if all(emptyUserIdx)
        fprintf(logfid, ...
            '[%s] No valid results found in task %s. Will ignore this task. Aborting...\n', ...
            datestr(now), curTaskDispName);
        warning('No valid results found in task %s. Will ignore this task. Aborting...', curTaskDispName);
        nignored = nignored + 1;
        processed(itask) = false;
        except   = true;
        continue
    end
    % remove all the users with empty results
    anares(emptyUserIdx) = [];
    curTaskData(emptyUserIdx, :) = [];
    % extract contents from the cell output
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
    curTaskData.index = ultIndex;
    curTaskData = [curTaskData, restbl]; %#ok<AGROW>
    data.Data{curtaskidx} = curTaskData;
    % store the time used
    data.Time2Proc{curtaskidx} = seconds2human(toc - elapsedTime, 'full');

    % clear redundant variables to save storage
    clearvars('-except', initialVarsTask{:});
end

% remove all the not processed tasks
res = data(ismember(data.TaskIDName, taskIDNames(processed)), :);

% display information of completion.
fprintf('Congratulations! %d (succeeded) /%d (in total) processing task(s) completed this time.\n', nprocessed, ntasks4process);
fprintf('Returning without error!\nTotal time used: %s\n', seconds2human(toc, 'full'));

% log the success
fprintf(logfid, '[%s] Completed processing without error.\n', datestr(now));
fclose(logfid);
if strcmp(prompt, 'waitbar'), delete(hwb); end
rmpath(HELPERFUNPATH);
end

function RECORD = mapSCat(RECORD, taskSTIMMap)
% Modify variable SCat of RECORD and return it.

STIM = RECORD.STIM;
if ~iscell(STIM)
    STIM = num2cell(STIM);
end
chkSTIM = isKey(taskSTIMMap, STIM);
if all(chkSTIM)
    % Reshape is used to maintain the structure of data type in case the
    % RECORD is empty, then cell2mat will change the structure of data type.
    RECORD.SCat = reshape(cell2mat(values(taskSTIMMap, STIM)), size(STIM));
else % In this case, some of stimuli are not right, and delete all the instances.
    RECORD(:, :) = [];
end
end

function NGSTIM = findNG(RECORD, criterion)
% For some of the tasks, no-go stimuli is not predifined.

% Get all the stimuli.
allSTIM = unique(RECORD.STIM);
% For the newer version of DRT data, when response is required and the
% subject responded with an incorrect key, remove that trial because these
% trials might confuse the determination of nogo stimuli.
if isnum(allSTIM) && ismember('Resp', RECORD.Properties.VariableNames)
    % DRT of newer version detected.
    % Amend the ACC records.
    if ischar(RECORD.STIM)
        RECORD.Resp = num2str(RECORD.Resp);
        RECORD(RECORD.Resp ~= '0' & RECORD.STIM ~= RECORD.Resp, :) = [];
    else
        RECORD(RECORD.Resp ~= 0 & RECORD.STIM ~= RECORD.Resp, :) = [];
    end
end
% Find out no-go stimulus.
if ~isempty(allSTIM)
    firstTrial = RECORD(1, :);
    firstIsGo = ~xor(firstTrial.ACC == 1, firstTrial.RT < criterion);
    firstTrialInfo = allSTIM == firstTrial.STIM;
    % Here is an interesting way to find out no-go stimulus.
    NGSTIM = allSTIM(xor(firstTrialInfo, firstIsGo));
else
    NGSTIM = [];
end
end

function r = isnum(a)
%Determine if a is a numeric string, or numeric data.
if (isnumeric(a))
    r = 1;
else
    o = str2double(a);
    r = ~isnan(o);
end
end
