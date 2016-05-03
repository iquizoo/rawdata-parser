function res = sngstats(splitRes, tasksettings, taskSTIMMap)
%SNGSTATS forms a wrapper function to compute those single task statistics.
%

%By Zhang, Liang. 05/03/2016, E-mail:psychelzh@gmail.com

%Initialization jobs.
%Get all the output variable names.
%coupleVars are formatted out variables.
varscat = strsplit(tasksettings.VarsCat{:});
varscond = strsplit(tasksettings.VarsCond{:});
if all(cellfun(@isempty, varscond))
    delimiter = '';
else
    delimiter = '_';
end
cpvars = strcat(repmat(varscat, 1, length(varscond)), delimiter, ...
    repelem(varscond, 1, length(varscat)));
%further required variables.
sngvars = [strsplit(tasksettings.SingletonVars{:}), strsplit(tasksettings.SingletonVarsCP{:})];
spvars = strsplit(tasksettings.SpecialVars{:});
%Out variables names are composed by three part.
outvars = [cpvars, sngvars, spvars];
%Remove empty strings.
outvars(cellfun(@isempty, outvars)) = [];
%Note: sngstats means 'single task statistics'.
anafunstr = ['sngstats', tasksettings.AnalysisFun{:}];
task = tasksettings.TaskIDName{:};
%Initializing special result.
spres = table;
%Use this variable to detect abnormal data.
exception = false;
if ~istable(splitRes{:}) || isempty(splitRes{:})
    exception = true;
