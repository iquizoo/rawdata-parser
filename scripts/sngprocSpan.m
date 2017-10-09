function [stats, labels] = sngprocSpan(SLen, ACC)
%SNGPROCSPAN Does some basic data transformation to working memory span tasks.
%
%   Basically, the supported tasks are as follows:
%     MOT ForSpan, BackSpan, SpatialSpan.
%   The output table contains 2 variables: TE_ML(!D)(Two Error-Maximal
%   Length), TE_TT(!D)(Two Error-Total Trial), ML(Maximal Length), MS(Mean
%   Span).
%
%   Reference:
%   Woods, D. L., Kishiyama, M. M., Yund, E. W., Herron, T. J., Edwards,
%   B., Poliva, O., Reed, B. (2011). Improving digit span assessment of
%   short-term verbal memory. Journal of Clinical & Experimental
%   Neuropsychology, 33(1), 101¨C111.

% By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

% trials number
NTrial = length(SLen);
% maximal lenth
ML = max(SLen(ACC == 1));
if isempty(ML)
    % no correct trials exist
    ML = nan;
    MS = nan;
else
    % initial length
    baseLen = SLen(1);
    % mean span baseline, set at 0.5 less than initial length
    msBase = baseLen - 0.5;
    [grps, allSLen] = findgroups(SLen);
    PC = splitapply(@mean, ACC, grps);
    allSLenWeight = (-1) .^ (allSLen < baseLen);
    MS = msBase + dot(PC, allSLenWeight);
end

stats = [NTrial, ML, MS];
labels = {'NTrial', 'ML', 'MS'};
