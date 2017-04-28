function res = sngprocSwitch(RECORD)
%SNGPROCSWITCH does some basic data transformation to conflict-based tasks.
% Reference:
%   Vandierendonck, A.
%   A comparison of methods to combine speed and accuracy measures of
%   performance: A rejoinder on the binning procedure
%   Behavior Research Methods, 2016, 1-21

%By Zhang, Liang. 08/23/2016. E-mail:psychelzh@gmail.com

repcode = 1;
swtcode = 2;
%Overall RT and ACC.
res_total = sngprocSAT(RECORD);
res_total.Properties.VariableNames = ...
    strcat(res_total.Properties.VariableNames, '_Overall');
%Condition-wise analysis. Here the abnormal trials are included.
%Condition of congruent/repeat.
reptrials  = RECORD(RECORD.SCat == repcode, :);
res_repeat = sngprocSAT(reptrials);
res_repeat.lisas = ...
    res_repeat.MRT + res_repeat.PE * (res_total.SRT_Overall / res_total.SPE_Overall);
res_repeat.Properties.VariableNames = strcat(res_repeat.Properties.VariableNames, '_Repeat');
%Condition of incongruent/switch.
swttrials  = RECORD(RECORD.SCat == swtcode, :);
res_switch = sngprocSAT(swttrials);
res_switch.lisas = ...
    res_switch.MRT + res_switch.PE * (res_total.SRT_Overall / res_total.SPE_Overall);
res_switch.Properties.VariableNames = strcat(res_switch.Properties.VariableNames, '_Switch');
%The last two output variables for conflict effect.
res = [res_total, res_repeat, res_switch];
res.MRT_SwitchCost = res.MRT_Switch - res.MRT_Repeat;
res.ACC_SwitchCost = res.ACC_Repeat - res.ACC_Switch;
res.v_SwitchCost   = res.v_Repeat - res.v_Switch;
res.lisas_SwitchCost = res.lisas_Switch - res.lisas_Repeat;
%The score based NIH instructions.
ACC = res.ACC_Overall;
RT  = res.MedRT_Switch;
if RT < 500
    RT = 500;
end
res.NIHScore = asin(sqrt(ACC)) / (pi / 2) + (log(2500) - log(RT)) / (log(2500) - log(500));