else
    recRes = splitRes{:};
    recVars = recRes.Properties.VariableNames;
    if ismember('RECORD', recVars) || ismember('TEST', recVars)
        %Get the appropriate analysis variable.
        anaVar = recVars{~cellfun(@isempty, regexp(recVars, 'RECORD|TEST', 'once'))};
        RECORD = splitRes{:}.(anaVar){:};
        %Minor modification to some of the variables in RECORD.
        switch task
            case {'Symbol', 'Orthograph', 'Tone', 'Pinyin', 'Lexic', 'Semantic', ...%langTasks
                    'GNGLure', 'GNGFruit', 'CPT1', ...%otherTasks in NSN. %NSN
                    }
                if exist('taskSTIMMap', 'var')
                    %Modify SCat.
                    if ~iscell(RECORD.STIM)
                        RECORD.STIM = num2cell(RECORD.STIM);
                    end
                    if all(isKey(taskSTIMMap, RECORD.STIM))
                        RECORD.SCat = cell2mat(values(taskSTIMMap, RECORD.STIM));
                    else %In this case, some of stimuli are not right, and delete all the instances.
                        RECORD(:, :) = [];
                    end
                end
                %Remove NaN trials.
                RECORD(isnan(RECORD.RT), :) = [];
                %Before removing RTs, record the time used if required.
                if ismember('TotalTime', outvars)
                    spres.TotalTime = sum(RECORD.RT);
                end
                if ismember('NTotalTrl', outvars)
                    spres.NTotalTrl = height(RECORD);
                end
                %Cutoff RTs: for too fast trials and too slow trials. Do not remove
                %trials without response, because some trials of GNG task is designed
                %to suppress a response for subjects.
                RECORD((RECORD.RT < 100 & RECORD.RT ~= 0) | RECORD.RT > 2500, :) = [];
                %record the number of correct trials if required.
                if ismember('NAccTrl', outvars)
                    spres.NAccTrl = sum(RECORD.ACC);
                end
            case {'Flanker', 'Stroop1', 'Stroop2', 'NumStroop', 'TaskSwitching'} %Conflict
                if exist('taskSTIMMap', 'var')
                    %Modify SCat.
                    if ~iscell(RECORD.SCat)
                        RECORD.SCat = num2cell(RECORD.SCat);
                    end
                    if all(isKey(taskSTIMMap, RECORD.SCat))
                        RECORD.SCat = cell2mat(values(taskSTIMMap, RECORD.SCat));
                    else %In this case, some of stimuli are not right, and delete all the instances.
                        RECORD(:, :) = [];
                    end
                end
                %Cutoff RTs: eliminate trials that are too fast (<100ms)
                RECORD(RECORD.RT < 100 & RECORD.RT ~= 0, :) = [];
                %Remove trials of no response.
                if ~ismember(RECORD.Properties.VariableNames, 'Resp')
                    RECORD.Resp = RECORD.ACC;
                end
                switch task
                    case {'Flanker', 'Stroop1', 'Stroop2'}
                        missResp = 0;
                    case 'NumStroop'
                        missResp = 2;
                    case 'TaskSwitching'
                        missResp = -1;
                end
                RECORD(RECORD.Resp == missResp, :) = [];
            case {'SRT', 'SRTWatch', 'SRTBread'} %SRT
                %The original record of ACC of each trial is not always right.
                if ismember('STIM', RECORD.Properties.VariableNames)
                    %transform: 'l'/'1' -> 1 , 'r'/'2' -> 2.
                    RECORD.STIM = (RECORD.STIM ==  'r' | RECORD.STIM ==  '2') + 1;
                    RECORD.ACC = RECORD.STIM == RECORD.Resp;
                end
                %Remove NaN trials.
                RECORD(isnan(RECORD.RT), :) = [];
                %Cutoff RTs: for too fast and too slow RTs. After discussion, only trials
                %that are too fast are removed. Note RT == 0 mostly means no response.
                RECORD(RECORD.RT < 100 & RECORD.RT ~= 0, :) = [];
                %Do not remove trials without response, because some trials of stopwatch
                %and fruit task is designed to suppress a response for subjects.
            case 'DRT' %DRT
                %Find out the no-go stimulus.
                if ~iscell(RECORD.STIM)
                    RECORD.STIM = num2cell(RECORD.STIM);
                end
                allSTIM = unique(RECORD.STIM(~isnan(RECORD.ACC)));
                firstTrial = RECORD(1, :);
                firstIsGo = firstTrial.ACC == 1 && firstTrial.RT < 3000;
                firstTrialInfo = strcmp(allSTIM, firstTrial.STIM);
                %Here is an interesting way to find out no-go stimulus.
                NGSTIM = allSTIM(xor(firstTrialInfo, firstIsGo));
                RECORD.SCat = ~ismember(RECORD.STIM, NGSTIM);
                %Remove NaN trials.
                RECORD(isnan(RECORD.RT), :) = [];
            case {'CRT', 'SpeedAdd', 'SpeedSubtract', 'DigitCmp', 'CountSense'} %CRT
                %Cutoff RTs: eliminate RTs that are too fast (<100ms).
                RECORD(RECORD.RT < 100 & RECORD.RT ~= 0, :) = [];
                %Removed trials without response.
                RECORD(RECORD.Resp == 0, :) = [];
                %Remove NaN trials.
                RECORD(isnan(RECORD.RT), :) = [];
            case {'SusAtten', 'ForSpan', 'BackSpan', 'SpatialSpan'} %Span
                %Remove trials with nan ACC.
                RECORD(isnan(RECORD.ACC), :) = [];
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
            case {'AssocMemory', 'SemanticMemory', ... %Memrep
                    'PicMemory', 'WordMemory', ... %Memsep
                    }
                %Cutoff RTs: for too fast trials.
                RECORD(RECORD.RT < 100 & RECORD.RT ~= 0, :) = [];
                %Remove NaN trials.
                RECORD(isnan(RECORD.ACC), :) = [];
                %Remove trials of no response, which denoted by -1 in Resp.
                RECORD(RECORD.Resp == -1, :) = [];
            
            case {'Nback1', 'Nback2'} %Nback
                %Remove trials that no response is needed.
                RECORD(RECORD.CResp == -1, :) = [];
                %Cutoff RTs: for too fast trials.
                RECORD(RECORD.RT < 100 & RECORD.RT ~= 0, :) = [];
                %Remove NaN trials.
                RECORD(isnan(RECORD.RT), :) = [];
        end
        %Compute now.
        if isempty(RECORD)
            exception = true;
        else
            anafun = str2func(anafunstr);
            switch nargin(anafunstr)
                case 1
                    comres = anafun(RECORD);
                case 4
                    comres = anafun(RECORD, varscat, delimiter, varscond);
            end
            res = [comres, spres];
        end
    else %For divided attention task.
    end
end
%Exception detected, return NaNs.
if exception
    res = table;
    for ivar = 1:length(outvars)
        res.(outvars{ivar}) = nan;
    end
end