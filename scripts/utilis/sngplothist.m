function [hs, hnames] =  sngplothist(tbl, TaskIDName)
%SNGPLOTHIST plots histograms for all the vaiables of each grade.
%   HISTSNGTASK(TBL, TASKIDNAME) plot all the histograms.
%
%   [H, HNAME] = EBSNGTASKCMB(TBL, TASKIDNAME) also returns the handle of
%   the figure and the recommended name.

%By Zhang, Liang. E-Mail:psychelzh@gmail.com

allTblVars = tbl.Properties.VariableNames;
plotVars = allTblVars(~cellfun(@isempty, strfind(allTblVars, TaskIDName)));
nPlotVars = length(plotVars);
%Get all the grades.
grades = cellstr(unique(tbl.grade));
nGrades = length(grades);
hs = cell(nGrades, nPlotVars);
hnames = cell(nGrades, nPlotVars);
for igrade = 1:nGrades
    curGrade = grades{igrade};
    for iplotvar = 1:nPlotVars
        %Open an invisible figure.
        hcurPlot = figure;
        hcurPlot.Visible = 'off';
        hs{igrade, iplotvar} = hcurPlot;
        %Get data and plot.
        curPlotVar = plotVars{iplotvar};
        curGradeData = tbl.(curPlotVar)(tbl.grade == curGrade);
        histogram(curGradeData)
        %Get the name of title and label.
        curVarName = regexp(curPlotVar, ...
            ['(?<=', TaskIDName, '_).*'], 'match', 'once');
        varNameSplit = strsplit(curVarName, '_');
        varNameSplit = strrep(varNameSplit, 'prime', '''');
        if length(varNameSplit) > 1
            labelSwitchTasks = {'PicMemory', 'WordMemory'};
            if ismember(TaskIDName, labelSwitchTasks)
                label = varNameSplit{2};
            else
                if strcmp(varNameSplit{2}, 'Overall')
                    label = strrep(varNameSplit{1}, 'Rate', 'ACC');
                else
                    label = varNameSplit{1};
                end
            end
        else
            label = varNameSplit{1};
        end
        titleVarName = strjoin(varNameSplit, ' ');
        label = strrep(label, 'RT', 'RT(ms)');
        %Set title and label.
        title(['Histogram of ', titleVarName, ' in Grade ', curGrade])
        xlabel(label)
        ylabel('Frequency')
        %Set the font and background to make it look better.
        hax = gca;
        hax.YGrid         = 'on';
        hax.GridLineStyle = '-';
        hax.FontName      = 'Gill Sans MT';
        hax.FontSize      = 12;
        hnames{igrade, iplotvar} = ...
            ['Histogram of ', titleVarName, ' in Grade ', curGrade];
    end
end
