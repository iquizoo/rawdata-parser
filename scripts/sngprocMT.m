function [stats, labels] = sngprocMT(CSeries, RSeries)
%SNGPROCMT does some basic data transformation to memory tail task.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

CSeries = strjoin(CSeries, '');
RSeries = strjoin(RSeries, '');
ACC = mean(CSeries == RSeries);
stats = ACC;
labels = 'ACC';
