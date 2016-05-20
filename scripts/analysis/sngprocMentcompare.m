function res = sngprocMentcompare(RECORD)
%SNGPROCMENTCOMPARE Does some basic data transformation to mental comparison task.
%
%   Basically, the supported tasks are as follows:
%     22. DigitCmp
%     23. CountSense
%   The output table contains 14 variables.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

%Cutoff RTs: eliminate RTs that are too fast (<100ms).

res = table;
distances = unique(RECORD.SCat);
ndist     = length(distances);
varSuff   = strcat('D', cellfun(@num2str, num2cell(distances), 'UniformOutput', false));
for idist = 1:ndist
    res.(strcat('RT', '_', varSuff{idist})) = mean(RECORD.RT(RECORD.ACC == 1 & RECORD.SCat == distances(idist)));
end
