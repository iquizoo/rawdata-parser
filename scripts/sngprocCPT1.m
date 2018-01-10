function [stats, labels] = sngprocCPT1(RT, ACC, SCat)

% no need to remove reaction time outliers
NTrial = length(SCat);
NTarget = sum(SCat == 'Target');
% number of hits
Hits = sum(SCat == 'Target' & ACC == 1);
% number of commission and omission errors
Commissions = sum(SCat == 'Non-Target' & ACC == 0);
Omissions = sum(SCat == 'Target' & ACC == 0);
% mean and standard deviation of hit reation time
MRT = mean(RT(SCat == 'Target' & ACC == 1));
SRT = std(RT(SCat == 'Target' & ACC == 1));
% d' and bias
[dprime, c] = sdt(Hits / NTarget, Commissions / (NTrial - NTarget));
% compose return values
stats = [NTrial, NTarget, Hits, Commissions, Omissions, MRT, SRT, dprime, c];
labels = {'NTrial', 'NTarget', 'Hits', 'Commissions', 'Omissions', 'MRT', 'SRT', 'dprime', 'c'};
