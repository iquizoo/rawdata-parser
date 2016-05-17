function [h, hname] = sngplotebcmb(tbl, TaskIDName, chkVarsCat, delimiter, chkVarsCond)
%SNGPLOTEBCMB errorbar plot batch job of one single task.
%   EBSNGTASKCMB(TBL, TASKIDNAME, CHKVARSCAT, DELIMITER, CHKVARSCOND) plot
%   error bar of the data in the tbl of variable composed by TaskIDName and
%   chkVarsPref, chkVarsSuff, sngVars according to the rule used when
%   merging data. In this 'cmb' suffix mode, only one errorbar figure will
%   be generated, in which all the information is combined (so-called
%   'cmb'); condition information (denoted by chkVarsCond) is indicated by
%   legend, and category information (denoted by chkVarsCat) is indicated
%   by y axis.
%
%   [H, HNAME] = EBSNGTASKCMB(TBL, TASKIDNAME, CHKVARSCAT, DELIMITER,
%   CHKVARSCOND) also returns the handle of the figure and the recommended
%   name.
%
%   See also SNGPLOTEBMULT, SNGPLOTEBSINGLETON

%By Zhang, Liang. E-Mail:psychelzh@gmail.com

%Initialization jobs.
nVarCats = length(chkVarsCat);
nVarCond = length(chkVarsCond);
%Determine y axes and labels.
yRTloc = ~cellfun(@isempty, regexp(chkVarsCat, 'RT', 'once'));
axisPos = {'left', 'right'};
ylabels = strrep(chkVarsCat, '_', ' ');
ylabels(yRTloc) = strcat(ylabels(yRTloc), '(ms)');
%Get all the grades for XTickLabel.
grades = cellstr(unique(tbl.grade));
%Open an invisible figure.
h = figure;
h.Visible = 'off';
%Set file name.
hname = 'Error bar (SEM) plot in combination';
%Category-wise error bar plot.
for ivarcat = 1:nVarCats
    yyaxis(axisPos{ivarcat})
    curVarCat = chkVarsCat{ivarcat};
    curTblVars = strcat(TaskIDName, '_', curVarCat, delimiter, chkVarsCond);
    for ivarcond = 1:nVarCond
        curCondTblVar = curTblVars{ivarcond};
        %Plot one instance of error bar, use 'sem' as the error.
        mns  = grpstats(tbl.(curCondTblVar), tbl.grade);
        errs = grpstats(tbl.(curCondTblVar), tbl.grade, 'sem');
        errorbar(mns, errs)
        %Put text on the error bar to denote the means.
        text(1:length(mns), mns, arrayfun(@(x) sprintf('%.2f', x), mns, 'UniformOutput', false));
        ylabel(ylabels{ivarcat})
        hold on
    end
end
%Set the font and background to make it look better.
hax = gca;
hax.YGrid = 'on';
hax.GridLineStyle = '-';
hax.XTick = 1:length(grades);
hax.XTickLabel = grades;
hax.FontName = 'Gill Sans MT';
hax.FontSize = 12;
%Add label to x axis, and set title to it. Note errorbar plot will clear
%all the set of current axis.
xlabel('Grade')
title(['Error bar (SEM) plot in task ', TaskIDName]);
%Use legend to indicate condition information.
legend(chkVarsCond, 'Location', 'north')
