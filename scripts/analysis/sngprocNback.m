function res = sngprocNback(RECORD)
%SNGPROCNBACK Does some basic data transformation to n-back tasks.
%
%   Basically, the supported tasks are as follows:
%     Nback1-2
%   The output table contains 2 variables, called ACC, RT.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

res = table;
res.ACC = length(RECORD.ACC(RECORD.ACC == 1)) / length(RECORD.ACC);
res.RT = mean(RECORD.RT);
