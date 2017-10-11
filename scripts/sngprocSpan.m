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
    % note 'findgroups' will sort data in ascending order
    [grps, allSLen] = findgroups(SLen);
    PC = splitapply(@mean, ACC, grps);
    MS = allSLen(1) - 0.5 + sum(PC);
end

stats = [NTrial, ML, MS];
labels = {'NTrial', 'ML', 'MS'};
