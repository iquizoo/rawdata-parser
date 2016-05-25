function res = sngproc(rec, tasksettings, resvarsuff, taskSTIMMap, method)
%SNGPROC forms a wrapper function to compute those single task statistics.
%   RES = SNGPROC(SPLITRES, TASKSETTING) does basic computation job for
%   most of the tasks when no SCat(have a look at the data to see what SCat
%   is) modification is needed. Locally, RT cutoffs, NaN cleaning and other
%   miscellaneous tasks to prepare data for processing.
%   RES = SNGPROC(SPLITRES, TASKSETTING, TASKSTIMMAP) adds a map container
%   for modification of SCat in RECORD.
%   RES = SNGPROC(SPLITRES, TASKSETTING, TASKSTIMMAP, METHOD) adds a method
%   to calculate odd trials or even trials only.
%
%   See also sngstatsBART, sngstatsCRT, sngstatsConflict, sngstatsMemrep,
%   sngstatsMemsep, sngstatsMentcompare, sngstatsMentcompute, sngstatsNSN,
%   sngstatsNback, sngstatsSRT, sngstatsSpan

%By Zhang, Liang. 05/03/2016, E-mail:psychelzh@gmail.com

%Initialization jobs.
if nargin < 5
    method = 'full';
end
%Get all the output variable names.
%coupleVars are formatted out variables.
varscat = strsplit(tasksettings.VarsCat{:});
varscond = strsplit(tasksettings.VarsCond{:});
if all(cellfun(@isempty, varscond))
    delimiterVC = '';
else
    delimiterVC = '_';
end
cpvars = strcat(repmat(varscat, 1, length(varscond)), delimiterVC, ...
    repelem(varscond, 1, length(varscat)));
%further required variables.
sngvars = [strsplit(tasksettings.SingletonVars{:}), strsplit(tasksettings.SingletonVarsCP{:})];
spvars = strsplit(tasksettings.SpecialVars{:});
%Out variables names are composed by three part.
outvars = [cpvars, sngvars, spvars];
%Remove empty strings.
outvars(cellfun(@isempty, outvars)) = [];
%Preallocation.
comres = table; %Short of common results. Results calculated from analysis function, if existed.
spres = table; %Short of special results. Results calculated in current function.
RECORD = rec{:};
%Remove NaN (not a number) or empty (char of ASCII 0) trials.
cellRec = table2cell(RECORD);
chkStatus = cellfun(@all, cellfun(@(x) isnan(x) | double(x) == 0, cellRec, ...
    'UniformOutput', false));
rmRows = all(chkStatus, 2); %Remove rows of only nan or 0 char.
RECORD(rmRows, :) = [];
task = tasksettings.TaskIDName{:};
nonRTRecTasks = {...
    'Reading', ...
    'SusAtten', ...
    'ForSpan', 'BackSpan', 'SpatialSpan', ...
    'Jigsaw1', 'Jigsaw2', ...
    'BART'};
if ismember(task, nonRTRecTasks)
    switch task
        case {'SusAtten', 'ForSpan', 'BackSpan', 'SpatialSpan'} %Span
            %Some of the recording does not include SLen (Stimuli
            %Length) as one of their variable, get it here.
            if ~ismember('SLen', RECORD.Properties.VariableNames)
                RECORD.SLen = cellfun(@length, RECORD.SSeries);
            end
            %Some of the recording does not include Next as one
            %variable, get it here.
            if ~ismember('Next', RECORD.Properties.VariableNames)
                RECORD.Next = [diff(RECORD.SLen); 0];
            end
        case 'Reading'
            TotalTime = 5 * 60 * 1000; %5 min
    end
