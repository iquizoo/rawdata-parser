function res = sngstatsConflict(RECORD, varPref, delimiter, varSuff)
%CONFLICT Does some basic data transformation to conflict-based tasks.
%
%   Basically, the supported tasks are as follows:
%     Flanker,
%     Stroop1-2,
%     NumStroop
%     TaskSwicthing.
%   The output table contains 8 variables.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

res = table;
%Overall RT and ACC.
res.RT_Overall = nanmean(RECORD.RT(RECORD.ACC == 1));
res.ACC_Overall = nanmean(RECORD.ACC);
%Condition-wise analysis.
%Condition of congruent/repeat.
res.([varPref{1}, delimiter, varSuff{2}]) = nanmean(RECORD.RT(RECORD.SCat == 1 & RECORD.ACC == 1));
res.([varPref{2}, delimiter, varSuff{2}]) = nanmean(RECORD.ACC(RECORD.SCat == 1));
%Condition of incongruent/switch.
res.([varPref{1}, delimiter, varSuff{3}]) = nanmean(RECORD.RT(RECORD.SCat == 0 & RECORD.ACC == 1));
res.([varPref{2}, delimiter, varSuff{3}]) = nanmean(RECORD.ACC(RECORD.SCat == 0));
%The last two output variables.
res.([varPref{1}, delimiter, varSuff{4}]) = ...
    res.([varPref{1}, delimiter, varSuff{3}]) - res.([varPref{1}, delimiter, varSuff{2}]);
res.([varPref{2}, delimiter, varSuff{4}]) = ...
    res.([varPref{2}, delimiter, varSuff{2}]) - res.([varPref{2}, delimiter, varSuff{3}]);
