function res = sngprocMemrep(RECORD, varPref, delimiter, varSuff)
%SNGPROCSMEMREP Does some basic data transformation to semantic memory task.
%
%   Basically, the supported tasks are as follows:
%     AssocMemory SemanticMemory
%   The output table contains 9 variables.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

res = table;
%ACC and RT for overall performance.
res.([varPref{1}, delimiter, varSuff{1}]) = length(RECORD.ACC(RECORD.ACC == 1)) / length(RECORD.ACC);
res.([varPref{2}, delimiter, varSuff{1}]) = mean(RECORD.RT(RECORD.ACC == 1));
%Run-wise ACC and RT.
runs = 1:2;
for run = runs
    res.([varPref{1}, delimiter, varSuff{run + 1}]) = ...
        length(RECORD.ACC(RECORD.REP == run & RECORD.ACC == 1)) / length(RECORD.ACC(RECORD.REP == run));
    res.([varPref{2}, delimiter, varSuff{run + 1}]) = ...
        mean(RECORD.RT(RECORD.ACC == 1 & RECORD.REP == run));
end
