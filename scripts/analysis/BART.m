function res = BART(splitRes)
%BART Does some basic data transformation to BART task.
%
%   Basically, the supported tasks are as follows:
%     47. BART
%   The output table contains 1 variables, called MNHit.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

%chkVar is used to check outliers.
chkVar = {};
%coupleVars are formatted out variables.
varPref = {'MNHit'};
varSuff = {''};
delimiter = '';
coupleVars = strcat(repmat(varPref, 1, length(varSuff)), delimiter, repelem(varSuff, 1, length(varPref)));
%further required variables.
singletonVars = {};
%Out variables names are composed by three part.
outvars = [chkVar, coupleVars, singletonVars];
if ~istable(splitRes{:}) || isempty(splitRes{:})
    res = {array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars)};
    return
end
RECORD = splitRes{:}.RECORD{:};
%Caculate the average hit number.
MNHit = nanmean(RECORD.NHit(RECORD.Feedback == 0));
res = {table(MNHit)};
