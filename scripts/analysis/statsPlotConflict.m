function statsPlotConflict(tbl)
%STATSPLOTCONFLICT Plots basic graphs of report.
%

%By Zhang, Liang. 04/16/2016. E-mai:psychelzh@gmail.com

%% Remove data of undefined school or grade.
tbl(isundefined(tbl.school) | isundefined(tbl.grade), :) = [];
tblVars = tbl.Properties.VariableNames;

%% Get TaskIDName.
VarsOfBasicInformation = {'userId', 'gender', 'school', 'grade'};
VarsOfTaskData = tblVars(~ismember(tblVars, VarsOfBasicInformation));
TaskIDName = regexp(VarsOfTaskData{1}, '^\w+?(?=_)', 'match', 'once');

%% Set the store directories and file names of figures and excels.
% Excel file.
xlsDir = 'Docs';
curTaskXlsDir = [TaskIDName, filesep, xlsDir];
if ~exist(curTaskXlsDir, 'dir')
    mkdir(curTaskXlsDir)
end
% Figures.
figDir = 'Figs';
curTaskFigDir = [TaskIDName, filesep, figDir];
if ~exist(curTaskFigDir, 'dir')
    mkdir(curTaskFigDir)
end

%% Get all the checking variable names to plot.
switch TaskIDName
    case {...
            'Flanker',...
            'Stroop1',...
            'Stroop2',...
            'NumStroop',...
            }
        varSuff = {'_Overall', '_CongEffect'};
    case 'TaskSwitching'
        varSuff = {'_Overall', '_SwitchCost'};
end
varPref = {'RT', 'ACC'};
repVarSuff = repmat(varSuff, length(varPref), 1);
chkVarSuff = repVarSuff(:)';
chkVars = strcat(repmat(varPref, 1, length(varSuff)), chkVarSuff);
tblVars = tbl.Properties.VariableNames;
chkTblVarsLoc = false(size(tblVars));
for ivar = 1:length(chkVars)
    chkTblVarsLoc = chkTblVarsLoc | ...
        ~cellfun(@isempty, regexp(tblVars, ['(?<=_)', chkVars{ivar}, '$'], 'once'));
end
chkTblVars = tblVars(chkTblVarsLoc);

%% Get the checking data and remove those with NaNs.
chkData = tbl{:, chkTblVarsLoc};
tbl(all(isnan(chkData), 2), :) = [];
chkData(all(isnan(chkData), 2), :) = [];
tbl.grade = removecats(tbl.grade);
grades = cellstr(unique(tbl.grade));

%% Write a table of descriptive statistics.
despStats = grpstats(tbl, {'school', 'grade'}, 'numel', 'DataVars', VarsOfTaskData);
outDespStats = despStats(:, 1:3);
writetable(outDespStats, [curTaskXlsDir, filesep, 'Counting of each school and grade.xlsx']);
rmgrade = outDespStats.grade(outDespStats.GroupCount == 1);
if ~isempty(rmgrade)
    tbl(tbl.grade == rmgrade, :) = [];
    tbl.grade = removecats(tbl.grade);
    grades = cellstr(unique(tbl.grade));
    chkData = tbl{:, chkTblVarsLoc};
end

%% Box plot and outliers.
outlierVarPref = {'MildOutlierCount_', 'ExtremeOutlierCount_'};
repOutlierVarSuff = repmat(chkVars, length(outlierVarPref), 1);
outlierVarSuff = repOutlierVarSuff(:)';
outlierVarnames = strcat(repmat(outlierVarPref, 1, length(chkVars)), outlierVarSuff);
curTaskOutlier = grpstats(tbl, 'grade', {@(x)coutlier(x, 'mild'), @(x)coutlier(x, 'extreme')}, ...
    'DataVars', chkTblVars, ...
    'VarNames', [{'grade', 'GroupCount'}, outlierVarnames]);
