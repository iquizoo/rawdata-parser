function res = sngprocStopSignal(RECORD)
%SNGPROCBART Does some basic data transformation to BART task.
%
%   Basically, the supported tasks are as follows:
%     StopSignal
%   The output table contains 1 variables, called SSRT.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com
res = table;
% findpeaks are from signal processing toolbox.
SSD = mean([findpeaks(RECORD.SSD(RECORD.IsStop == 1)); ...
    -findpeaks(-RECORD.SSD(RECORD.IsStop == 1))]);
MedGoRT = median(RECORD.RT(RECORD.ACC == 1 & RECORD.IsStop == 0));
res.SSRT = MedGoRT - SSD;
res.ACC = mean(RECORD.ACC(RECORD.IsStop == 0));
