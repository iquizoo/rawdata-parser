function [stats, labels] = sngprocDivAtten(Condition, RT, ACC, STIM)
%SNGPRODIVATTEN analyzes data of divided attention task

% for now, the CResp is not recorded, will use arbitrary value as target.
% treat one of STIM as target (the first of unique results)
SCat = categorical(STIM, unique(STIM), {'Target', 'Non-Target'});
% calculate the same stats as CPT1 for each condition
[grps, gid] = findgroups(Condition);
[cond_stats, cond_labels] = splitapply(@sngprocCPT1, RT, ACC, SCat, grps);
keyIdxName = 'dprime';
keyIdx = sum(cond_stats(ismember(cond_labels, keyIdxName)));
cond_labels_fix = strcat(cond_labels, '_', repmat(cellstr(gid), 1, size(cond_labels, 2)));
stats = [cond_stats(:)', keyIdx];
labels = [cond_labels_fix(:)', 'dprimeUnion'];
