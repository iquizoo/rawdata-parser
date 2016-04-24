function [h, hname] = ebsngtaskcmb(tbl, TaskIDName, chkVarsCat, delimiter, chkVarsCond)
%EBSNGTASKCMB errorbar plot batch job of one single task.
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
%   See also EBSNGTASKMULT, EBSNGTASKSINGLETON

%By Zhang, Liang. E-Mail:psychelzh@gmail.com

%Initialization jobs.
nVarCats = length(chkVarsCat);
nVarCond = length(chkVarsCond);
%Determine y axes and labels.
yRTloc = ~cellfun(@isempty, regexp(chkVarsCat, 'RT', 'once'));
axisPos = {'left', 'right'};
ylabels = strrep(chkVarsCat, '_', ' ');
ylabels{yRTloc} = [ylabels{yRTloc}, '(ms)'];
%Get all the grades for XTickLabel.
grades = cellstr(unique(tbl.grade));
%Open an invisible figure, add label to x axis, and set title to it.
h = figure;
h.Visible = 'off';
xlabel('Grade')
title(['Error bar (SEM) plot in task ', TaskIDName]);
%Set file name.
hname = {['Error bar (SEM) plot', '.png']};
%Category-wise error bar plot.
for ivarcat = 1:nVarCats
    if isDBYaxes % yyaxis will be used.
        yyaxis(axisPos{ivarcat})
    end
    curVarCat = chkVarsCat{ivarcat};
    curTblVars = strcat(TaskIDName, '_', curVarCat, delimiter, chkVarsCond);
    for ivarcond = 1:nVarCond
        %Plot one instance of error bar, use 'sem' as the error.
        errorbar(grpstats(tbl.(curTblVars{ivarcond}), tbl.grade), ...
            grpstats(tbl.(curTblVars{ivarcond}), tbl.grade, 'sem'))
        if isDBYaxes
            ylabel(ylabels{ivarcat})
        end
        %Set the font and background to make it look better.
        hax = gca;
        hax.YGrid = 'on';
        hax.GridLineStyle = '-';
        hax.XTick = 1:length(grades);
        hax.XTickLabel = grades;
        hax.FontName = 'Gill Sans MT';
        hax.FontSize = 12;
        hold on
    end
end
%Use legend to indicate condition information.
legend(chkVarsCond)
