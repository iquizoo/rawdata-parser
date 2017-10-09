function [stats, labels] = sngprocNSN(SCat, RT, ACC)
%SNGPROCNSN Does some basic data transformation to all noise/signal-noise tasks.
%
%   Basically, the supported tasks are as follows:
%     Symbol Orthograph Tone Pinyin Lexic Semantic DRT CPT1 CPT2 GNGLure
%     GNGFruit DivAtten1 DivAtten2

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