else
    %Unifying modification to some of the variables in RECORD.
    %   1. For ACC: incorrect -> 0, missing -> -1, correct -> 1.
    %   2. For SCat: (unify in order that 0 represents no response is
    %   required)
    %     2.1 nontarget -> 0, target -> 1.
    %     2.2 congruent -> 1, incongruent -> 2 (originally 0).
    %     2.3 left(target-like) -> 1, right(nontarget-like) -> 2.
    %     2.4 old -> 1, similar -> 2, new -> 3 (originally 0).
    %     2.5 complex -> 1 (means all trials need a response).
    %   3. For Score: incorrect -> -1, missing -> 0, correct -> 1.
    switch task
        case {'Symbol', 'Orthograph', 'Tone', 'Pinyin', 'Lexic', 'Semantic', ...%langTasks
                'GNGLure', 'GNGFruit', ...%GNG tasks
                'Flanker', 'TaskSwitching', ...%Part of EF tasks
                } %SCat modification required tasks.
            %left -> 1, right -> 2.
            RECORD = mapSCat(RECORD, taskSTIMMap);
            %Get the total used time (unit: min).
            TotalTime = sum(RECORD.RT);
        case {'SpeedAdd', 'SpeedSubtract', ...%Math tasks
                'DigitCmp', 'Subitizing', ...%Another two math tasks.
                }
            %All the trials require response.
            stimvars = {'S1', 'S2'};
            RECORD.SCat = rowfun(@(x, y) abs(x - y), RECORD, 'InputVariables', stimvars, 'OutputFormat', 'uniform');
            %Get the total used time (unit: min).
            TotalTime = sum(RECORD.RT);
        case {'SRT', 'CRT'}
            %All the trials require response.
            RECORD.SCat = ones(height(RECORD), 1);
            %Transform: 'l'/'1' -> 1 , 'r'/'2' -> 2, then fix ACC record.
            RECORD.STIM = (RECORD.STIM ==  'r' | RECORD.STIM ==  '2') + 1;
            RECORD.ACC = RECORD.STIM == RECORD.Resp;
        case {'SRTWatch', 'SRTBread', ... %Two alternative SRT task.
                'AssocMemory', 'SemanticMemory', ...%Memory task.
                }
            %All the trials require response.
            RECORD.SCat = ones(height(RECORD), 1);
        case {'DRT', ...%DRT
                'DivAtten1', 'DivAtten2', ...%DA
                }
            %Find out the no-go stimulus.
            NGSTIM = findNG(RECORD, tasksettings.NRRT);
            %For SCat: Go -> 1, NoGo -> 0.
            RECORD.SCat = ~ismember(RECORD.STIM, NGSTIM);
        case 'CPT2'
            %Note only 'C' which is followed by 'B' is Go(target) trial
            GoTrials = strcmp(RECORD.STIM, 'C');
            %'C' appears at the first trial will not be a target.
            if ismember(find(GoTrials), 1)
                GoTrials(1) = false;
            end
            isFollowB = strcmp(RECORD.STIM(circshift(GoTrials, -1)) , 'B');
            %'C' not followed by 'B' should be excluded.
            GoTrials(~isFollowB) = false;
            %Add a field 'SCat', 1 -> go, 0 -> nogo.
            RECORD.SCat = zeros(height(RECORD), 1);
            RECORD.SCat(GoTrials) = 1;
        case {'NumStroop', 'Stroop1', 'Stroop2'}
            %Replace SCat 0 with 2.
            RECORD.SCat(RECORD.SCat == 0) = 2;
        case {'PicMemory', 'WordMemory'}
            %Replace SCat 0 with 3.
            RECORD.SCat(RECORD.SCat == 0) = 3;
        case {'Nback1', 'Nback2'} %Nback
            %Remove trials that no response is needed.
            RECORD(RECORD.CResp == -1, :) = [];
            %All the trials require response.
            RECORD.SCat = ones(height(RECORD), 1);
    end %switch
    %Set the ACC of abnormal trials (RT) as -1.
    RECORD.ACC((RECORD.RT < 100 & RECORD.RT ~= 0) | ... %Too short RTs
        (RECORD.RT > 2500 & RECORD.RT ~= tasksettings.NRRT)) = -1; %Too long RTs
    %Set the ACC of no response trials which require response as -1.
    RECORD.ACC(RECORD.RT == tasksettings.NRRT & RECORD.SCat ~= 0) = -1;
