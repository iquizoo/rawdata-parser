function res = sngprocConflict(RECORD)
%SNGPROCCONFLICT does some basic data transformation to conflict-based tasks.
%
%   Basically, the supported tasks are as follows:
%     Flanker, Stroop1-2, NumStroop, TaskSwicthing.
%   The output table contains 8 variables.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

res = table;
congcode = 1;
incongcode = 2;
%Overall RT and ACC.
res.MRT_Overall = mean(RECORD.RT(RECORD.ACC == 1));
res.ACC_Overall = length(RECORD.ACC(RECORD.ACC == 1)) / length(RECORD.ACC);
%Condition-wise analysis. Here the abnormal trials are included.
%Condition of congruent/repeat.
congtrials    = RECORD(RECORD.SCat == congcode, :);
res_congruent = sngprocEZDiff(congtrials);
res_congruent.Properties.VariableNames = strcat(res_congruent.Properties.VariableNames, '_Congruent');
%Condition of incongruent/switch.
incongtrials    = RECORD(RECORD.SCat == incongcode, :);
res_incongruent = sngprocEZDiff(incongtrials);
res_incongruent.Properties.VariableNames = strcat(res_incongruent.Properties.VariableNames, '_Incongruent');
%The last two output variables for conflict effect.
res = [res, res_congruent, res_incongruent];
res.MRT_CongEffect = res.MRT_Incongruent - res.MRT_Congruent;
res.ACC_CongEffect = res.ACC_Congruent - res.ACC_Incongruent;
res.v_CongEffect   = res.v_Congruent - res.v_Incongruent;
