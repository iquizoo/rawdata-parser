function [hs, hnames] = ebsngtaskmult(tbl, TaskIDName, chkVarsCat, delimiter, chkVarsCond)
%EBSNGTASKMULT Errorbar plot batch job of one single task.
%   EBSNGTASKMULT(TBL, TASKIDNAME, CHKVARSCAT, DELIMITER, CHKVARSCOND)
%   plot error bar of the data in the tbl of variable composed by
%   TaskIDName and chkVarsPref, chkVarsSuff, sngVars according to the rule
%   used when merging data. In this 'mult' suffix mode, usually more than
%   one errorbar plots will be generated, each of which conveys the
%   information of one condition (denoted by chkVarsCond).
%
%   [HS, HNAMES] = EBSNGTASKMULT(TBL, TASKIDNAME, CHKVARSCAT, DELIMITER,
%   CHKVARSCOND) also returns the handles of the figures and the
%   recommended names.
%
%   See also EBSNGTASKCMB, EBSNGTASKSINGLETON

%By Zhang, Liang. E-Mail:psychelzh@gmail.com

%Input checking.
if nargin < 3
    error('UDF:EBSNGTASKMULT:NOTENOUGHINPUT', 'Argument chkVarsCat is required!\n')
elseif nargin < 4
    delimiter = '';
    chkVarsCond = {''};
end
%Initialization jobs.
nVarCats = length(chkVarsCat);
nVarCond = length(chkVarsCond);
%Determine y axes and labels.
yRTloc = ~cellfun(@isempty, regexp(chkVarsCat, 'RT', 'once'));
isDBYaxes = false;
%Get all the grades for XTickLabel.
grades = cellstr(unique(tbl.grade));
%Preallocation.
hs = gobjects(nVarCond, 1);
hnames = cell(nVarCond, 1);
%Condition-wise error bar plot.
for ivarcond = 1:nVarCond
    curVarCond = chkVarsCond{ivarcond};
    switch nVarCats
        case 1
            ylabels = chkVarsCat;
        case 2
            if all(ismember(chkVarsCat, {'ML', 'MS'}))
                ylabels = 'Length';
            else
                isDBYaxes = true;
                axisPos = {'left', 'right'};
                ylabels = strrep(chkVarsCat, '_', ' ');
                ylabels = strrep(ylabels, 'prime', '''');
                ylabels(yRTloc) = strcat(ylabels(yRTloc), '(ms)');
                if strcmp(curVarCond, 'Overall')
                    ylabels = strrep(ylabels, 'Rate', 'ACC');
                end
            end
        otherwise
            ylabels = curVarCond;
    end
    curTblVars = strcat(TaskIDName, '_', chkVarsCat, delimiter, curVarCond);
    %Open an invisible figure.
    hs(ivarcond) = figure;
    hs(ivarcond).Visible = 'off';
    %Set file name. Transform curVarCond to title-compatible condition name.
    curVarTitle = curVarCond;
    if isempty(curVarCond)
        curVarTitle = strjoin(chkVarsCat, '&');
    end
    hnames{ivarcond} = ['Error bar (SEM) plot of ', curVarTitle];
    for ivarcat = 1:nVarCats
        if isDBYaxes % yyaxis will be used.
            yyaxis(axisPos{ivarcat})
        end
        %Plot one instance of error bar, use 'sem' as the error.
        errorbar(grpstats(tbl.(curTblVars{ivarcat}), tbl.grade), ...
            grpstats(tbl.(curTblVars{ivarcat}), tbl.grade, 'sem'))
        if isDBYaxes
            ylabel(ylabels{ivarcat})
        end
        hold on
    end
    %Set the font and background to make it look better.
    hax = gca;
    hax.YGrid = 'on';
    hax.GridLineStyle = '-';
    hax.XTick = 1:length(grades);
    hax.XTickLabel = grades;
    hax.FontName = 'Gill Sans MT';
    hax.FontSize = 12;
    %Add label to x axis, and set title to it. Note errorbar plot will
    %clear all the set of current axis.
    xlabel('Grade')
    title(['Error bar (SEM) plot of ', curVarTitle, ' in task ', TaskIDName]);
    if ~isDBYaxes % yyaxis not used.
        ylabel(ylabels)
        if nVarCats > 1 % nonsingleton variable category, then use legend to denote variable category.
            legend(chkVarsCat, 'Location', 'best')
        end
    end
end
