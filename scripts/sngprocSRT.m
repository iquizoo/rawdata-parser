function [stats, labels] = sngprocSRT(RT, ACC)
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

% record total and responded trials numbers
NTrial = length(RT);
NResp = sum(ACC ~= -1);
% set the RT for no response trials as missing
RT(ACC == -1) = NaN;
% two-step protocol to remove RT outliers
% 1. lower cut-off: 100
RT(RT < 100) = NaN;
% 2. iqr-based cut-off
RT(outlier(RT)) = NaN;
% set ACC of outlier and -1 trials as NaN (not included)
ACC(isnan(RT) | ACC == -1) = NaN;
% record included trials number
NInclude = sum(~isnan(ACC));
PE = 1 - nanmean(ACC);
MRT = mean(RT(ACC == 1));
SRT = std(RT(ACC == 1));
stats = [NTrial, NResp, NInclude, PE, MRT, SRT];
labels = {'NTrial', 'NResp', 'NInclude', 'PE', 'MRT', 'SRT'};
