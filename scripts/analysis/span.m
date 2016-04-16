function res = span(splitRes)
%SPAN Does some basic data transformation to working memory span tasks.
%
%   Basically, the supported tasks are as follows:
%     29. ForSpan,
%     30. BackSpan,
%     31. SpatialSpan.
%   The output table contains 4 variables: TE_ML(Two Error-Maximal Length),
%   TE_TT(Two Error-Total Trial), ML(Maximal Length), MS(Mean Span).
%
%   Reference: 
%   Woods, D. L., Kishiyama, M. M., Yund, E. W., Herron, T. J., Edwards,
%   B., Poliva, O., Reed, B. (2011). Improving digit span assessment of
%   short-term verbal memory. Journal of Clinical & Experimental
%   Neuropsychology, 33(1), 101¨C111.

% By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

outvars = {...
    'TE_ML', 'TE_TT', 'ML', 'MS'};
if ~istable(splitRes{:}) || isempty(splitRes{:})
    res = {array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars)};
    return
end
RECORD = splitRes{:}.RECORD{:};
%Remove trials with nan as its ACC.
RECORD(isnan(RECORD.ACC), :) = [];
%Some of the recording does not include SLen (Stimuli Length) as one of
%their variable, get it here.
if ~ismember('SLen', RECORD.Properties.VariableNames)
    RECORD.SLen = cellfun(@length, RECORD.SSeries);
end
%Some of the recording does not include Next as one variable, get it here.
if ~ismember('Next', RECORD.Properties.VariableNames)
    RECORD.Next = [diff(RECORD.SLen); 0];
end
%ML (maximal length) could be a judgement if there are any trials that are
%correct.
ML = max(RECORD.SLen(RECORD.ACC == 1));
if isempty(ML) % No correct trials found.
    TE_ML = nan;
    TE_TT = nan;
    ML = nan;
    MS = nan;
else
    %For the TE_* variables.
    reduceTrialInd = find(RECORD.Next == -1);
    TE_ML = sum(RECORD.ACC(1:reduceTrialInd(1)));
    TE_TT = reduceTrialInd(1) - 1;
    %Mean span metric.
    msBase = RECORD.SLen(1) - 0.5; %Mean span baseline, set at 0.5 less than initial length.
    allSLen = unique(RECORD.SLen);
    msIncre = 0;
    for iLen = 1:length(allSLen)
        %Incremented by hit rate of each SLen.
        msIncre = msIncre + mean(RECORD.ACC(RECORD.SLen == allSLen(iLen))); 
    end
    MS = msBase + msIncre;
end
res = {table(TE_ML, TE_TT, ML, MS)};
res{:}.Properties.VariableDescriptions = {'the total number of trials correct prior to two successive misses', ...
    'the total number of trials (both correct and incorrect) presented prior to two successive errors', ...
    'the longest list correctly reported', ...
    'the list length where 50% of lists would be correctly reported'};