writetable(curTaskOutlier, [curTaskXlsDir, filesep, 'Counting of outliers of each grade.xlsx']);
for ichk = 1:length(chkTblVars)
    figure
    boxplot(chkData(:, ichk), tbl.grade, 'Whisker', 3);
    xlabel('Grade')
    [taskIDName, desp] = regexp(chkTblVars{ichk}, '^\w+?(?=_)', 'match', 'split', 'once');
    title(['Box plot of', strrep(desp{2}, '_', ' '), ' in task ', taskIDName, ' through all grades'])
    bpylabel = regexp(chkTblVars{ichk}, strjoin(varPref, '|'), 'match', 'once');
    if strcmp(bpylabel, 'MRT') || strcmp(bpylabel, 'RT')
        bpylabel = [bpylabel, '(ms)'];
    end
    ylabel(strrep(bpylabel, '_', ' '))
    hax = gca;
    hax.FontName = 'Gill Sans MT';
    hax.FontSize = 12;
    saveas(gcf, [curTaskFigDir, filesep, ...
        'Box plot of', strrep(desp{2}, '_', ' '),  ' through all grades'], 'jpg');
    close(gcf)
end

%% Write a table about descriptive statistics of different ages.
%Remove extreme outliers.
for igrade = 1:length(grades)
    curgradeidx = tbl.grade == grades{igrade};
    [~, outlieridx] = coutlier(tbl.(VarsOfTaskData{1})(curgradeidx), 'extreme');
    rmidx = curgradeidx;
    rmidx(rmidx == 1) = outlieridx;
    tbl(rmidx, :) = [];
    for ihistVar = 1:length(chkTblVars)
        curgradedata = tbl.(chkTblVars{ihistVar})(tbl.grade == grades{igrade});
        histogram(curgradedata)
        [taskIDName, desp] = regexp(chkTblVars{ihistVar}, '^\w+?(?=_)', 'match', 'split', 'once');
        curChkVar = strrep(desp{2}, '_', ' ');
        title(['Histogram of ', curChkVar, ...
            ' of task ', TaskIDName,' GRADE ', num2str(grades{igrade})])
        if strcmp(curChkVar, 'MRT') || strcmp(curChkVar, 'RT')
            label = [curChkVar, '(ms)'];
        else
            label = curChkVar;
        end
        xlabel(label)
        ylabel('Frequency')
        hax = gca;
        hax.FontName = 'Gill Sans MT';
        hax.FontSize = 12;
        saveas(gcf, [curTaskFigDir, filesep, ...
            'Histogram of ', strrep(chkTblVars{ihistVar}, '_', ' '), ...
            ' GRADE ', num2str(grades{igrade}), '.jpg']);
        close(gcf);
    end
end
agingDespStats = grpstats(tbl, 'grade', {'mean', 'std'}, 'DataVars', chkTblVars);
writetable(agingDespStats, [curTaskXlsDir, filesep, 'Descriptive statistics of each grade.xlsx']);

%% Error bar plot.
for ivsuff = 1:length(varSuff)
    figure
    curSuffVarNames = chkTblVars(~cellfun(@isempty, strfind(chkTblVars, varSuff{ivsuff})));
    axisPos = {'left', 'right'};
    title(['Error bar (SEM) plot of ', strrep(varSuff{ivsuff}, '_', ' '), ' in task ', taskIDName]);
    for ivar = 1:2
        yyaxis(axisPos{ivar})
        errorbar(grpstats(tbl.(curSuffVarNames{ivar}), tbl.grade), ...
            grpstats(tbl.(curSuffVarNames{ivar}), tbl.grade, 'sem'))
        xlabel('Grade')
        ebylabel = regexp(curSuffVarNames{ivar}, strjoin(varPref, '|'), 'match', 'once');
        if strcmp(ebylabel, 'MRT') || strcmp(ebylabel, 'RT')
            ebylabel = [ebylabel, '(ms)'];
        end
        ylabel(strrep(ebylabel, '_', ' '))
        hax = gca;
        hax.YGrid = 'on';
        hax.GridLineStyle = '-';
        hax.XTick = 1:length(grades);
        hax.XTickLabel = grades;
        hax.FontName = 'Gill Sans MT';
        hax.FontSize = 12;
        hold on
    end
    saveas(gcf, [curTaskFigDir, filesep, ...
        'Error bar (SEM) plot of ', strrep(varSuff{ivsuff}, '_', ' ')], 'jpg');
    close(gcf)
end
