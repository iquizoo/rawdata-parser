function [stats, labels] = sngprocSAT(RT, ACC)
%SNGPROCSAT Takes into consideration of Speed Accuracy Tradeoff.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

% set the RT for no response trials as missing
RT(ACC == -1) = NaN;
% two-step protocol to remove RT outliers
RT = rmoutlier(RT);

[stats, labels] = SAT(RT, ACC);
