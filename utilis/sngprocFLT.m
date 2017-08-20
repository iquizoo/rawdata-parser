function res = sngprocFLT(RECORD)

% define useful constants.
grpVars = {'SCat', 'Change'};
changeType = {'Stay', 'Change'};
statsVars = [grpVars, {'Count', 'ACC'}];
% remove those trials with ACC of -1.
RECORD(RECORD.ACC == -1, :) = [];
% get the mean accuracy for each category and change type.
stats = grpstats(RECORD, grpVars, 'mean', ...
    'DataVars', 'ACC', 'VarNames', statsVars);
% deal with missing conditions.
subTbl = table(repelem(1:3, 2)', repmat(0:1, 1, 3)', zeros(6, 1), nan(6, 1), ...
    'VariableNames', statsVars);
existingRows = ismember(subTbl{:, grpVars}, stats{:, grpVars}, 'rows');
subTbl{existingRows, :} = stats{:, :};
stats = subTbl;
% calculate capacity.
stats = unstack(stats, 'ACC', 'Change', ...
    'ConstantVariables', 'Count', ...
    'NewDataVariableNames', changeType);
stats.Capacity = rowfun(@(x0, x1) x0 + x1 - 1, stats, ...
    'InputVariables', changeType, 'OutputFormat', 'uniform');
cap22 = 2 * stats.Capacity(stats.SCat == 1);
cap40 = 4 * stats.Capacity(stats.SCat == 2);
cap20 = 2 * stats.Capacity(stats.SCat == 3);
filtcap = cap20 - cap22;
res = table(cap22, cap40, cap20, filtcap);
