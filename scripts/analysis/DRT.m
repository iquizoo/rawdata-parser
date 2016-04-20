function res = DRT(splitRes)
%DRT Does some basic data transformation to discrete reaction time tasks.
%
%   Basically, the supported tasks are as follows:
%     11-14. DRT
%   The output table contains 4 variables, called MRT, VRT, Rate_hit and
%   Rate_FA.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

outvars = {'MRT'};
if ~istable(splitRes{:}) || isempty(splitRes{:})
    res = {array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars)};
    return
end
RECORD = splitRes{:}.RECORD{:};
RECORD(isnan(RECORD.ACC), :) = [];
%Find out the no-go condition.
allcond = unique(RECORD.SCat);
firstTrial = RECORD(1, :);
firstCond = firstTrial.ACC == 1 && firstTrial.RT < 3000;
if firstCond
    ngcond = allcond(~ismember(allcond, firstTrial.SCat));
else
    ngcond = firstTrial.SCat;
end

%Calculate MRT for go trials.
%Cutoff RTs: eliminate RTs that are too fast (<100ms).
goRTs = RECORD.RT(~ismember(RECORD.SCat, ngcond));
MRT = nanmean(goRTs);
% VRT = nanvar(goRTs);
% 
% %hit rate and false alarm rate.
% Rate_hit = nanmean(RECORD.ACC(~ismember(RECORD.SCat, ngcond)));
% Rate_FA = 1 -  nanmean(RECORD.ACC(ismember(RECORD.SCat, ngcond)));

res = {table(MRT)};
