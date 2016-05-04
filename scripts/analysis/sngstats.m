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
%Merge conditions. Useful when merging data.
mrgcond = strsplit(tasksettings.MergeCond{:});
if all(cellfun(@isempty, mrgcond))
    delimiterMC = '';
else
    delimiterMC = '_';
end
%Remove empty strings.
outvars(cellfun(@isempty, outvars)) = [];
%Note: sngstats means 'single task statistics'.
anafunstr = ['sngstats', tasksettings.AnalysisFun{:}];
anafun = str2func(anafunstr);
%Preallocation.
res = table; %Table type is used. Read the lines in the end of this function.
spres = table;
if ~isempty(splitRes{:})
    recRes = splitRes{:};
    recVars = recRes.Properties.VariableNames;
    nvar = length(recVars);
    if length(mrgcond) == 1 && length(mrgcond) < nvar
        mrgcond = repmat(mrgcond, 1, nvar);
    end
    for ivar = 1:nvar
        curRecVar = recVars{ivar};
        if ~isempty(strfind(curRecVar, 'RECORD')) || ~isempty(strfind(curRecVar, 'TEST'))
           RECORD = recRes.(curRecVar){:};
           %Minor modification to some of the variables in RECORD.
           task = tasksettings.TaskIDName{:};
           switch task
               case {'Symbol', 'Orthograph', 'Tone', 'Pinyin', 'Lexic', 'Semantic', ...%langTasks
                       'GNGLure', 'GNGFruit', 'CPT1', ...%otherTasks in NSN. %NSN
                       }
                   if exist('taskSTIMMap', 'var')
                       RECORD = mapSCat(RECORD, taskSTIMMap, 'STIM');
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
               case {'DRT', ...%DRT
                       'DivAtten1', 'DivAtten2', ...%DA
                       }
                   %Remove NaN trials.
                   RECORD(isnan(RECORD.RT), :) = [];
                   %Cutoff RTs: for too fast trials.
                   RECORD(RECORD.RT < 100 & RECORD.RT ~= 0, :) = [];
                   %Find out the no-go stimulus. Note RT of 3000 is regarded
                   %as no response.
                   criterion = 3000 * strcmp(task, 'DRT') + 1000 * ~strcmp(task, 'DRT');
                   NGSTIM = findNG(RECORD, criterion);
                   RECORD.SCat = ~ismember(RECORD.STIM, NGSTIM);
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
               case 'CPT2'
                   %Note only 'C' which is followed by 'B' is Go(target) trial
                   CCdts = strcmp(RECORD.STIM, 'C');
                   %'C' appears at the first trial will not be a target.
                   if ismember(find(CCdts), 1)
                       CCdts(1) = false;
                   end
                   isFollowB = strcmp(RECORD.STIM(circshift(CCdts, -1)) , 'B');
                   %'C' not followed by 'B' should be excluded.
                   CCdts(~isFollowB) = false;
                   %Add a field 'SCat', 1 -> go, 0 -> nogo.
                   RECORD.SCat = zeros(height(RECORD), 1);
                   RECORD.SCat(CCdts) = 1;
                   %Cutoff RTs: for too fast trials.
                   RECORD(RECORD.RT < 100 & RECORD.RT ~= 0, :) = [];
               case {'AssocMemory', 'SemanticMemory', ... %Memrep
                       'PicMemory', 'WordMemory', ... %Memsep
                       }
                   %Cutoff RTs: for too fast trials.
                   RECORD(RECORD.RT < 100 & RECORD.RT ~= 0, :) = [];
                   %Remove NaN trials.
                   RECORD(isnan(RECORD.ACC), :) = [];
                   %Remove trials of no response, which denoted by -1 in Resp.
                   RECORD(RECORD.Resp == -1, :) = [];
               case {'Flanker', 'Stroop1', 'Stroop2', 'NumStroop', 'TaskSwitching'} %Conflict
                   if exist('taskSTIMMap', 'var')
                       RECORD = mapSCat(RECORD, taskSTIMMap, 'SCat');
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
               case {'Nback1', 'Nback2'} %Nback
                   %Remove trials that no response is needed.
                   RECORD(RECORD.CResp == -1, :) = [];
                   %Cutoff RTs: for too fast trials.
                   RECORD(RECORD.RT < 100 & RECORD.RT ~= 0, :) = [];
                   %Remove NaN trials.
                   RECORD(isnan(RECORD.RT), :) = [];
           end
           %Compute now.
           if ~isempty(RECORD)
               switch nargin(anafunstr)
                   case 1
                       comres = anafun(RECORD);
                   case 4
                       comres = anafun(RECORD, varscat, delimiterVC, varscond);
               end
               curTaskRes = [comres, spres];
               curTaskRes(:, ~ismember(curTaskRes.Properties.VariableNames, outvars)) = [];
           else
               curTaskRes = array2table(nan(1, length(outvars)), 'VariableNames', outvars);
           end
           curTaskRes.Properties.VariableNames = strcat(curTaskRes.Properties.VariableNames, ...
               delimiterMC, mrgcond{ivar});
           res = [res, curTaskRes]; %#ok<*AGROW>
        end
    end
end
%Table is wrapped into a cell. The table type of MATLAB has something
%tricky when nesting table type in a table; it treats the rows of the
%nested table as integrated when using rowfun or concatenating.
res = {res};
end

function RECORD = mapSCat(RECORD, taskSTIMMap, var)
%Modify variable SCat of RECORD and return it.

if ~iscell(RECORD.(var))
    RECORD.(var) = num2cell(RECORD.(var));
end
if all(isKey(taskSTIMMap, RECORD.(var)))
    RECORD.SCat = cell2mat(values(taskSTIMMap, RECORD.(var)));
else %In this case, some of stimuli are not right, and delete all the instances.
    RECORD(:, :) = [];
end
end

function NGSTIM = findNG(RECORD, criterion)
%For some of the tasks, no-go stimuli is not predifined.

allSTIM = unique(RECORD.STIM);
if ~isempty(allSTIM)
    firstTrial = RECORD(1, :);
    firstIsGo = firstTrial.ACC == 1 && firstTrial.RT < criterion;
    firstTrialInfo = allSTIM == firstTrial.STIM;
    %Here is an interesting way to find out no-go stimulus.
    NGSTIM = allSTIM(xor(firstTrialInfo, firstIsGo));
else
    NGSTIM = [];
end
end
