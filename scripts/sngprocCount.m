function [stats, labels] = sngprocCount(RT, ACC)
%SNGPROCCOUNT counts correct and incorrect trials

% record total and responded trials numbers
NTrial = length(RT);
NResp = sum(ACC ~= -1);
% accuracy is of interest, so trials with no response or too quick response
% will be treated as incorrect ones
ACC(ACC == -1 | RT < 100) = 0;
% count trial number of error
NE = sum(ACC == 0);
Time = sum(RT);
% compose return values
stats = [NTrial, NResp, NE, Time];
labels = {'NTrial', 'NResp', 'NE', 'Time'};
