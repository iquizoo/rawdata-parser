function [stats, labels] = sngprocANS(S1, S2, ACC, RT)
%SNGPROCANS calculates Weber fraction for approximate number system.

% Zhang, Liang. E-mail: psychelzh@gmail.com

% count the trials of response (no response means -1 of ACC)
NTrial = length(RT);
NResp = sum(ACC ~= -1);
% accuracy is of interest, so trials with no response or too quick response
% will be treated as incorrect ones
ACC(ACC == -1 | RT < 100) = 0;
% get the stimuli matrix
S = [S1, S2];
larger = max(S, [], 2);
smaller = min(S, [], 2);
% get the accuracy measure for each type of stimuli
[grps, gidl, gids] = findgroups(larger, smaller);
Pc = grpstats(ACC, grps);
% model fitting
warning('off', 'stats:nlinfit:ModelConstantWRTParam')
warning('off', 'MATLAB:rankDeficientMatrix')
mdlfun = @(b, x) 1 - 1 / 2 .* ...
    erfc((x(:, 1) - x(:, 2)) ./ (b .* sqrt(2 .* (x(:, 1) .^ 2 + x(:, 2) .^ 2))));
mdl = fitnlm([gidl, gids], Pc, mdlfun, 1);
w = mdl.Coefficients.Estimate;
% compose return values
stats = [NTrial, NResp, w];
labels = {'NTrial', 'NResp', 'w'};
