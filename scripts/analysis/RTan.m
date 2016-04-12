function res = RTan(qrecord, cate) %#ok<*STOUT>
%Data analysis for reaction time task, the names of which are
%1. '反应速度(simple RT)' (cate = 1)
%2. '分辨速度(discriminant RT)' (cate = 2)
%3. '选择速度(choice RT)' (cate = 3)
%4. '面包大师' (cate = 1)
%5. '超级秒表' (cate = 1)
%6. '速算师' (cate = 1)
%7. '数字魔法师初级' (cate = 1)
%8. '数字魔法师中级' (cate = 2)
%Note: cate is used when calculating score.

%By Zhang Liang, E-mail:psychelzh@gmail.com, 01/19/2016.

if iscell(qrecord)
    qrecord = qrecord{1};
end

%For the task '速算师', there are several runs of trials.
if ismember('RUN', qrecord.Properties.VariableNames)
    runs = unique(qrecord.RUN);
    nrun = length(runs);
    for irun = 1:nrun
        eval(['ACC_R', num2str(irun), '=mean(qrecord.ACC(qrecord.RUN == ', num2str(irun), '));']);
        eval(['RT_R', num2str(irun), '=mean(qrecord.RT(qrecord.ACC == 1 & qrecord.RUN == ', num2str(irun), '));']);
    end
    if nrun < 4
        for irun = nrun:4
            eval(['ACC_R', num2str(irun), '=0;']);
            eval(['RT_R', num2str(irun), '=0;']);
        end
    end
end

ACC = nanmean(qrecord.ACC);
RT = nanmean(qrecord.RT(qrecord.ACC == 1));
score = 1000 + (5500 + 500 * cate - RT) * (ACC + 0.1); %#ok<*NASGU>
allvars = who;
svars = allvars(~cellfun(@isempty, regexp(allvars, '^(ACC|RT)', 'start')));
%Generate the evaluate string.
pre = 'res = table(';
mid = [];
for ivar = 1:length(svars)
    mid = [mid, svars{ivar}, ',']; %#ok<*AGROW>
end
post = 'score);';
eval([pre, mid, post]);
