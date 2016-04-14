function res = DRT(splitRes)
%DRT Does some basic data transformation to discrete reaction time tasks.
%
%   Basically, the supported tasks are as follows:
%     ·Ö±æËÙ¶È, task id: 10-13
%   The output table contains 4 variables, called MRT, VRT, Rate_hit and
%   Rate_FA.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

outvars = {...
    'MRT', 'VRT', ...
    'Rate_hit', 'Rate_FA'};
if ~istable(splitRes{:})
    res = array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars);
    return
end
RECORD = splitRes{:}.RECORD{:};
%Find out the no-go condition.
condOf3000 = cell2mat(RECORD.SCat(RECORD.RT == 3000));
unistr = unique(condOf3000);
nstr = nan(size(unistr));
for istr = 1:length(unistr)
    nstr(istr) = sum(condOf3000 == unistr(istr));
end
[~, idx] = max(nstr);
ngcond = unistr(idx);

%Calculate MRT for go trials.
%Cutoff RTs: eliminate RTs that are too fast (<100ms) or too slow (>2500ms)
RECORD(RECORD.RT < 100 | RECORD.RT > 2500, :) = [];
goRTs = RECORD.RT(~ismember(RECORD.SCat, ngcond));
MRT = nanmean(goRTs);
VRT = nanvar(goRTs);

%hit rate and false alarm rate.
Rate_hit = mean(RECORD.ACC(~ismember(RECORD.SCat, ngcond)));
Rate_FA = 1 -  mean(RECORD.ACC(ismember(RECORD.SCat, ngcond)));

res = table(MRT, VRT, Rate_hit, Rate_FA);
