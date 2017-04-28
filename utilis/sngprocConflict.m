function res = sngprocConflict(RECORD)
%SNGPROCCONFLICT does some basic data transformation to conflict-based tasks.
%
% Reference:
%   Vandierendonck, A.
%   A comparison of methods to combine speed and accuracy measures of
%   performance: A rejoinder on the binning procedure
%   Behavior Research Methods, 2016, 1-21

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

congcode = 1;
incongcode = 2;
% total conditions.
res_total = sngprocSAT(RECORD);
res_total.Properties.VariableNames = ...
    strcat(res_total.Properties.VariableNames, '_Overall');
% condition of congruent.
congtrials    = RECORD(RECORD.SCat == congcode, :);
res_congruent = sngprocSAT(congtrials);
res_congruent.lisas = ...
    res_congruent.MRT + res_congruent.PE * (res_total.SRT_Overall / res_total.SPE_Overall);
res_congruent.Properties.VariableNames = ...
    strcat(res_congruent.Properties.VariableNames, '_Congruent');
% condition of incongruent/switch.
incongtrials    = RECORD(RECORD.SCat == incongcode, :);
res_incongruent = sngprocSAT(incongtrials);
res_incongruent.lisas = ...
    res_incongruent.MRT + res_incongruent.PE * (res_total.SRT_Overall / res_total.SPE_Overall);
res_incongruent.Properties.VariableNames = ...
    strcat(res_incongruent.Properties.VariableNames, '_Incongruent');
% congruent effect.
res = [res_total, res_congruent, res_incongruent];
res.MRT_CongEffect = res.MRT_Incongruent - res.MRT_Congruent;
res.ACC_CongEffect = res.ACC_Congruent - res.ACC_Incongruent;
res.v_CongEffect   = res.v_Congruent - res.v_Incongruent;
res.lisas_CongEffect = res.lisas_Incongruent - res.lisas_Congruent;
%The score based NIH instructions.
ACC = res.ACC_Overall;
RT  = res.MedRT_Incongruent;
if RT < 500
    RT = 500;
end
res.NIHScore = asin(sqrt(ACC)) / (pi / 2) + (log(2500) - log(RT)) / (log(2500) - log(500));
