function [stats, labels] = sngprocSRT(RT, ACC)
%SNGPROCSRT calculates mean simple reaction time.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com
%Change log:
%   04/21/2016 Add an ACC variable to record accuracy, esp. useful for
%   bread and watch task.
%
%   05/13/2016 ACC records missing information now.

% record total and responded trials numbers
NTrial = length(RT);
NResp = sum(ACC ~= -1);
% set the RT for no response trials as missing
RT(ACC == -1) = NaN;
% two-step protocol to remove RT outliers
RT = rmoutlier(RT);
% set ACC of outlier and -1 trials as NaN (not included)
ACC(isnan(RT) | ACC == -1) = NaN;
% record included trials number
NInclude = sum(~isnan(ACC));
PE = 1 - nanmean(ACC);
MRT = mean(RT(ACC == 1));
SRT = std(RT(ACC == 1));
stats = [NTrial, NResp, NInclude, PE, MRT, SRT];
labels = {'NTrial', 'NResp', 'NInclude', 'PE', 'MRT', 'SRT'};
