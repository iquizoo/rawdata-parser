function res = sngstatsMemsep(RECORD, varPref, delimiter, varSuff)
%SNGSTATSMEMSEP Does some basic data transformation to memory task.
%
%   Basically, the supported tasks are as follows:
%     PicMemory
%     WordMemory
%   The output table contains 9 variables.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

res = table;
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
