function res = sngprocMT(RECORD)
%SNGPROCMT Does some basic data transformation to memory tail task.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

res = table;
allFeedBacks = strjoin(RECORD.Feedback, '');
res.ACC = mean(allFeedBacks == '1');
