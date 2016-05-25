function res = sngprocNSN(RECORD)
%SNGPROCNSN Does some basic data transformation to all noise/signal-noise tasks.
%
%   Basically, the supported tasks are as follows:
%     Symbol Orthograph Tone Pinyin Lexic Semantic DRT CPT1 CPT2 GNGLure
%     GNGFruit DivAtten1 DivAtten2

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

%ACCuracy and MRT. Note that ACC of -1 denotes MISSING. (Rate is used in
%consideration of consistency.)
Rate_Overall = length(RECORD.ACC(RECORD.ACC == 1)) / length(RECORD.ACC);
RT_Overall = mean(RECORD.RT(RECORD.ACC == 1));
%1 -> target, 0/2 -> nontarget.
%Count of hit and false alarm.
Count_hit = sum(RECORD.ACC(RECORD.SCat == 1 & RECORD.ACC ~= -1));
Count_FA = sum(~RECORD.ACC(RECORD.SCat ~= 1 & RECORD.ACC ~= -1));
%Ratio of hit and false alarm.
Rate_hit = length(RECORD.ACC(RECORD.SCat == 1 & RECORD.ACC == 1)) / length(RECORD.ACC(RECORD.SCat == 1));
% Rate_hit = mean(RECORD.ACC(RECORD.SCat == 1 & RECORD.ACC ~= -1));
Rate_FA = length(RECORD.ACC(RECORD.SCat ~= 1 & RECORD.ACC ~= 1)) / length(RECORD.ACC(RECORD.SCat ~= 1));
% Rate_FA = mean(~RECORD.ACC(RECORD.SCat ~= 1 & RECORD.ACC ~= -1));
%Mean RT computation.
RT_hit = mean(RECORD.RT(RECORD.SCat == 1 & RECORD.ACC == 1));
RT_FA = mean(RECORD.RT(RECORD.SCat ~= 1 & RECORD.ACC == 0));
%d' and c.
[dprime, c] = sgldetect(Rate_hit, Rate_FA);
%Efficiency.
efficiency = asin(sqrt(Count_hit / RT_hit));
%Get these metrics into a table.
res = table(Rate_Overall, RT_Overall, ...
    Count_hit, Count_FA, ...
    Rate_hit, Rate_FA, ...
    RT_hit, RT_FA, ...
    dprime, c, ...
    efficiency);
