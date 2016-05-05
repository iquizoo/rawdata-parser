function res = sngstatsCRT(RECORD)
%SNGSTATSCRT Does some basic data transformation to choice reaction time tasks.
%
%   Basically, the supported tasks are as follows:
%     CRT
%   The output table contains 6 variables, called ACC, MRT, VRT, v, a, Ter.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

%RT and ACC.
ACC = mean(RECORD.ACC);
MRT = mean(RECORD.RT(RECORD.ACC == 1));
%Standard deviation of RTs.
VRT = std(RECORD.RT(RECORD.ACC == 1));
%Calculate variables defined by a diffusion model.
[v, a, Ter] = EZdif(ACC, MRT / 10 ^ 3, VRT ^ 2 / 10 ^ 6);
res = table(ACC, MRT, VRT, v, a, Ter);
