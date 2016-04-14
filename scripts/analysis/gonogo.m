function res = gonogo(Taskname, splitRes)
%GONOGO Does some basic data transformation to go/no-go tasks.
%
%   Basically, the supported tasks are as follows:
%     抵制诱惑, task id: 35
%     水果忍者, task id: 36
%   The output table contains 2 variables, called MRT, VRT.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

outvars = {...
    'ACC', 'RT'};
if ~istable(splitRes{:})
    res = array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars);
    return
end
RECORD = splitRes{:}.RECORD{:};
%Find out all the no-go conditions.
switch Taskname{:}
    case '抵制诱惑'
        nogoCode = [0, 1, 2, 3];        
    case '水果忍者'
        nogoCode = 0;
end
%Cutoff RTs: for too fast trials.
RECORD(RECORD.RT < 100, :) = [];
%Mean and variance of RT for go trials.
MRT = mean(RECORD.RT(RECORD.ACC == 1 & ~ismember(RECORD.SCat, nogoCode)));
VRT = var(RECORD.RT(RECORD.ACC == 1 & ~ismember(RECORD.SCat, nogoCode)));
%Hit rate
Rate_hit = mean(RECORD.ACC(~ismember(RECORD.SCat, nogoCode)));
Rate_FA = 1 - mean(RECORD.ACC(ismember(RECORD.SCat, nogoCode)));

res = table(MRT, VRT, Rate_hit, Rate_FA);
