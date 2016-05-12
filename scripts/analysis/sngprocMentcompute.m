function res = sngprocMentcompute(splitRes)
%SNGPROCMENTCOMPUTE Does some basic data transformation to mental computation task.
%
%   Basically, the supported tasks are as follows:
%     20. SpeedAdd
%     21. SpeedSubtract
%   The output table contains 18 variables.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

% The task sets the minimum addition/subtraction number in 8 possible
% numbers: 1 through 8.
MinNum = 1:8;
outvars = {};
for imin = MinNum
    outvars = [outvars, {['RT', num2str(imin)], ['ACC', num2str(imin)]}]; %#ok<*AGROW>
end
outvars = [outvars, {'RT', 'ACC'}];
if ~istable(splitRes{:}) || isempty(splitRes{:})
    res = {array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars)};
    return
end
RECORD = splitRes{:}.RECORD{:};

%Cutoff RTs: eliminate RTs that are too fast (<100ms).
RECORD(RECORD.RT < 100, :) = [];
% % In need of the consistency of results, 4 runs are urgent. Calculate RT and ACC for each run.
% runs = 1:4;
% %RT and ACC for each run.
% for irun = runs
%     res.(['RT_R', num2str(irun)]) = mean(RECORD.RT(RECORD.RUN == irun & RECORD.ACC == 1));
%     res.(['ACC_R', num2str(irun)]) = mean(RECORD.ACC(RECORD.RUN == irun));
% end
%Mean RT and ACC for each minimun add/subtract number.
minnum = rowfun(@min, RECORD, 'InputVariables', {'NX', 'NY'}, 'OutputFormat', 'uniform');
for imin = MinNum
    res.(['RT', num2str(imin)]) = nanmean(RECORD.RT(minnum == imin & RECORD.ACC == 1));
    res.(['ACC', num2str(imin)]) = nanmean(RECORD.ACC(minnum == imin));
end
res.RT = nanmean(RECORD.RT(RECORD.ACC == 1));
res.ACC = nanmean(RECORD.ACC);
res = {struct2table(res)};
