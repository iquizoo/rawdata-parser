function [stats, labels] = sngprocNSN(RT, ACC, SCat)
%SNGPROCNSN forms a wrapper to do signal detection theory analysis.
%   [STATS, LABELS] = SNGPROCNSN(RT, ACC, SCAT) receives reaction times
%   (RT) and accuracy (ACC) with its conditions (SCat) as input parameters,
%   and output mainly 'dprime' and 'c'.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

% get the mean reaction time and accuracy for all trials
[total_stats, total_labels] = behavstats(RT, ACC, 'Method', 'cutoff', 'Boundary', [100, inf]);
% get the mean reaction time and accuracy for different conditions
[grps, gid] = findgroups(SCat);
[cond_stats, cond_labels] = splitapply(...
    @(x, y) behavstats(x, y, 'Method', 'none'), ...
    RT, ACC, grps);
% add condition names to condition labels.
cond_labels_fix = strcat(cond_labels, '_', repmat(cellstr(gid), 1, size(cond_labels, 2)));
% calculate sensitity index (dprime) and bias (c)
cond_PE = cond_stats(ismember(cond_labels, 'PE'));
% note the order: 'noise first, signal second'
[dprime, c] = sdt(1 - cond_PE(2), cond_PE(1));
stats = [total_stats, cond_stats(:)', dprime, c];
labels = [total_labels, cond_labels_fix(:)', {'dprime', 'c'}];
