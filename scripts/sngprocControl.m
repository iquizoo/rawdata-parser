function [stats, labels] = sngprocControl(SCat, RT, ACC)
%SNGPROCCONTROL does some basic data transformation to conflict-based tasks.
%
% Reference:
%   Vandierendonck, A.
%   A comparison of methods to combine speed and accuracy measures of
%   performance: A rejoinder on the binning procedure
%   Behavior Research Methods, 2016, 1-21

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

RT(ACC == -1) = NaN;
RT = rmoutlier(RT);
% set ACC of outlier and -1 trials as NaN (not included)
ACC(isnan(RT) | ACC == -1) = NaN;

[total_stats, total_labels] = SAT(RT, ACC);
lisas_weight = total_stats(ismember(total_labels, 'lisas_weight'));

[grps, gid] = findgroups(SCat);
[cond_stats, cond_labels] = splitapply(@(x, y) SAT(x, y, lisas_weight), ...
    RT, ACC, grps);
diff_stats = cond_stats(2, :) - cond_stats(1, :);
diff_labels = strcat('diff_', cond_labels(1, :));
cond_labels = strcat(repmat(cellstr(gid), 1, size(cond_labels, 2)), '_', cond_labels);

PC = 1 - total_stats(ismember(total_labels, 'PE'));
RT = cond_stats(ismember(cond_labels, 'Incon_MRT'));
RT = max(min(RT, 2500), 500);
NIHScore = asin(sqrt(PC)) / (pi / 2) + ...
    (log(2500) - log(RT)) / (log(2500) - log(500));

stats = [total_stats, reshape(cond_stats, 1, numel(cond_stats)), diff_stats, NIHScore];
labels = [total_labels, reshape(cond_labels, 1, numel(cond_labels)), diff_labels, {'NIHScore'}];
