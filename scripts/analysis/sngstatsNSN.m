function res = sngstatsNSN(RECORD)
%SNGSTATSNSN Does some basic data transformation to all noise/signal-noise tasks.
%
%   Basically, the supported tasks are as follows:
%     Symbol
%     Orthograph
%     Tone
%     Pinyin
%     Lexic
%     Semantic
%     DRT
%     CPT1
%     GNGLure
%     GNGFruit
%     DivAtten1
%     DivAtten2

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

%ACCuracy and MRT.
Rate_Overall = mean(RECORD.ACC); %Rate is used in consideration of consistency.
RT_Overall = mean(RECORD.RT(RECORD.ACC == 1));
%1 -> target, 0 -> nontarget.
%Count of hit and false alarm.
Count_hit = sum(RECORD.ACC(RECORD.SCat == 1));
Count_FA = sum(~RECORD.ACC(RECORD.SCat == 0));
%Ratio of hit and false alarm.
Rate_hit = mean(RECORD.ACC(RECORD.SCat == 1));
Rate_FA = mean(~RECORD.ACC(RECORD.SCat == 0));
%Mean RT computation.
RT_hit = mean(RECORD.RT(RECORD.SCat == 1 & RECORD.ACC == 1));
RT_FA = mean(RECORD.RT(RECORD.SCat == 0 & RECORD.ACC == 0));
%d' and c.
[dprime, c] = sngdetect(Rate_hit, Rate_FA);
%Efficiency.
efficiency = asin(sqrt(Count_hit / RT_hit));
%Get these metrics into a table.
res = table(Rate_Overall, RT_Overall, ...
    Count_hit, Count_FA, ...
    Rate_hit, Rate_FA, ...
    RT_hit, RT_FA, ...
    dprime, c, ...
    efficiency);
