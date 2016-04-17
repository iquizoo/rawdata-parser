function statsPlotBART(tbl)
%STATSPLOTBART Plots basic graphs of report.
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
chkVars = {'MNHit'};
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

%% Box plot and outliers.
outlierVarPref = {'MildOutlierCount_', 'ExtremeOutlierCount_'};
repOutlierVarSuff = repmat(chkVars, length(outlierVarPref), 1);
outlierVarSuff = repOutlierVarSuff(:)';
outlierVarnames = strcat(repmat(outlierVarPref, 1, length(chkVars)), outlierVarSuff);
curTaskOutlier = grpstats(tbl, 'grade', {@(x)coutlier(x, 'mild'), @(x)coutlier(x, 'extreme')}, ...
    'DataVars', chkTblVars, ...
    'VarNames', [{'grade', 'GroupCount'}, outlierVarnames]);
writetable(curTaskOutlier, [curTaskXlsDir, filesep, 'Counting of outliers of each grade.xlsx']);
figure
boxplot(chkData, tbl.grade, 'Whisker', 3);
xlabel('Grade')
[taskIDName, desp] = regexp(chkTblVars{:}, '^\w+?(?=_)', 'match', 'split', 'once');
title(['Box plot of', strrep(desp{2}, '_', ' '), ' in task ', taskIDName, ' through all grades'])
bpylabel = regexp(chkTblVars{:}, 'MRT', 'match', 'once');
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

%% Error bar plot.
%Remove extreme outliers.
for igrade = 1:length(grades)
    curgradeidx = tbl.grade == grades{igrade};
    [~, outlieridx] = coutlier(tbl.(VarsOfTaskData{1})(curgradeidx), 'extreme');
    rmidx = curgradeidx;
    rmidx(rmidx == 1) = outlieridx;
    tbl(rmidx, :) = [];
end
figure
title(['Error bar (SEM) plot of ', strrep(chkVars{:}, '_', ' '), ' in task ', taskIDName]);
errorbar(grpstats(tbl.(chkTblVars{:}), tbl.grade), ...
    grpstats(tbl.(chkTblVars{:}), tbl.grade, 'sem'))
xlabel('Grade')
ebylabel = regexp(chkTblVars{:}, 'Count|RT', 'match', 'once');
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
saveas(gcf, [curTaskFigDir, filesep, ...
    'Error bar (SEM) plot of ', strrep(chkVars{:}, '_', ' ')], 'jpg');
close(gcf)
