function [stats, labels] = sngprocFLT(RT, ACC, SCat, Cond)
%SNGPROCFLT does analysis for filtering task

% record total and responded trials numbers
NTrial = length(RT);
NResp = sum(ACC ~= -1);
% accuracy is of interest, will treat fast/no response as error
ACC(ACC == -1 | RT < 100) = 0;
% get the real categories of groups and group info
cats_SCat = categories(SCat);
cats_Cond = categories(Cond);
[grps, gidSCat, gidCond] = findgroups(SCat, Cond);
gidTbl = table(gidSCat, gidCond, 'VariableNames', {'SCat', 'Cond'});
% get the proportion of correct for each group
PC = splitapply(@mean, ACC, grps);
% compose PC table
PCTbl = table( ...
    categorical(repelem(cats_SCat, length(cats_Cond))), ...
    categorical(repmat(cats_Cond, length(cats_SCat), 1)), ...
    nan(length(cats_Cond) * length(cats_SCat), 1), ...
    'VariableNames', {'SCat', 'Cond', 'PC'});
[~, loc] = ismember(PCTbl(:, 1:2), gidTbl, 'rows');
PCTbl.PC(loc) = PC;
% calculate capacity.
PCTbl = unstack(PCTbl, 'PC', 'SCat');
PCTbl.Capacity = rowfun(@(x0, x1) x0 + x1 - 1, PCTbl, ...
    'InputVariables', cats_SCat, 'OutputFormat', 'uniform');
cap22 = 2 * PCTbl.Capacity(PCTbl.Cond == '22');
cap40 = 4 * PCTbl.Capacity(PCTbl.Cond == '40');
cap20 = 2 * PCTbl.Capacity(PCTbl.Cond == '20');
filtcap = cap20 - cap22;
stats = [NTrial, NResp, cap22, cap40, cap20, filtcap];
labels = {'NTrial', 'NResp', 'cap22', 'cap40', 'cap20', 'filtcap'};
