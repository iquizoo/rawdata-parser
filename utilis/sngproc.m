function res = sngproc(rec, varargin)
%SNGPROC forms a wrapper function to compute those single task statistics.
%     res = SNGPROC(rec, tasksettings) does basic computation job for
%     most of the tasks when no SCat(have a look at the data to see what SCat
%     is) modification is needed. Locally, RT cutoffs, NaN cleaning and other
%     miscellaneous tasks to prepare data for processing.
%
%     res = SNGPROC(rec, tasksettings, Name, Value) provides parameters input
%     by Name, Value pairs. Possible pairs are as follows:
%             'Condition' - specifies the condition of the data, especially
%                           for divided attention tasks, which have a left
%                           and a right conditions.
%           'StimulusMap' - specifies the mapping between the stimulus type
%                           and encode type for specific tasks.
%                'Method' - can be 'full', 'odd', or 'even', which specifies
%                           the specific trials used in the analysis.
%        'RemoveAbnormal' - true or false, specifies whether to remove those
%                           subjects who behave abnormally, for example, the
%                           accuracy lower than chance level.
%
%     See also sngprocBART, sngprocEZDiff, sngprocConflict, sngprocMemrep,
%     sngprocMemsep, sngprocMentcompare, sngprocMentcompute, sngprocNSN,
%     sngprocNback, sngprocSRT, sngprocSpan

%   By Zhang, Liang. 05/03/2016, E-mail:psychelzh@gmail.com

% Parse input arguments.
par = inputParser;
par.KeepUnmatched = true;
addOptional(par, 'TotalTime', NaN, @isnumeric);
parNames   = {'TaskSetting', 'Condition',  'StimulusMap', 'Method',         'RemoveAbnormal'        };
parDflts   = {  table,          [],            [],        'full',                true               };
parValFuns = {   @istable,     @ischar,   @isobject,     @ischar, @(x) islogical(x) | isnumeric(x)  };
cellfun(@(x, y, z) addParameter(par, x, y, z), parNames, parDflts, parValFuns);
parse(par, varargin{:});
TotalTime    = par.Results.TotalTime;
tasksettings = par.Results.TaskSetting;
resvarsuff   = par.Results.Condition;
taskSTIMMap  = par.Results.StimulusMap;
method       = par.Results.Method;
rmanml       = par.Results.RemoveAbnormal;
% Get all the output variable names.
% coupleVars are formatted out variables.
varscat = strsplit(tasksettings.VarsCat{:});
varscond = strsplit(tasksettings.VarsCond{:});
if all(cellfun(@isempty, varscond))
    delimiterVC = '';
else
    delimiterVC = '_';
end
cpvars = strcat(repmat(varscat, 1, length(varscond)), delimiterVC, ...
    repelem(varscond, 1, length(varscat)));
% further required variables.
sngvars = strsplit(tasksettings.VarsFull{:});
% Out variables names are composed by three part.
outvars = [cpvars, sngvars];
% Remove empty strings.
outvars(cellfun(@isempty, outvars)) = [];
% Preallocation.
comres = table; % Short of common results. Results calculated from analysis function, if existed.
spres = table; % Short of special results. Results calculated in current function.
% Remove NaN (not a number) or empty (char of ASCII 0) trials.
cellRec = table2cell(rec);
chkStatus = cellfun(@all, cellfun(@(x) isnan(x) | double(x) == 0, cellRec, ...
    'UniformOutput', false));
rmRows = all(chkStatus, 2); % Remove rows of only nan or 0 char.
rec(rmRows, :) = [];
task = tasksettings.TaskIDName{:};
nonRTRecTasks = {...
    'Reading', ...
    'SusAtten', ...
    'ForSpan', 'BackSpan', 'SpatialSpan', 'MemoryTail', ...
    'Jigsaw1', 'Jigsaw2', ...
    'BART', 'TMT'};
