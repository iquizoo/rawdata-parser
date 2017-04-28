function res = sngprocTMT(RECORD)
%SNGPROCTMT calculates indicators for trail making test.

%By Zhang, Liang. 04/27/2017. E-mail:psychelzh@gmail.com

Acode = 1;
Bcode = 2;
MedRT_CondA = sum(RECORD.RT(RECORD.SCat == Acode));
MedRT_CondB = sum(RECORD.RT(RECORD.SCat == Bcode));
BAdiff  = MedRT_CondB - MedRT_CondA;
BAratio = MedRT_CondB / MedRT_CondA;
res = table(MedRT_CondA, MedRT_CondB, BAdiff, BAratio);
