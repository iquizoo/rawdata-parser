function [h, hname] = sngplotbox(tbl, TaskIDName, chkVar, outliermode)
%SNGPLOTBOX Boxplot batch job of one single task.
%   BPSNGTASK(TBL, TASKIDNAME, CHKVAR) boxplots the data in the tbl of
%   variable composed by TaskIDName and chkVar according to the rule used
%   when merging data.

%By Zhang, Liang. E-Mail:psychelzh@gmail.com

if nargin <= 3
    outliermode = 'extreme';
end
%Plot variable composition.
plotVar = strcat(TaskIDName, '_', chkVar);
whisker = 1.5 * strcmp(outliermode, 'mild') + 3 * strcmp(outliermode, 'extreme');
%Open an invisible figure.
h = figure;
h.Visible = 'off';
hname = ['Box plot of ', strrep(chkVar, '_', ' '), ' through all grades'];
boxplot(tbl.(plotVar), tbl.grade, 'Whisker', whisker);
%Get the name of title and label.
[titlevar, label] = var2caption(TaskIDName, chkVar);
title(['Box plot of ', titlevar, ' in task ', TaskIDName, ' through all grades'])
%Set x tick labels (add the count of outlier numbers).
grades       = cellstr(unique(tbl.grade));
outliers     = cellfun(@num2str, ...
    num2cell(splitapply(@(x) coutlier(x, outliermode), ...
    tbl.(plotVar), findgroups(tbl.grade))), 'UniformOutput', false);
%Add spaces before the grade number to make it align at the center.
outlierPre   = 'Outliers: ';
gradePre     = arrayfun(@(rep) repmat(' ', 1, rep), ...
    cellfun(@(str) ceil((length(outlierPre) + length(str)) / 2), outliers), ...
    'UniformOutput', false);
gradeSuff    = '\newline';
gradesLine   = strcat(gradePre, grades, gradeSuff);
outliersLine = strcat({outlierPre}, outliers);
xticks       = strcat(gradesLine, outliersLine);
%Set some of the axes properties in order for better visulization.
hax = gca;
hax.TickLabelInterpreter = 'tex';
hax.XTickLabel    = xticks;
hax.XLabel.String = 'Grade';
hax.YLabel.String = label;
hax.FontName = 'Gill Sans MT';
hax.FontSize = 12;
