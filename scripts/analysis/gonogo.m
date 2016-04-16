function res = gonogo(TaskIDName, splitRes)
%GONOGO Does some basic data transformation to go/no-go tasks.
%
%   Basically, the supported tasks are as follows:
%     36. GNG_Lure
%     37. GNG_Fruit
%   The output table contains 2 variables, called MRT, VRT.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

outvars = {...
    'ACC', 'RT'};
if ~istable(splitRes{:}) || isempty(splitRes{:})
    res = {array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars)};
    return
end
RECORD = splitRes{:}.RECORD{:};
%Find out all the no-go conditions.
switch TaskIDName{:}
    case 'GNG_Lure'
        nogoCode = [0, 1, 2, 3, 10, 11];        
    case 'GNG_Fruit'
        nogoCode = 0;
end
%Cutoff RTs: for too fast trials.
RECORD(RECORD.RT < 100, :) = [];
%Mean and variance of RT for go trials.
MRT = nanmean(RECORD.RT(RECORD.ACC == 1 & ~ismember(RECORD.SCat, nogoCode)));
VRT = nanvar(RECORD.RT(RECORD.ACC == 1 & ~ismember(RECORD.SCat, nogoCode)));
%Hit rate
Rate_hit = nanmean(RECORD.ACC(~ismember(RECORD.SCat, nogoCode)));
Rate_FA = 1 - nanmean(RECORD.ACC(ismember(RECORD.SCat, nogoCode)));

res = {table(MRT, VRT, Rate_hit, Rate_FA)};
