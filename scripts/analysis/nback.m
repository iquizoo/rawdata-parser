function res = nback(splitRes)
%NBACK Does some basic data transformation to n-back tasks.
%
%   Basically, the supported tasks are as follows:
%     42-43. Nback1-2
%   The output table contains 2 variables, called ACC, RT.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

%chkVar is used to check outliers.
chkVar = {};
%coupleVars are formatted out variables.
varPref = {'ACC', 'RT'};
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
%Remove trials that no response is needed.
RECORD(RECORD.CResp == -1, :) = [];
%Cutoff RTs: for too fast trials.
RECORD(RECORD.RT < 100 & RECORD.RT > 0, :) = [];
%Remove NaN trials.
RECORD(isnan(RECORD.ACC), :) = [];

ACC = mean(RECORD.ACC);
RT = mean(RECORD.RT);
res = {table(ACC, RT)};