if ismember(task, nonRTRecTasks)
    switch task
        case {'SusAtten', 'ForSpan', 'BackSpan', 'SpatialSpan'} % Span
            % Some of the recording does not include SLen (Stimuli
            % Length) as one of their variable, get it here.
            if ~ismember('SLen', rec.Properties.VariableNames)
                if ~isempty(rec)
                    rec.SLen = cellfun(@length, rec.SSeries);
                else
                    rec.SLen = zeros(0);
                end
            end
        case 'Reading'
            if ~exist('TotalTime', 'var')
                TotalTime = 5 * 60 * 1000; % 5 min
            end
        case 'TMT'
            rec.SCat = cellfun(@length, rec.STIM);
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
    switch task
        case {'Symbol', 'Orthograph', 'Tone', 'Pinyin', 'Lexic', 'Semantic', ...% langTasks
                'GNGLure', 'GNGFruit', ...% GNG tasks
                'Flanker', ...% Part of EF tasks
                } % SCat modification required tasks.
            % left -> 1, right -> 2.
            assert(~isempty(taskSTIMMap), ...
                'UDF:CCDPRO:SNGPROC:STIMULUSMAP', 'Stimulus map must be specified.');
            rec = mapSCat(rec, taskSTIMMap);
            % Get the total used time (unit: ms).
            if ~exist('TotalTime', 'var')
                TotalTime = sum(rec.RT);
            end
        case {'SpeedAdd', 'SpeedSubtract', ...% Math tasks
                'DigitCmp', 'Subitizing', ...% Another two math tasks.
                }
            % All the trials require response.
            stimvars = {'S1', 'S2'};
            rec.SCat = rowfun(@(x, y) abs(x - y), rec, 'InputVariables', stimvars, 'OutputFormat', 'uniform');
            % Get the total used time (unit: min).
            if ~exist('TotalTime', 'var')
                TotalTime = sum(rec.RT);
            end
        case {'SRT', 'CRT'}
            % All the trials require response.
            rec.SCat = ones(height(rec), 1);
            % Transform: 'l'/'1' -> 1 , 'r'/'2' -> 2, then fix ACC record.
            rec.STIM = (ismember(rec.STIM,  'r') | ismember(rec.STIM,  '2')) + 1;
            rec.ACC = rec.STIM == rec.Resp;
        case {'SRTWatch', 'SRTBread', ... % Two alternative SRT task.
                'AssocMemory', ... %  Exclude 'SemanticMemory', ...% Memory task.
                }
            % All the trials require response.
            rec.SCat = ones(height(rec), 1);
        case {'DRT', ...% DRT
                'DivAtten1', 'DivAtten2', ...% DA
                }
            % Find out the no-go stimulus.
            NGSTIM = findNG(rec, tasksettings.NRRT);
            % For SCat: Go -> 1, NoGo -> 0.
            rec.SCat = ~ismember(rec.STIM, NGSTIM);
        case 'CPT2'
            % Note: only 'C' following 'B' is Go(target) trial.
            % Get all the candidate go trials.
            GoTrials = find(strcmp(rec.STIM, 'C'));
            % 'C' appears at the first trial will not be a target.
            GoTrials(GoTrials == 1) = [];
            % 'C's that are not following 'B' should be excluded.
            isFollowB = strcmp(rec.STIM(GoTrials - 1) , 'B');
            GoTrials(~isFollowB) = [];
            % Add a field 'SCat', 1 -> go, 0 -> nogo.
            rec.SCat = zeros(height(rec), 1);
            rec.SCat(GoTrials) = 1;
        case {'NumStroop', 'Stroop1', 'Stroop2'}
            % Replace SCat 0 with 2.
            rec.SCat(rec.SCat == 0) = 2;
        case {'PicMemory', 'WordMemory', 'SymbolMemory'}
            % Replace SCat 0 with 3.
            rec.SCat(rec.SCat == 0) = 3;
        case {'Nback1', 'Nback2'} % Nback
            % Remove trials that no response is needed.
            rec(rec.CResp == -1, :) = [];
            % All the trials require response.
            rec.SCat = ones(height(rec), 1);
        case 'TaskSwitching'
            rec.SCat(1) = 0;
        case 'DCCS'
            rec.SCat(1:12:48) = 0;
        case {'Filtering', 'Filtering2'}
            if ~all(ismember(rec.SCat, 1:3))
                for row = 1:height(rec)
                    ntar = rec.NTar(row);
                    ndis = rec.NDis(row);
                    if ntar == 2 && ndis == 2
                        SCat = 1;
                    elseif ntar == 4 && ndis == 0
                        SCat = 2;
                    else
                        SCat = 3;
                    end
                    rec.SCat(row) = SCat;
                end
            end
    end % switch
    % Set the ACC of abnormal trials (RT) as -1.
    rec.ACC((rec.RT < tasksettings.RTmin & rec.RT ~= 0) | ... % Too short RTs
        (rec.RT > tasksettings.RTmax & rec.RT ~= tasksettings.NRRT)) = -1; % Too long RTs
    % Set the ACC of no response trials which require response as -1 for
    % those tasks which need a response for each trial.
    if tasksettings.RespRequired
        rec.ACC(rec.RT == tasksettings.NRRT & rec.SCat ~= 0) = -1;
    end
