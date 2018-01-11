function [stats, labels] = sngprocMemrep(RT, ACC, REP)
%SNGPROCSMEMREP analyzes data of repetition memory task

% By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com
% Change log
%   01/10/2018 support new protocol of analysis

% count the trials of response (no response means -1 of ACC)
NTrial = length(RT);
NResp = sum(ACC ~= -1);
% accuracy is of interest, so trials with no response or too quick response
% will be treated as incorrect ones
ACC(ACC == -1 | RT < 100) = 0;
% get the proportion of correct for total and each repetition
PC = mean(ACC);
PC_rep = grpstats(ACC, REP, 'mean');
% check results
PC_rep_full = nan(2, 1);
[~, loc] = ismember(unique(REP), 1:2);
PC_rep_full(loc) = PC_rep;
% compose return values
stats = [NTrial, NResp, PC, PC_rep_full'];
labels = {'NTrial', 'NResp', 'PC', 'PC_R1', 'PC_R2'};
