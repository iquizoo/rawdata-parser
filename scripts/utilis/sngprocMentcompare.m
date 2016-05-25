function res = sngprocMentcompare(RECORD)
%SNGPROCMENTCOMPARE Does some basic data transformation to mental comparison task.
%
%   Basically, the supported tasks are as follows:
%     DigitCmp CountSense
%   The output table contains 14 variables.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

%Cutoff RTs: eliminate RTs that are too fast (<100ms).

res = table;
res.ACC_Overall = length(RECORD.ACC(RECORD.ACC == 1)) / length(RECORD.ACC);
res.RT_Overall = mean(RECORD.RT(RECORD.ACC == 1));
distances = unique(RECORD.SCat);
ndist     = length(distances);
varSuff   = strcat('D', cellfun(@num2str, num2cell(distances), 'UniformOutput', false));
for idist = 1:ndist
    res.(strcat('RT', '_', varSuff{idist})) = mean(RECORD.RT(RECORD.ACC == 1 & RECORD.SCat == distances(idist)));
    res.(strcat('ACC', '_', varSuff{idist})) = ...
        length(RECORD.ACC(RECORD.ACC == 1 & RECORD.SCat == distances(idist))) / length(RECORD.ACC(RECORD.SCat == distances(idist)));
end