end % if
% Compute now.
if ~isempty(rec)
    % Check if split is used.
    method = lower(method);
    if ~strcmp(method, 'full')
        switch method
            case 'odd'
                starttrl = 1;
            case 'even'
                starttrl = 2;
        end
        rec = rec(starttrl:2:end, :);
    end
    % Record the total time used if required.
    if ismember('TotalTime', outvars)
        spres.TotalTime = TotalTime;
    end
    % Record the number of correct trials if required.
    if ismember('CountAccTrl', outvars)
        spres.CountAccTrl = sum(rec.ACC == 1);
    end
    % Set the score.
    if ismember('ACC', rec.Properties.VariableNames)
        % Record the total valid trials.
        spres.CountTotalTrl = sum(rec.ACC ~= -1);
        % Total score and mean score (per minute).
        if ismember('MeanScore', outvars)
            % Set field Score from ACC: 1 -> 1, 0 -> -1, -1 -> 0, use a
            % quadratic curve to transform.
            rec.Score = 1.5 * rec.ACC .^ 2 + 0.5 * rec.ACC - 1;
            TotalScore = sum(rec.Score);
            spres.TotalScore = TotalScore;
            if ~exist('TotalTime', 'var') || TotalTime == 0 % TotalTime is unknown!
                spres.MeanScore = nan;
            else
                spres.MeanScore = TotalScore / (TotalTime / (1000 * 60));
            end
        end
    end
    anafunsuff = tasksettings.AnalysisFun{:};
    if ~isempty(anafunsuff)
        % Note: sngproc means 'single task processing'.
        anafunstr = ['sngproc', anafunsuff];
        anafun = str2func(anafunstr);
        switch nargin(anafunstr)
            case 1
                comres = anafun(rec);
            case 4
                comres = anafun(rec, varscat, delimiterVC, varscond);
        end
    end
    res = cat(2, comres, spres);
    % Get all the variable names of current res table.
    curTaskResVarNames = res.Properties.VariableNames;
    if rmanml
        % Treat mean RT of less than 300ms/larger than 2500ms as missing.
        MRTvars = curTaskResVarNames(~cellfun(@isempty, ...
            regexp(curTaskResVarNames, '^M?RT(?!_CongEffect|_SwitchCost|_FA)', 'once')));
        for irtvar = 1:length(MRTvars)
            if res.(MRTvars{irtvar}) < tasksettings.RTmin || res.(MRTvars{irtvar}) > tasksettings.RTmax
                res{:, :} = nan;
                break
            end
        end
        % Treat ACC_Overall of below chance level as missing.
        ACCvars = curTaskResVarNames(~cellfun(@isempty, ...
            regexp(curTaskResVarNames, '^ACC$|^ACC(?!_CongEffect|_SwitchCost)|^Rate_Overall', 'once')));
        for iaccvar = 1:length(ACCvars)
            if res.(ACCvars{iaccvar}) < tasksettings.ChanceACC
                res{:, :} = nan;
                break
            end
        end
    end
    if ~isempty(outvars)
        res(:, ~ismember(curTaskResVarNames, outvars)) = [];
        missVars = outvars(~ismember(outvars, curTaskResVarNames));
        for imiss = 1:length(missVars)
            res.(missVars{imiss}) = nan;
        end
    end
else
    res = array2table(nan(1, length(outvars)), 'VariableNames', outvars);
end % if ~isempty(RECORD)
% Add the suffix to the results table variable names if not empty.
if ~isempty(resvarsuff)
    res.Properties.VariableNames = strcat(res.Properties.VariableNames, ...
        '_', resvarsuff);
end
end

function RECORD = mapSCat(RECORD, taskSTIMMap)
% Modify variable SCat of RECORD and return it.

if ~iscell(RECORD.STIM)
    RECORD.STIM = num2cell(RECORD.STIM);
end
chkSTIM = isKey(taskSTIMMap, RECORD.STIM);
if all(chkSTIM)
    % Reshape is used to maintain the structure of data type in case the
    % RECORD is empty, then cell2mat will change the structure of data type.
    RECORD.SCat = reshape(cell2mat(values(taskSTIMMap, RECORD.STIM)), size(RECORD.STIM));
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
