function score = sngscoreMemory(ACC_R1, ACC_R2, RT_Overall, weight_R1, weight_R2, ntrl)
%

score = 1000 + ntrl * (ACC_R1 * weight_R1 + ACC_R2 * weight_R2) - RT_Overall;
