function [stats, labels] = sngprocNSN(RT, ACC, SCat)
%SNGPROCNSN forms a wrapper to do signal detection theory analysis.
%   [STATS, LABELS] = SNGPROCNSN(RT, ACC, SCAT) receives reaction times
%   (RT) and accuracy (ACC) with its conditions (SCat) as input parameters,
%   and output mainly 'dprime' and 'c'.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

RT(ACC == -1) = NaN;
RT = rmoutlier(RT);

[total_stats, total_labels] = behavstats(RT, ACC);

[grps, gid] = findgroups(SCat);
[cond_stats, cond_labels] = splitapply(@behavstats, ...
    RT, ACC, grps);
cond_labels = strcat(cond_labels, '_', repmat(cellstr(gid), 1, size(cond_labels, 2)));
cond_res = array2table(cond_stats(:)', 'VariableNames', cond_labels(:)');

[dprime, c] = sdt(1 - cond_res.PE_Signal, cond_res.PE_Noise);
stats = [total_stats, cond_stats(:)', dprime, c];
labels = [total_labels, cond_labels(:)', {'dprime', 'c'}];
