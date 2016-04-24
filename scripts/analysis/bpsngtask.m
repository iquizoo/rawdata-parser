function bpsngtask(tbl, TaskIDName, chkVar, whisker)
%BPSNGTASK Boxplot batch job of one single task.
%   BPSNGTASK(TBL, TASKIDNAME, CHKVAR) boxplots the data in the tbl of
%   variable composed by TaskIDName and chkVar according to the rule used
%   when merging data.

%By Zhang, Liang. E-Mail:psychelzh@gmail.com

if nargin <= 3
    whisker = 3;
end
%Plot variable composition.
plotVar = strcat(TaskIDName, '_', chkVar);
boxplot(tbl.(plotVar), tbl.grade, 'Whisker', whisker);
xlabel('Grade')
%Get the name of title and label.
[titlevar, label] = var2caption(TaskIDName, chkVar);
title(['Box plot of ', titlevar, ' in task ', TaskIDName, ' through all grades'])
ylabel(label)
set(gca, 'FontName', 'Gill Sans MT')
set(gca, 'FontSize', 12)
