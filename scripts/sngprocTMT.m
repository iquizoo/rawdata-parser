function [stats, labels] = sngprocTMT(RT, NWrong, SCat)
%SNGPROCTMT calculates indicators for trial making test.

% By Zhang, Liang. 04/27/2017. E-mail:psychelzh@gmail.com

% find group information
[grps, gid] = findgroups(SCat);
% get number of error for each category
NE = grpstats(NWrong, grps, 'sum');
% get total used time for each category
Time = grpstats(RT, grps, 'sum');
% compose return values
stats = [NE', Time', NE(2) - NE(1), Time(2) - Time(1), Time(2) / Time(1)];
labels = [strcat('NE_', cellstr(gid))', strcat('Time_', cellstr(gid))', {'NE_diff', 'Time_diff', 'Time_ratio'}];
