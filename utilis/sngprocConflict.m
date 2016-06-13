function res = sngprocConflict(RECORD, varPref, delimiter, varSuff)
%SNGPROCCONFLICT does some basic data transformation to conflict-based tasks.
%
%   Basically, the supported tasks are as follows:
%     Flanker, Stroop1-2, NumStroop TaskSwicthing.
%   The output table contains 8 variables.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

res = table;
congcode = 1;
incongcode = 2;
%Overall RT and ACC.
res.RT_Overall = mean(RECORD.RT(RECORD.ACC == 1));
res.ACC_Overall = length(RECORD.ACC(RECORD.ACC == 1)) / length(RECORD.ACC);
%Condition-wise analysis. Here the abnormal trials are included.
%Condition of congruent/repeat.
res.([varPref{1}, delimiter, varSuff{2}]) = mean(RECORD.RT(RECORD.SCat == congcode & RECORD.ACC == 1));
res.([varPref{2}, delimiter, varSuff{2}]) = ...
    length(RECORD.ACC(RECORD.ACC == 1 & RECORD.SCat == congcode)) / length(RECORD.ACC(RECORD.SCat == congcode));
%Condition of incongruent/switch.
res.([varPref{1}, delimiter, varSuff{3}]) = nanmean(RECORD.RT(RECORD.SCat == incongcode & RECORD.ACC == 1));
res.([varPref{2}, delimiter, varSuff{3}]) = ...
    length(RECORD.ACC(RECORD.ACC == 1 & RECORD.SCat == incongcode)) / length(RECORD.ACC(RECORD.SCat == incongcode));
%The last two output variables for conflict effect.
res.([varPref{1}, delimiter, varSuff{4}]) = ...
    res.([varPref{1}, delimiter, varSuff{3}]) - res.([varPref{1}, delimiter, varSuff{2}]);
res.([varPref{2}, delimiter, varSuff{4}]) = ...
    res.([varPref{2}, delimiter, varSuff{2}]) - res.([varPref{2}, delimiter, varSuff{3}]);
