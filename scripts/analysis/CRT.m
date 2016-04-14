function res = CRT(splitRes)
%DRT Does some basic data transformation to choice reaction time tasks.
%
%   Basically, the supported tasks are as follows:
%     Ñ¡ÔñËÙ¶È, task id: 14-16
%   The output table contains 6 variables, called MRT, VRT, ACC, v, a, Ter.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

outvars = {...
    'MRT', 'VRT', 'ACC', ...
    'v', 'a', 'Ter'};
if ~istable(splitRes{:})
    res = {array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars)};
    return
end
RECORD = splitRes{:}.RECORD{:};
%Cutoff RTs: eliminate RTs that are too fast (<100ms) or too slow (>2500ms)
RECORD(RECORD.RT < 100 | RECORD.RT > 2500, :) = [];
MRT = nanmean(RECORD.RT(RECORD.ACC == 1));
VRT = nanvar(RECORD.RT(RECORD.ACC == 1));
ACC = nanmean(RECORD.ACC);
[v, a, Ter] = EZdif(ACC, MRT / 1000, VRT / 1000000);

res = {table(MRT, VRT, ACC, v, a, Ter)};
