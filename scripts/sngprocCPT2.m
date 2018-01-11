function [stats, labels] = sngprocCPT2(RT, ACC, SCat)
%SNGPROCCPT2 analyzes data from harder version of CPT

% set those too-quick reponse as error
ACC(RT < 100) = 0;
% count trial number for each type
NTrial = length(SCat);
NTarget = sum(SCat == 'Target');
NXonly = sum(SCat == 'Xonly');
NAonly = sum(SCat == 'Aonly');
NAnotX = sum(SCat == 'AnotX');
% number of hits
Hits = sum(SCat == 'Target' & ACC == 1);
% number of commission and omission errors
Commissions = sum(SCat ~= 'Target' & ACC == 0);
Omissions = sum(SCat == 'Target' & ACC == 0);
% number of Xonly, Aonly and Random errors
EXonly = sum(SCat == 'Xonly' & ACC == 0);
EAonly = sum(SCat == 'Aonly' & ACC == 0);
EAnotX = sum(SCat == 'AnotX' & ACC == 0);
% mean and standard deviation of hit reation time
MRT = mean(RT(SCat == 'Target' & ACC == 1));
SRT = std(RT(SCat == 'Target' & ACC == 1));
% d' and bias
[dprime, c] = sdt(Hits / NTarget, Commissions / (NTrial - NTarget));
% compose return values
stats = [NTrial, NTarget, NXonly, NAonly, NAnotX, ...
    Hits, Commissions, Omissions, EXonly, EAonly, EAnotX, ...
    MRT, SRT, dprime, c];
labels = {'NTrial', 'NTarget', 'NXonly', 'NAonly', 'NAnotX', ...
    'Hits', 'Commissions', 'Omissions', 'EXonly', 'EAonly', 'EAnotX', ...
    'MRT', 'SRT', 'dprime', 'c'};
