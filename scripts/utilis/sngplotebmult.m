function [hs, hnames] = sngplotebmult(tbl, TaskIDName, chkVarsCat, delimiter, chkVarsCond)
%SNGPLOTEBMULT Errorbar plot batch job of one single task.
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
%   See also SNGPLOTEBCMB, SNGPLOTEBSINGLETON

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
%Determine y axes, the first step. Read the second step at line 50.
yRTloc = ~cellfun(@isempty, regexp(chkVarsCat, 'RT|Time', 'once'));
if all(yRTloc) || all(~yRTloc)
    isDBYaxes = false;
else
    isDBYaxes = true;
    axisPos = {'left', 'right'};
    varAxisPos = nan(1, nVarCats);
    %For time related variables, use a different axis.
    varAxisPos(yRTloc) = 2 - (yRTloc(1) == true);
    varAxisPos(~yRTloc) = (yRTloc(1) == true) + 1;
end
%Get all the grades for XTickLabel.
grades = cellstr(unique(tbl.grade));
%Preallocation.
hs = cell(nVarCond, 1);
hnames = cell(nVarCond, 1);
%Condition-wise error bar plot.
for ivarcond = 1:nVarCond
    curVarCond = chkVarsCond{ivarcond};
    curTblVars = strcat(TaskIDName, '_', chkVarsCat, delimiter, curVarCond);
    %Determine y axes, the second step.
    if ~isDBYaxes && nVarCats > 1
        curCondCatsMean = nanmean(tbl{:, ismember(tbl.Properties.VariableNames, curTblVars)});
        contrasts = nchoosek(1:nVarCats, 2);
        contrastsMean = curCondCatsMean(contrasts);
        contrastsResult = abs(bsxfun(@rdivide, contrastsMean(:, 1), contrastsMean(:, 2)));
        if any(contrastsResult > 5) || any(contrastsResult < 0.2)
            %This means the average of different variables are largely
            %(arbitrarily set at level 5 (0.2) now) diffrent, which makes
            %two axes necessary.
            isDBYaxes = true;
            axisPos = {'left', 'right'};
            contrastsResult(contrastsResult <= 1) = 1 ./ contrastsResult(contrastsResult <= 1);
            contrasts(contrastsResult <= 1, :) = contrasts(contrastsResult <= 1, end:-1:1);
            [~, idx] = sort(contrastsResult);
            varAxisPos = nan(1, nVarCats);
            %Larger scale uses the right axes.
            largerAxis = ismember(1:nVarCats, contrasts(idx(1), 1));
            varAxisPos(largerAxis) = 2 - (largerAxis(1) == true);
            varAxisPos(~largerAxis) = 1 + (largerAxis(1) == true);
        end
    end
    %Open an invisible figure for each condition.
    hcurPlot = figure;
    hcurPlot.Visible = 'off';
    hs{ivarcond} = hcurPlot;
    %Set file name. Transform curVarCond to title-compatible condition name.
    curVarTitle = curVarCond;
    if isempty(curVarCond)
        curVarTitle = strjoin(chkVarsCat, '&');
    end
    hnames{ivarcond} = ['Error bar (SEM) plot of ', curVarTitle];
    %Use showLegend to denote whether legend is needed.
    showLegend = false;
    if nVarCats > 2 || (nVarCats == 2 && ~isDBYaxes)
        showLegend = true;
    end
    for ivarcat = 1:nVarCats
        curTblVar = curTblVars{ivarcat};
        %Set ylabel string.
        yLabel = regexp(curTblVar, 'Rate|ACC|Count|RT|Time', 'match', 'once');
        if isempty(yLabel)
            yLabel = 'Arbitrary Unit';
            showLegend = true; %Set it to true to separate different variables.
        end
        if ismember(ivarcat, find(yRTloc))
            if any(tbl.(curTblVar) > 10 ^ 4) %Transform unit to secs.
                tbl.(curTblVar) = tbl.(curTblVar) / 10 ^ 3;
                yLabel = strcat(yLabel, '(s)');
            else
                yLabel = strcat(yLabel, '(ms)');
            end
        end
        if strcmp(curVarCond, 'Overall')
            yLabel = strrep(yLabel, 'Rate', 'ACC');
        end
        %Prepare the axis.
        if isDBYaxes % yyaxis will be used.
            yyaxis(axisPos{varAxisPos(ivarcat)})
        end
        %Plot one instance of error bar, use 'sem' as the error.
        mns  = grpstats(tbl.(curTblVar), tbl.grade);
        errs = grpstats(tbl.(curTblVar), tbl.grade, 'sem');
        errorbar(mns, errs)
        %Put text on the error bar to denote the means.
        text(1:length(mns), mns, arrayfun(@(x) sprintf('%.2f', x), mns, 'UniformOutput', false));
        ylabel(yLabel)
        hold on
    end
    %Set the font and background to make it look better.
    hax = gca;
    hax.YGrid         = 'on';
    hax.GridLineStyle = '-';
    hax.XTick         = 1:length(grades);
    hax.XTickLabel    = grades;
    hax.FontName      = 'Gill Sans MT';
    hax.FontSize      = 12;
    %Add label to x axis, and set title to it. Note errorbar plot will
    %clear all the set of current axis.
    xlabel('Grade')
    title(['Error bar (SEM) plot of ', curVarTitle, ' in task ', TaskIDName]);
    if showLegend
        chkVarsCat = strrep(chkVarsCat, 'prime', '''');
        legend(chkVarsCat, 'Location', 'best', 'FontSize', 9)
    end
end
