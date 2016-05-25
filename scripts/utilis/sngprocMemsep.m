function res = sngprocMemsep(RECORD, varPref, delimiter, varSuff)
%SNGPROCMEMSEP Does some basic data transformation to memory task.
%
%   Basically, the supported tasks are as follows:
%     PicMemory WordMemory
%   The output table contains 9 variables.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

res = table;
res.MRT = mean(RECORD.RT(RECORD.ACC == 1));
%Code for each category of stimuli.
oldcode = 1;
simcode = 2;
newcode = 3;
%Overall hit and false alarm rate.
oldTrials = RECORD(RECORD.SCat == oldcode, :);
res.([varPref{1}, delimiter, varSuff{1}]) = length(oldTrials.ACC(oldTrials.ACC == 1)) / length(oldTrials.ACC);
simTrials = RECORD(RECORD.SCat == simcode, :);
res.([varPref{1}, delimiter, varSuff{2}]) = 1 - length(simTrials.ACC(simTrials.ACC == 1)) / length(simTrials.ACC);
newTrials = RECORD(RECORD.SCat == newcode, :);
res.([varPref{1}, delimiter, varSuff{3}]) = 1 - length(newTrials.ACC(newTrials.ACC == 1)) / length(newTrials.ACC);
%Run-wise hit and false alarm rate.
runs = 1:2;
for run = runs
    curRunOldTrials = oldTrials(oldTrials.REP == run, :);
    res.([varPref{run + 1}, delimiter, varSuff{1}]) = ...
        length(curRunOldTrials.ACC(curRunOldTrials.ACC == 1)) / length(curRunOldTrials.ACC);
    curRunSimTrials = simTrials(simTrials.REP == run, :);
    res.([varPref{run + 1}, delimiter, varSuff{2}]) = ...
        1 - length(curRunSimTrials.ACC(curRunSimTrials.ACC == 1)) / length(curRunSimTrials.ACC);
    curRunNewTrials = newTrials(newTrials.REP == run, :);
    res.([varPref{run + 1}, delimiter, varSuff{3}]) = ...
        1 - length(curRunNewTrials.ACC(curRunNewTrials.ACC == 1)) / length(curRunNewTrials.ACC);
end
res.dprimeTM = sgldetect(res.([varPref{1}, delimiter, varSuff{1}]), res.([varPref{1}, delimiter, varSuff{3}]));
res.dprimeFM = sgldetect(res.([varPref{1}, delimiter, varSuff{2}]), res.([varPref{1}, delimiter, varSuff{3}]));