end %if
%Compute now.
if ~isempty(RECORD)
    %Check if split is used.
    method = lower(method);
    if ~strcmp(method, 'full')
        switch method
            case 'odd'
                starttrl = 1;
            case 'even'
                starttrl = 2;
        end
        RECORD = RECORD(starttrl:2:end, :);
    end
    %Record the total trials if required.
    if ismember('CountTotalTrl', outvars)
        spres.CountTotalTrl = height(RECORD);
    end
    %Record the total time used if required.
    if ismember('TotalTime', outvars)
        spres.TotalTime = TotalTime;
    end
    %Record the number of correct trials if required.
    if ismember('CountAccTrl', outvars)
        spres.CountAccTrl = sum(RECORD.ACC == 1);
    end
    %Set the score.
    if ismember('ACC', RECORD.Properties.VariableNames)
        %Set field Score from ACC: 1 -> 1, 0 -> -1, -1 -> 0, use a
        %quadratic curve to transform.
        RECORD.Score = 1.5 * RECORD.ACC .^ 2 + 0.5 * RECORD.ACC - 1;
        %Total score and mean score (per minute).
        if ismember('TotalScore', outvars)
            TotalScore = sum(RECORD.Score);
            spres.TotalScore = TotalScore;
            if ~exist('TotalTime', 'var') || TotalTime == 0 %TotalTime is unknown!
                spres.MeanScore = nan;
            else
                spres.MeanScore = TotalScore / (TotalTime / (1000 * 60));
            end
        end
    end
    anafunsuff = tasksettings.AnalysisFun{:};
    if ~isempty(anafunsuff)
        %Note: sngstats means 'single task processing'.
        anafunstr = ['sngproc', anafunsuff];
        anafun = str2func(anafunstr);
        switch nargin(anafunstr)
            case 1
                comres = anafun(RECORD);
            case 4
                comres = anafun(RECORD, varscat, delimiterVC, varscond);
        end
    end
    res = [comres, spres];
    %Caculate the scores of each task.
    scorefunsuff = tasksettings.ScoringFun{:};
    scorevars   = strsplit(tasksettings.ScoringVars{:});
    score = nan;
    if ~isempty(scorefunsuff)
        scorefunstr = ['sngscore', scorefunsuff];
        scorefun    = str2func(scorefunstr);
        if ~isempty(tasksettings.ScoringPara{:})
            scoreparas  = cellfun(@str2double, strsplit(tasksettings.ScoringPara{:}), 'UniformOutput', false);
            score = rowfun(@(varargin) scorefun(varargin{:}, scoreparas{:}), res, ...
                'InputVariables', scorevars, 'OutputFormat', 'uniform');
        else
            score = rowfun(@(varargin) scorefun(varargin{:}), res, ...
                'InputVariables', scorevars, 'OutputFormat', 'uniform');
        end
    end
    res(:, ~ismember(res.Properties.VariableNames, outvars)) = [];
    missVars = outvars(~ismember(outvars, res.Properties.VariableNames));
    for imiss = 1:length(missVars)
        res.(missVars{imiss}) = nan;
    end
else
    res = array2table(nan(1, length(outvars)), 'VariableNames', outvars);
    score = nan;
end %if ~isempty(RECORD)
res.score = score;
%Treat mean RT of any condition is less than 300ms as missing.
curTaskResVarNames = res.Properties.VariableNames;
MRTvars = curTaskResVarNames(~cellfun(@isempty, ...
    regexp(curTaskResVarNames, '\<M?RT(?!_CongEffect|_SwitchCost|_FA)', 'once')));
for irtvar = 1:length(MRTvars)
    if res.(MRTvars{irtvar}) < 300 || res.(MRTvars{irtvar}) > 2500
        res{:, :} = nan;
        break
    end
end
%Add the suffix to the results table variable names if not empty.
if ~isempty(resvarsuff)
    res.Properties.VariableNames = strcat(curTaskResVarNames, ...
        '_', resvarsuff);
end
end

function RECORD = mapSCat(RECORD, taskSTIMMap)
%Modify variable SCat of RECORD and return it.

if ~iscell(RECORD.STIM)
    RECORD.STIM = num2cell(RECORD.STIM);
end
chkSTIM = isKey(taskSTIMMap, RECORD.STIM);
if all(chkSTIM)
    %Reshape is used to maintain the structure of data type in case the
    %RECORD is empty, then cell2mat will change the structure of data type.
    RECORD.SCat = reshape(cell2mat(values(taskSTIMMap, RECORD.STIM)), size(RECORD.STIM));
else %In this case, some of stimuli are not right, and delete all the instances.
    RECORD(:, :) = [];
end
end

function NGSTIM = findNG(RECORD, criterion)
%For some of the tasks, no-go stimuli is not predifined.

%Get all the stimuli.
allSTIM = unique(RECORD.STIM);
%For the newer version of DRT data, when response is required and the
%subject responded with an incorrect key, remove that trial because these
%trials might confuse the determination of nogo stimuli.
if isnum(allSTIM) && ismember('Resp', RECORD.Properties.VariableNames)
    %DRT of newer version detected.
    %Amend the ACC records.
    if ischar(RECORD.STIM)
        RECORD.STIM = str2double(num2cell(RECORD.STIM));
    end
    RECORD(RECORD.Resp ~= 0 & RECORD.STIM ~= RECORD.Resp, :) = [];
end
if ~isempty(allSTIM)
    firstTrial = RECORD(1, :);
    firstIsGo = ~xor(firstTrial.ACC == 1, firstTrial.RT < criterion);
    firstTrialInfo = allSTIM == firstTrial.STIM;
    %Here is an interesting way to find out no-go stimulus.
    NGSTIM = allSTIM(xor(firstTrialInfo, firstIsGo));
else
    NGSTIM = [];
end
end
