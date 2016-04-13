function res = BART(splitRes)
%BART Does some basic data transformation to BART task.
%
%   Basically, the supported tasks are as follows:
%     ´µÆøÇò, task id: 46
%     
%   The output table contains 2 variables, called MRT, VRT.

RECORD = splitRes{:}.RECORD{:};
%Caculate the average hit number.
MNHit = mean(RECORD.NHit(RECORD.Feedback == 0));
res = table(MNHit);
