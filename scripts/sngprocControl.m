function [stats, labels] = sngprocControl(SCat, RT, ACC)
%SNGPROCCONTROL does some basic data transformation to conflict-based tasks.
%
% Reference:
%   Vandierendonck, A.
%   A comparison of methods to combine speed and accuracy measures of
%   performance: A rejoinder on the binning procedure
%   Behavior Research Methods, 2016, 1-21

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

% find group information
[grps, gid] = findgroups(SCat);
% remove RT's with no response
RT(ACC == -1) = NaN;
% remove RT outlier for each condition
for igrp = 1:length(gid)
    curGroupIdx = grps == igrp;
    RT(curGroupIdx) = rmoutlier(RT(curGroupIdx));
end
% calculate statistics for the whole task
[total_stats, total_labels] = SAT(RT, ACC);
lisas_weight = total_stats(ismember(total_labels, 'lisas_weight'));
% calculate statistics for each condition
[cond_stats, cond_labels] = splitapply(@(x, y) SAT(x, y, lisas_weight), ...
    RT, ACC, grps);
diff_stats = cond_stats(2, :) - cond_stats(1, :);
diff_labels = strcat(cond_labels(1, :), '_diff');
cond_labels_fix = strcat(cond_labels, '_', repmat(cellstr(gid), 1, size(cond_labels, 2)));
% calculate NIHScore
PC_Total = 1 - total_stats(ismember(total_labels, 'PE'));
MRT2 = cond_stats(2, ismember(cond_labels(1, :), 'MRT'));
MRT2 = max(min(MRT2, 2500), 500);
NIHScore = asin(sqrt(PC_Total)) / (pi / 2) + ...
    (log(2500) - log(MRT2)) / (log(2500) - log(500));
% merge results
stats = [total_stats, cond_stats(:)', diff_stats, NIHScore];
labels = [total_labels, cond_labels_fix(:)', diff_labels, {'NIHScore'}];
