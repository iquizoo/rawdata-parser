function res = sngprocSpan(RECORD)
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
%For scoring.
MLACC = mean(RECORD.ACC(RECORD.SLen == ML));
MLNextACC = mean(RECORD.ACC(RECORD.SLen == ML - 1));
%Wrap these output into a table.
res = table(ML, MS, MLACC, MLNextACC);
