function [stats, labels] = sngprocACC(ACC)
%SNGRPOCACC calculates the average accuracy.

% recode -1 as 0
ACC(ACC == -1) = 0;
% calculate the average ACC
stats = mean(ACC);
labels = {'PC'};
