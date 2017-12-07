function [stats, labels] = sngprocSNSN(RT, ACC, SCat)
%SNGPROCSNS calculates number of hit and false alarm (simple NSN).
%   NOTE: d' will not be calculated.

% record trial information
NTrial = length(RT);
NResp = sum(ACC ~= -1);
% set the RT for no response trials as missing
RT(ACC == -1) = NaN;
% remove RT outliers
RT = rmoutlier(RT);
% set ACC of outlier and -1 trials as NaN (not included)
ACC(isnan(RT) | ACC == -1) = NaN;
NInclude = sum(~isnan(ACC));
% fix incomplete SCat
cats = categories(SCat);
switch length(unique(SCat))
    case 0
        % no SCat data found, compose one
        ACC = nan(2, 1);
        SCat = categorical(cats);
    case 1
        % only one SCat data found, add th missing one
        ACC = [ACC; nan];
        SCat = [SCat; setdiff(cats, unique(SCat))];
end
% get the number of hit and false alarm
[grps, gid] = findgroups(SCat);
[cond_include, cond_correct] = grpstats(ACC, grps, {'numel', @(x) sum(x == 1)});
stats = [NTrial, NResp, NInclude, cond_include', cond_correct'];
labels = [{'NTrial', 'NResp', 'NInclude'}, ...
    strcat('Count_', cellstr(gid')), strcat('Correct_', cellstr(gid'))];
