function res = SRT(splitRes)
%SRT Does some basic data transformation to simple reaction time tasks.
%
%   Basically, the supported tasks are as follows:
%     7-10. SRT
%     18. SRTWatch
%     19. SRTBread
%   The output table contains 3 variables, called ACC, MRT, VRT.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com
%04/21/2016, change log: Add an ACC variable to record accuracy, esp. useful for bread
%and watch task.

%chkVar is used to check outliers.
chkVar = {};
%coupleVars are formatted out variables.
varPref = {'ACC', 'MRT'};
varSuff = {''};
delimiter = '';
coupleVars = strcat(repmat(varPref, 1, length(varSuff)), delimiter, repelem(varSuff, 1, length(varPref)));
%further required variables.
singletonVars = {'VRT'};
outvars = [chkVar, coupleVars, singletonVars];
if ~istable(splitRes{:}) || isempty(splitRes{:})
    res = {array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars)};
    return
end
RECORD = splitRes{:}.RECORD{:};
%Cutoff RTs: for too fast and too slow RTs. After discussion, only trials
%that are too fast are removed. Note RT == 0 mostly means no response.
RECORD(RECORD.RT < 100 & RECORD.RT > 0, :) = [];
%Do not remove trials without response, because some trials of stopwatch
%and fruit task is designed to suppress a response for subjects.
%Remove NaN trials.
RECORD(isnan(RECORD.ACC), :) = [];
%For the task 'SRT'. The original record of ACC of each trial is not always
%right.
if ismember('STIM', RECORD.Properties.VariableNames)
    %transform: 'l' -> 1 , 'r' -> 2.
    RECORD.STIM = (RECORD.STIM ==  'r') + 1;
    RECORD.ACC = RECORD.STIM == RECORD.Resp;
end
%Accuracy.
ACC = mean(RECORD.ACC);
%Mean RT.
MRT = mean(RECORD.RT(RECORD.ACC == 1));
%Standard deviation of RT. Square root of variance.
VRT = std(RECORD.RT(RECORD.ACC == 1));
res = {table(ACC, MRT, VRT)};
