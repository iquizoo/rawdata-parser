function res = sngprocBART(RECORD)
%SNGPROCBART Does some basic data transformation to BART task.
%
%   Basically, the supported tasks are as follows:
%     BART
%   The output table contains 1 variables, called MNHit.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

res = table;
res.MNHit = nanmean(RECORD.NHit(RECORD.Feedback == 0));
