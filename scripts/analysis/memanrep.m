function res = memanrep(splitRes)
%SMMEMAN Does some basic data transformation to semantic memory task.
%
%   Basically, the supported tasks are as follows:
%     35. SemanticMemory
%   The output table contains 9 variables.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

%chkVar is used to check outliers.
chkVar = {};
%coupleVars are formatted out variables.
varPref = {'Overall', 'R1', 'R2'};
varSuff = {'ACC', 'RT'};
delimiter = '_';
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
% STUDY = splitRes{:}.STUDY{:};
if ~ismember(splitRes{:}.Properties.VariableNames, 'RECORD')
    %This means it is the semantic memory task.
    RECORD = splitRes{:}.TEST{:};
else
    %This means it is the associative memory task.
    RECORD = splitRes{:}.RECORD{:};
end
%Cutoff RTs: for too fast trials.
RECORD(RECORD.RT < 100 & RECORD.RT > 0, :) = [];
%Remove NaN trials.
RECORD(isnan(RECORD.ACC), :) = [];
%Remove trials of no response, which denoted by -1 in Resp.
RECORD(RECORD.Resp == -1, :) = [];
%ACC and RT for overall performance.
res.([varPref{1}, delimiter, varSuff{1}]) = mean(RECORD.ACC);
res.([varPref{1}, delimiter, varSuff{2}]) = mean(RECORD.RT(RECORD.ACC == 1));
%Run-wise ACC and RT.
runs = 1:2;
for run = runs
    res.([varPref{run + 1}, delimiter, varSuff{1}]) = ...
        mean(RECORD.ACC(RECORD.REP == run));
    res.([varPref{run + 1}, delimiter, varSuff{2}]) = ...
        mean(RECORD.RT(RECORD.ACC == 1 & RECORD.REP == run));
end
res = {struct2table(res)};
