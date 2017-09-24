function res = sngprocControl(RECORD)
%SNGPROCCONTROL does some basic data transformation to conflict-based tasks.
%
% Reference:
%   Vandierendonck, A.
%   A comparison of methods to combine speed and accuracy measures of
%   performance: A rejoinder on the binning procedure
%   Behavior Research Methods, 2016, 1-21

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

Acode = 1; Bcode = 2;
Asuffix = 'CondA'; Bsuffix = 'CondB'; TotalSuffix = 'Overall';
delimiter = '_';
% total conditions.
res_total = sngprocSAT(RECORD);
lisas_weight = res_total.SRT / res_total.SPE;
res_total.Properties.VariableNames = ...
    strcat(res_total.Properties.VariableNames, delimiter, TotalSuffix);
% condition of congruent.
Atrials    = RECORD(RECORD.SCat == Acode, :);
res_condA = sngprocSAT(Atrials);
res_condA.lisas = res_condA.MRT + res_condA.PE * lisas_weight;
res_condA.Properties.VariableNames = ...
    strcat(res_condA.Properties.VariableNames, delimiter, Asuffix);
% condition of incongruent/switch.
Btrials    = RECORD(RECORD.SCat == Bcode, :);
res_condB = sngprocSAT(Btrials);
res_condB.lisas = res_condB.MRT + res_condB.PE * lisas_weight;
res_condB.Properties.VariableNames = ...
    strcat(res_condB.Properties.VariableNames, delimiter, Bsuffix);
% congruent effect.
res = [res_total, res_condA, res_condB];
diffVars = {'MRT', 'ACC', 'v', 'lisas'};
for diffVar = diffVars
    res.(strcat(diffVar{:}, delimiter, 'BAdiff')) = ...
        res.(strcat(diffVar{:}, delimiter, Bsuffix)) - ...
        res.(strcat(diffVar{:}, delimiter, Asuffix));
end
%The score based NIH instructions.
ACC = res.(strcat('ACC', delimiter, TotalSuffix));
RT  = res.(strcat('MedRT', delimiter, Bsuffix));
if RT < 500, RT = 500; end
res.NIHScore = ...
    asin(sqrt(ACC)) / (pi / 2) + ...
    (log(2500) - log(RT)) / (log(2500) - log(500));
