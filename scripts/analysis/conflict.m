function res = conflict(TaskIDName, splitRes)
%CONFLICT Does some basic data transformation to conflict-based tasks.
%
%   Basically, the supported tasks are as follows:
%     38. Flanker,
%     39-40. Stroop1-2,
%     41. NumStroop
%     44. TaskSwicthing.
%   The output table contains 8 variables.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

%chkVar is used to check outliers.
chkVar = {};
%coupleVars are formatted out variables.
varPref = {'RT', 'ACC'};
switch TaskIDName{:} % Addition: get the miss code of each task.
    case 'Flanker'
        codeA = [1, 3]; %Congruent.
        codeB = [2, 4]; %Incongruent.
        varSuff = {'Overall', 'Cong', 'Incong', 'CongEffect'};
        missResp = 0;
    case {...
            'Stroop1',...
            'Stroop2',...
            'NumStroop',...
            }
        codeA = 1; %Congruent.
        codeB = 0; %Incongruent.
        varSuff = {'Overall', 'Cong', 'Incong', 'CongEffect'};
        if strcmp(TaskIDName{:}, 'NumStroop')
            missResp = 2;
        else
            missResp = 0;
        end
    case 'TaskSwitching'
        codeA = 1; %Repeat.
        codeB = 2; %Switch.
        varSuff = {'Overall', 'Repeat', 'Switch', 'SwitchCost'};
        missResp = -1;
end
delimiter = '_';
coupleVars = strcat(repmat(varPref, 1, length(varSuff)), delimiter, repelem(varSuff, 1, length(varPref)));
%further required variables.
singletonVars = {};
%Out variables names are composed by three part.
outvars = [chkVar, coupleVars, singletonVars];
if ~istable(splitRes{:}) || isempty(splitRes{:})
    res = {array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars)};
    return
end
RECORD = splitRes{:}.RECORD{:};
%Cutoff RTs: eliminate trials that are too fast (<100ms)
RECORD(RECORD.RT < 100 & RECORD.RT > 0, :) = [];
%Remove trials of no response.
if ~ismember(RECORD.Properties.VariableNames, 'Resp')
    RECORD.Resp = RECORD.ACC;
end
RECORD(RECORD.Resp == missResp, :) = [];
%Overall RT and ACC.
res.RT_Overall = nanmean(RECORD.RT(RECORD.ACC == 1));
res.ACC_Overall = nanmean(RECORD.ACC);
%Condition-wise analysis.
%Condition A.
res.([varPref{1}, delimiter, varSuff{2}]) = nanmean(RECORD.RT(ismember(RECORD.SCat, codeA) & RECORD.ACC == 1));
res.([varPref{2}, delimiter, varSuff{2}]) = nanmean(RECORD.ACC(ismember(RECORD.SCat, codeA)));
%Condition B.
res.([varPref{1}, delimiter, varSuff{3}]) = nanmean(RECORD.RT(ismember(RECORD.SCat, codeB) & RECORD.ACC == 1));
res.([varPref{2}, delimiter, varSuff{3}]) = nanmean(RECORD.ACC(ismember(RECORD.SCat, codeB)));
%The last two output variables.
res.([varPref{1}, delimiter, varSuff{4}]) = ...
    res.([varPref{1}, delimiter, varSuff{3}]) - res.([varPref{1}, delimiter, varSuff{2}]);
res.([varPref{2}, delimiter, varSuff{4}]) = ...
    res.([varPref{2}, delimiter, varSuff{2}]) - res.([varPref{2}, delimiter, varSuff{3}]);
res = {struct2table(res)};
