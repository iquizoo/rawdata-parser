function [stats, labels] = sngprocANS(S1, S2, ACC, RT)
%SNGPROCANS calculates Weber fraction for approximate number system.
%
%   According to Inglis, et. al. (2014), here we develop two major indices
%   as the measure of ANS: percent of correct (PC) and Weber fraction (w).
%   Only Weber fraction is not able to be estimated when PC is too small.
%
%   To-do: add another two indices of ANS, i.e., two versions of "numerical
%   ratio effect (NRE)".

% Zhang, Liang. E-mail: psychelzh@gmail.com

% count the trials of response (no response means -1 of ACC)
NTrial = length(RT);
NResp = sum(ACC ~= -1);
% accuracy is of interest, so trials with no response or too quick response
% will be treated as incorrect ones
ACC(ACC == -1 | RT < 100) = 0;
% get the percent of correct
PC = mean(ACC);
% check if percent of correct reaches above random based on normal-dist
PC_critical = norminv(0.95) * sqrt(NTrial) / (2 * NTrial) + 0.5;
% preallocate w and p
w = nan;
p = nan;
% fit the model only when the percent of correct is above random level
if PC > PC_critical
    % get the percent of choosing right number for each type of stimuli
    smaller = min([S1, S2], [], 2);
    larger = max([S1, S2], [], 2);
    [grps, gid1, gid2] = findgroups(smaller, larger);
    PC_grp = grpstats(ACC, grps);
    % model fitting
    mdlfun = @(w, r) 1 / 2 * (1 + erf((r - 1) ./ (sqrt(2) * w .* sqrt(r .^ 2 + 1))));
    mdl = fitnlm(gid2 ./ gid1, PC_grp, mdlfun, 1);
    w = mdl.Coefficients.Estimate;
    p = mdl.Coefficients.pValue;
end
% compose return values
stats = [NTrial, NResp, PC, w, p];
labels = {'NTrial', 'NResp', 'PC', 'w', 'p'};
