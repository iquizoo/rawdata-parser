function [stats, labels] = behavstats(RT, ACC)
% summary statistics for behavior according to RT and ACC

% record trial information
NTrial = length(RT);
NResp = sum(ACC ~= -1);
% set ACC of outlier and -1 trials as NaN (not included)
ACC(isnan(RT) | ACC == -1) = NaN;
NInclude = sum(~isnan(ACC));
PE = 1 - nanmean(ACC);
SPE = nanstd(ACC);
MRT = mean(RT(ACC == 1));
SRT = std(RT(ACC == 1));

stats = [NTrial, NResp, NInclude, PE, SPE, MRT, SRT];
labels = {'NTrial', 'NResp', 'NInclude', 'PE', 'SPE', 'MRT', 'SRT'};
