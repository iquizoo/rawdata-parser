function [stats, labels] = sngprocStopSignal(RT, ACC, IsStop, SSD)
%SNGPROCSTOPSIGNAL analyzes stop signal task data to get SSRT.

% By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

% record trial information
NTrial = length(RT);
NResp = sum(ACC ~= -1);
% remove RT's with no response
RT(ACC == -1) = NaN;
% remove RT outlier
RT(~IsStop) = rmoutlier(RT(~IsStop));
ACC(isnan(RT)) = nan;
NInclude = sum(~isnan(ACC));
% mean reaction time and proportion of error for Go and Stop condition
MRT_Go = mean(RT(ACC == 1 & IsStop == 0));
MRT_Stop = mean(RT(ACC == 0 & IsStop == 1));
PE_Go = 1 - nanmean(ACC(IsStop == 0));
PE_Stop = 1 - mean(ACC(IsStop == 1));
% mean SSD
% note: findpeaks are from signal processing toolbox
MSSD = mean([findpeaks(SSD(IsStop == 1)); ...
    -findpeaks(-SSD(IsStop == 1))]);
SSRT = MRT_Go - MSSD;
% compose return values
stats = [NTrial, NResp, NInclude, MRT_Go, MRT_Stop, PE_Go, PE_Stop, MSSD, SSRT];
labels = {'NTrial', 'NResp', 'NInclude', 'MRT_Go', 'MRT_Stop', 'PE_Go', 'PE_Stop', 'MSSD', 'SSRT'};
