function res = sngprocSRT(RECORD)
%SNGPROCSRT Does some basic data transformation to simple reaction time tasks.
%
%   Basically, the supported tasks are as follows:
%     SRT SRTWatch SRTBread
%   The output table contains 3 variables, called ACC, MRT, VRT.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com
%Change log:
%   04/21/2016 Add an ACC variable to record accuracy, esp. useful for
%   bread and watch task.
%
%   05/13/2016 ACC records missing information now.

res = table;
%Accuracy.
res.ACC = length(RECORD.ACC(RECORD.ACC == 1)) / length(RECORD.ACC);
%Mean RT.
res.MRT = mean(RECORD.RT(RECORD.ACC == 1));
%Standard deviation of RT. Square root of variance.
res.VRT = std(RECORD.RT(RECORD.ACC == 1));
