function [hs, hnames] = sngplotebsingleton(tbl, TaskIDName, sngVars)
%SNGPLOTEBSINGLETON Errorbar plot batch job of one single task.
%   EBSNGTASKSINGLETON(TBL, TASKIDNAME, SNGVARS) plot error bar of all the
%   variables indicated by sngVars in the table tbl. In this 'singleton'
%   suffix mode, figures for each variable in sngVars will be generated.
%
%   [HS, HNAMES] = EBSNGTASKSINGLETON(TBL, TASKIDNAME, SNGVARS) also
%   returns the handles of the figures and the recommended names.
%
%   See also SNGPLOTEBMULT, SNGPLOTEBCMB

%By Zhang, Liang. E-Mail:psychelzh@gmail.com

%Initialization jobs.
nsngVars = length(sngVars);
%Preallocation.
hs = gobjects(nsngVars, 1);
hnames = cell(nsngVars, 1);
%Get all the grades for XTickLabel.
grades = cellstr(unique(tbl.grade));
for isngvar = 1:nsngVars
    %Open an invisible figure, add x label, ylabel and set a file name.
    hs(isngvar) = figure;
    hs(isngvar).Visible = 'off';
    %%Get data and plot.
    curSngVar = sngVars{isngvar};
    curTblVar = strcat(TaskIDName, '_', curSngVar);
    %Plot one instance of error bar, use 'sem' as the error.
    mns  = grpstats(tbl.(curTblVar), tbl.grade);
    errs = grpstats(tbl.(curTblVar), tbl.grade, 'sem');
    errorbar(mns, errs)
    %Put text on the error bar to denote the means.
    text(1:length(mns), mns, arrayfun(@(x) sprintf('%.2f', x), mns, 'UniformOutput', false));
    %Set label, title and file name.
    xlabel('Grade')
    [titlevar, label] = var2caption(TaskIDName, curSngVar);
    ylabel(label)
    title(['Error bar (SEM) plot of ', titlevar, ' in task ', TaskIDName]);
    hnames{isngvar} = ['Error bar (SEM) plot of ', titlevar];
    %Set the font and background to make it look better.
    hax = gca;
    hax.YGrid = 'on';
    hax.GridLineStyle = '-';
    hax.XTick = 1:length(grades);
    hax.XTickLabel = grades;
    hax.FontName = 'Gill Sans MT';
    hax.FontSize = 12;
end
