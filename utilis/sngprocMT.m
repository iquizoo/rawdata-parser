function res = sngprocMT(RECORD)
%SNGPROCMT Does some basic data transformation to memory tail task.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

res = table;
CSeries = strjoin(RECORD.CSeries, '');
RSeries = strjoin(RECORD.RSeries, '');
res.ACC = mean(CSeries == RSeries);
