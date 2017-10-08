function res = sngprocSAT(RT, ACC)
%SNGPROCSAT Takes into consideration of Speed Accuracy Tradeoff.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

% remove ACC of not 0, 1.
RECORD(~ismember(RECORD.ACC, [0, 1]), :) = [];
% percentage of error and related.
ACC = mean(RECORD.ACC);
angACC = asin(sqrt(ACC));
PE  = 1 - ACC;
SPE = std(RECORD.ACC);
% reaction time and related.
MRT = mean(RECORD.RT(RECORD.ACC == 1));
MedRT = median(RECORD.RT(RECORD.ACC == 1));
SRT = std(RECORD.RT(RECORD.ACC == 0));
% calculate variables defined by a diffusion model. (SAT-I)
[v, a, Ter] = EZdif(ACC, MRT / 10 ^ 3, SRT ^ 2 / 10 ^ 6);
% efficiency. (SAT-II)
efficiency = asin(sqrt(ACC / MRT));
res = table(ACC, angACC, PE, SPE, ...
    MRT, MedRT, SRT, ...
    v, a, Ter, ...
    efficiency);
