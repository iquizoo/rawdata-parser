function res = sngstatsSpan(splitRes)
%SPAN Does some basic data transformation to working memory span tasks.
%
%   Basically, the supported tasks are as follows:
%     29. ForSpan,
%     30. BackSpan,
%     31. SpatialSpan.
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

%coupleVars are formatted out variables.
varPref = {'ML', 'MS'};
varSuff = {''};
delimiter = '';
coupleVars = strcat(repmat(varPref, 1, length(varSuff)), delimiter, repelem(varSuff, 1, length(varPref)));
%further required variables.
singletonVars = {};
%Out variables names are composed by three part.
outvars = [coupleVars, singletonVars];
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
    ML = nan;
    MS = nan;
else
    %Mean span metric.
    baseLen = RECORD.SLen(1);
    msBase = baseLen - 0.5; %Mean span baseline, set at 0.5 less than initial length.
    allSLen = unique(RECORD.SLen);
    %If the SLen is larger than baseLen, Mean Span is increased.
    increSLen = allSLen(allSLen >= baseLen);
    msIncre = 0;
    for iLen = 1:length(increSLen)
        %Incremented by hit rate of each SLen.
        msIncre = msIncre + mean(RECORD.ACC(RECORD.SLen == increSLen(iLen)));
    end
    %If the SLen is larger than baseLen, Mean Span is decreased.
    decreSLen = allSLen(allSLen < baseLen);
    msDecre = 0;
    for iLen = 1:length(decreSLen)
        %Decreased by miss rate of each SLen.
        msDecre = msDecre + 1 - mean(RECORD.ACC(RECORD.SLen == decreSLen(iLen)));
    end
    MS = msBase + msIncre - msDecre;
end
res = {table(...
    ML, MS)};
res{:}.Properties.VariableDescriptions = {...
    'the longest list correctly reported', ...
    'the list length where 50% of lists would be correctly reported'};
