function [stats, labels] = sngprocDigitCmp(S1, S2, ACC, RT)
%SNGPROCDIGITCMP analyzes digit comparison task to get distance effect

% Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com
% change log:
%   01/08/2018, now use the linearly fitted slope as the distance effect

% count trial numbers
NTrial = length(RT);
NResp = sum(ACC ~= -1);
% set the RT for no response trials as missing
RT(ACC == -1) = NaN;
% two-step protocol to remove RT outliers
RT = rmoutlier(RT);
% set ACC of nan RT trials as 0
ACC(isnan(RT)) = 0;
% proportion of error
PE = 1 - mean(ACC);
% get the distance
dist = abs(S1 - S2);
% get the exclude indices to exclude incorrect trials
exclude = ~logical(ACC);
% make sure there is at least one trial for each distance (1-6)
if ~all(ismember(1:6, unique(dist(~exclude))))
    DistEffect = nan;
else
    % get the slope as distance effect
    mdl = fitlm(dist, RT, 'Exclude', exclude);
    DistEffect = mdl.Coefficients.Estimate(2);
end
% compose results
stats = [NTrial, NResp, PE, DistEffect];
labels = {'NTrial', 'NResp', 'PE', 'DistEffect'};
