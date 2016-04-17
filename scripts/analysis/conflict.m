function res = conflict(TaskIDName, splitRes)
%CONFLICT Does some basic data transformation to conflict-based tasks.
%
%   Basically, the supported tasks are as follows:
%     38. Flanker,
%     39-40. Stroop1-2,
%     44. TaskSwicthing.
%   The output table contains 8 variables.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

%Get all the conditions' coding and outvars suffix.
switch TaskIDName{:}
    case 'Flanker'
        codeA = [1, 3]; %Congruent.
        codeB = [2, 4]; %Incongruent.
        varSuff = {'_Overall', '_Cong', '_Incong', '_CongEffect'};
    case {...
            'Stroop1',...
            'Stroop2',...
            }
        codeA = 1; %Congruent.
        codeB = 0; %Incongruent.
        varSuff = {'_Overall', '_Cong', '_Incong', '_CongEffect'};
    case 'TaskSwitching'
        codeA = 1; %Repeat.
        codeB = 2; %Switch.
        varSuff = {'_Overall', '_Repeat', '_Switch', '_SwitchCost'};
end

repVarSuff = repmat(varSuff, 2, 1);
outSuff = repVarSuff(:)';
outvars = strcat(repmat({'RT', 'ACC'}, 1, length(varSuff)), outSuff);
if ~istable(splitRes{:}) || isempty(splitRes{:})
    res = {array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars)};
    return
end
RECORD = splitRes{:}.RECORD{:};
%Cutoff RTs: eliminate trials that are too fast (<100ms)
RECORD(RECORD.RT < 100, :) = [];
%No response trials used -1 as its ACC record, change it to 0.
RECORD.ACC(RECORD.ACC == -1) = 0;
%Overall RT and ACC.
res.RT = nanmean(RECORD.RT(RECORD.ACC == 1));
res.ACC = nanmean(RECORD.ACC);
%Condition-wise analysis.
%Condition A.
res.(['RT', varSuff{2}]) = nanmean(RECORD.RT(ismember(RECORD.SCat, codeA) & RECORD.ACC == 1));
res.(['ACC', varSuff{2}]) = nanmean(RECORD.ACC(ismember(RECORD.SCat, codeA)));
%Condition B.
res.(['RT', varSuff{3}]) = nanmean(RECORD.RT(ismember(RECORD.SCat, codeB) & RECORD.ACC == 1));
res.(['ACC', varSuff{3}]) = nanmean(RECORD.ACC(ismember(RECORD.SCat, codeB)));
%The last two output variables.
res.(['RT', varSuff{4}]) = res.(['RT', varSuff{3}]) - res.(['RT', varSuff{2}]);
res.(['ACC', varSuff{4}]) = res.(['ACC', varSuff{2}]) - res.(['ACC', varSuff{3}]);
res = {struct2table(res)};
