function res = BART(splitRes)
%BART Does some basic data transformation to BART task.
%
%   Basically, the supported tasks are as follows:
%     ´µÆøÇò, task id: 46
%     
%   The output table contains 1 variables, called MNHit.

outvars = {...
    'MNHit'};
if ~istable(splitRes{:})
    res = {array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars)};
    return
end
RECORD = splitRes{:}.RECORD{:};
%Caculate the average hit number.
MNHit = mean(RECORD.NHit(RECORD.Feedback == 0));
res = {table(MNHit)};
