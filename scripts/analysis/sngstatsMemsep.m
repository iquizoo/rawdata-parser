function res = sngstatsMemsep(taskIDName, splitRes)
%MEMAN Does some basic data transformation to memory task.
%
%   Basically, the supported tasks are as follows:
%     33. PicMemory
%     34. WordMemory
%   The output table contains 9 variables.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

%coupleVars are formatted out variables.
varPref = {'Overall', 'R1', 'R2'};
switch taskIDName{:}
    case 'PicMemory'
        varSuff = {'hit', 'simFA', 'newFA'};
    case 'WordMemory'
        varSuff = {'hit', 'lureFA', 'foilFA'};
end
delimiter = '_';
coupleVars = strcat(repmat(varPref, 1, length(varSuff)), delimiter, repelem(varSuff, 1, length(varPref)));
%further required variables.
singletonVars = {};
%Out variables names are composed by three part.
outvars = [coupleVars, singletonVars];
if ~istable(splitRes{:}) || isempty(splitRes{:})
    res = {array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars)};
    return
end
RECORD = splitRes{:}.RECORD{:};
%Cutoff RTs: for too fast trials.
RECORD(RECORD.RT < 100 & RECORD.RT > 0, :) = [];
%Remove NaN trials.
RECORD(isnan(RECORD.ACC), :) = [];
%Remove trials of no response, which denoted by -1 in Resp.
RECORD(RECORD.Resp == -1, :) = [];
%Code for each category of stimuli.
oldcode = 1;
simcode = 2;
newcode = 0;
%Overall hit and false alarm rate.
res.([varPref{1}, delimiter, varSuff{1}]) = mean(RECORD.ACC(RECORD.SCat == oldcode));
res.([varPref{1}, delimiter, varSuff{2}]) = 1 - mean(RECORD.ACC(RECORD.SCat == simcode));
res.([varPref{1}, delimiter, varSuff{3}]) = 1 - mean(RECORD.ACC(RECORD.SCat == newcode));
%Run-wise hit and false alarm rate.
runs = 1:2;
for run = runs
    res.([varPref{run + 1}, delimiter, varSuff{1}]) = ...
        mean(RECORD.ACC(RECORD.SCat == oldcode & RECORD.REP == run));
    res.([varPref{run + 1}, delimiter, varSuff{2}]) = ...
        1 - mean(RECORD.ACC(RECORD.SCat == simcode & RECORD.REP == run));
    res.([varPref{run + 1}, delimiter, varSuff{3}]) = ...
        1 - mean(RECORD.ACC(RECORD.SCat == newcode & RECORD.REP == run));
end
res = {struct2table(res)};
