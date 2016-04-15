function res = SRT(splitRes)
%SRT Does some basic data transformation to simple reaction time tasks.
%
%   Basically, the supported tasks are as follows:
%     7-10. SRT
%   The output table contains 2 variables, called MRT, VRT.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

outvars = {...
    'MRT', 'VRT'};
if ~istable(splitRes{:})
    res = {array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars)};
    return
end
RECORD = splitRes{:}.RECORD{:};
%Cutoff RTs: for too fast and too slow RTs.
RECORD(RECORD.RT < 100 | RECORD.RT > 2500, :) = [];
MRT = nanmean(RECORD.RT); %Mean RT.
VRT = nanvar(RECORD.RT); %Variance of RT, note not standard deviation.
res = {table(MRT, VRT)};
