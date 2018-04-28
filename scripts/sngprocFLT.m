function [stats, labels] = sngprocFLT(RT, ACC, SCat, Cond)
%SNGPROCFLT does analysis for filtering task

% record total and responded trials numbers
NTrial = length(RT);
NResp = sum(ACC ~= -1);
% accuracy is of interest, will treat fast/no response as error
ACC(ACC == -1 | RT < 100) = 0;
% get the overall accuracy
PC = mean(ACC);
% get the real categories of groups and group info
cats_SCat = categories(SCat);
cats_Cond = categories(Cond);
[grps, gidSCat, gidCond] = findgroups(SCat, Cond);
gidTbl = table(gidSCat, gidCond, 'VariableNames', {'SCat', 'Cond'});
% get the proportion of correct for each group
PC_grp = splitapply(@mean, ACC, grps);
% compose PC table
PCTbl_grp = table( ...
    categorical(repelem(cats_SCat, length(cats_Cond))), ...
    categorical(repmat(cats_Cond, length(cats_SCat), 1)), ...
    nan(length(cats_Cond) * length(cats_SCat), 1), ...
    'VariableNames', {'SCat', 'Cond', 'PC'} ...
    );
[~, loc] = ismember(PCTbl_grp(:, 1:2), gidTbl, 'rows');
PCTbl_grp.PC(loc) = PC_grp;
% calculate capacity.
PCTbl_grp = unstack(PCTbl_grp, 'PC', 'SCat');
PCTbl_grp.Capacity = rowfun(@(x0, x1) x0 + x1 - 1, PCTbl_grp, ...
    'InputVariables', cats_SCat, 'OutputFormat', 'uniform');
cap22 = 2 * PCTbl_grp.Capacity(PCTbl_grp.Cond == '22');
cap40 = 4 * PCTbl_grp.Capacity(PCTbl_grp.Cond == '40');
cap20 = 2 * PCTbl_grp.Capacity(PCTbl_grp.Cond == '20');
% filtering efficiency
FE = (cap40 - cap22) / (cap40 - cap20);
% compose return values
stats = [NTrial, NResp, PC, cap22, cap40, cap20, FE];
labels = {'NTrial', 'NResp', 'PC', 'cap22', 'cap40', 'cap20', 'FE'};
