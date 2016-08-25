function res = sngprocSwitch(RECORD)
%SNGPROCCONFLICT does some basic data transformation to conflict-based tasks.
%
%   Basically, the supported tasks are as follows:
%     TaskSwicthing.
%   The output table contains 8 variables.

%By Zhang, Liang. 08/23/2016. E-mail:psychelzh@gmail.com

res = table;
repcode = 1;
swtcode = 2;
%Remove the first trial.
RECORD(1, :) = [];
%Overall RT and ACC.
res.MRT_Overall = mean(RECORD.RT(RECORD.ACC == 1));
res.ACC_Overall = length(RECORD.ACC(RECORD.ACC == 1)) / length(RECORD.ACC);
%Condition-wise analysis. Here the abnormal trials are included.
%Condition of congruent/repeat.
reptrials    = RECORD(RECORD.SCat == repcode, :);
res_repeat = sngprocEZDiff(reptrials);
res_repeat.Properties.VariableNames = strcat(res_repeat.Properties.VariableNames, '_Repeat');
%Condition of incongruent/switch.
swttrials    = RECORD(RECORD.SCat == swtcode, :);
res_switch = sngprocEZDiff(swttrials);
res_switch.Properties.VariableNames = strcat(res_switch.Properties.VariableNames, '_Switch');
%The last two output variables for conflict effect.
res = [res, res_repeat, res_switch];
res.MRT_SwitchCost = res.MRT_Switch - res.MRT_Repeat;
res.ACC_SwitchCost = res.ACC_Repeat - res.ACC_Switch;
res.v_SwitchCost   = res.v_Repeat - res.v_Switch;
%The score based NIH instructions.
ACC = res.ACC_Overall;
RT  = res.MedRT_Switch;
if RT < 500
    RT = 500;
end
res.NIHScore = asin(sqrt(ACC)) / (pi / 2) + (log(2500) - log(RT)) / (log(2500) - log(500));
