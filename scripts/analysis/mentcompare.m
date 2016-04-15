function res = mentcompare(TaskIDName, splitRes)
%MENTCOMPARE Does some basic data transformation to mental comparison task.
%
%   Basically, the supported tasks are as follows:
%     22. DigitCmp
%     23. CountSense
%   The output table contains 14 variables.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

%Get the specific setting for this task.
switch TaskIDName{:}
    case 'DigitCmp'
        cmpRng = 1:6;
        inputVars = {'NL', 'NR'};
    case 'CountSense'
        cmpRng = [1:4, 5, 8];
        inputVars = {'NR', 'NB'};
end
outvars = {};
for irng = cmpRng
    outvars = [outvars, {['RT', num2str(irng)], ['ACC', num2str(irng)]}]; %#ok<*AGROW>
end
outvars = [outvars, {'RT', 'ACC'}];
if ~istable(splitRes{:})
    res = {array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars)};
    return
end
RECORD = splitRes{:}.RECORD{:};
%Cutoff RTs: eliminate RTs that are too fast (<100ms).
RECORD(RECORD.RT < 100, :) = [];
cmprng = abs(rowfun(@minus, RECORD, 'InputVariables', inputVars, 'OutputFormat', 'uniform'));
for irng = cmpRng
    res.(['RT', num2str(irng)]) = nanmean(RECORD.RT(cmprng == irng & RECORD.ACC == 1));
    res.(['ACC', num2str(irng)]) = nanmean(RECORD.ACC(cmprng == irng));
end
res.RT = nanmean(RECORD.RT(RECORD.ACC == 1));
res.ACC = nanmean(RECORD.ACC);
res = {struct2table(res)};
