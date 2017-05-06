function res = sngprocTMT(RECORD)
%SNGPROCTMT calculates indicators for trail making test.

%By Zhang, Liang. 04/27/2017. E-mail:psychelzh@gmail.com

Acode = 1;
Bcode = 2;
NE_CondA = median(RECORD.NWrong(RECORD.SCat == Acode));
NE_CondB = median(RECORD.NWrong(RECORD.SCat == Bcode));
NE_BA = NE_CondB - NE_CondA;
MedRT_CondA = median(RECORD.RT(RECORD.SCat == Acode));
MedRT_CondB = median(RECORD.RT(RECORD.SCat == Bcode));
MedRT_BAdiff  = MedRT_CondB - MedRT_CondA;
MedRT_BAratio = MedRT_CondB / MedRT_CondA;
res = table(NE_CondA, NE_CondB, NE_BA, MedRT_CondA, MedRT_CondB, MedRT_BAdiff, MedRT_BAratio);
