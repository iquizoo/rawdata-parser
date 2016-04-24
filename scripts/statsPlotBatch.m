function statsPlotBatch(mrgdata, tasks, mode)
%STATSPLOTBATCH does a batch job of plot all the figures.
%   STATSPLOTBATCH(MRGDATA) plots all the figures specified in mrgdata,
%   based on 'extreme' outlier mode.
%
%   STATSPLOTBATCH(MRGDATA, TASKS) does job only on the specified tasks,
%   also based on 'extreme' outlier mode.
%
%   STATSPLOTBATCH(MRGDATA, TASKS, MODE) does job only on the specified
%   tasks, and outliers selection is user defined.

%By Zhang, Liang. Email:psychelzh@gmail.com

%Folder contains all the analysis and plots functions.
anafunpath = 'analysis';
addpath(anafunpath);
%Read in the settings table.
settings = readtable('taskSettings.xlsx', 'Sheet', 'settings');
%Check input arguments.
if nargin <= 2
    mode = 'extreme';
end
if nargin <= 1
    tasks = settings.TaskIDName;
end
%Use cellstr data type.
if ischar(tasks)
    tasks = {tasks};
end
if isempty(tasks) %No task specified, then plots all the tasks.
    tasks = settings.TaskIDName;
end
locNotFound = ~ismember(tasks, settings.TaskName) & ~ismember(tasks, settings.TaskIDName);
%Remove tasks that do not exist.
if any(locNotFound)
    fprintf('Oops! These tasks are not found currently. Will delete these tasks in processing.\n');
    disp(tasks(locNotFound))
    tasks(locNotFound) = [];
end
%Check if the input task names are TaskIDName.
encodeSetNum = cellfun(@double, tasks, 'UniformOutput', false);
encodeSetLoc = cellfun(@gt, ...
    encodeSetNum, num2cell(repmat(double('z'), size(encodeSetNum))), ...
    'UniformOutput', false);
isTaskIDName = cellfun(@all, cellfun(@not, encodeSetLoc, 'UniformOutput', false));
%Change TaskNames to TaskIDNames.
origtasks = tasks;
tasksNeedTrans = tasks(~isTaskIDName);
[~, locTaskName] = ismember(tasksNeedTrans, settings.TaskName);
tasks(~isTaskIDName) = settings.TaskIDName(locTaskName);
ntasks = length(tasks);
fprintf('Will plot figures of %d tasks...\n', ntasks);
%Task-wise checking.
for itask = 1:ntasks
    initialVars = who;
    curTaskIDName = tasks{itask};
    origTaskName = origtasks{itask};
    fprintf('Now plot figures of task %s(%s).\n', origTaskName, curTaskIDName);
    curTaskSettings = settings(strcmp(settings.TaskIDName, curTaskIDName), :);
    if isempty(curTaskSettings)
        fprintf('Exception encountered when processing task %s, aborting!\n', origTaskName);
        continue
    elseif height(curTaskSettings) > 1
        curTaskSettings = curTaskSettings(1, :);
    end
    %% Set the store directories and file names of figures and excels.
    % Excel file.
    xlsDir = 'Docs';
    curTaskXlsDir = fullfile(curTaskIDName, xlsDir);
    if ~exist(curTaskXlsDir, 'dir')
        mkdir(curTaskXlsDir)
    end
    % Figures.
    figDir = 'Figs';
    curTaskFigDir = fullfile(curTaskIDName, figDir);
    if ~exist(curTaskFigDir, 'dir')
        mkdir(curTaskFigDir)
    end
    %% Get the data of current task.
    allMrgDataVars = mrgdata.Properties.VariableNames;
    % Some transformation of basic information, e.g. school and grade.
    curTaskVarsOfBasicInformation = {'userId', 'gender', 'school', 'grade'};
    curTaskDataBI = mrgdata(:, ismember(allMrgDataVars, curTaskVarsOfBasicInformation));
    % Experiment data.
    curTaskLoc = ~cellfun(@isempty, ...
        regexp(allMrgDataVars, ['^', curTaskSettings.TaskIDName{:}, '(?=_)'], 'start', 'once'));
    curTaskDataExp = mrgdata(:, curTaskLoc);
    curTaskVarsOfExperimentData = curTaskDataExp.Properties.VariableNames;
    curTaskData = [curTaskDataBI, curTaskDataExp];
    %Pre-plot data clean job.
    curTaskData(all(isnan(curTaskDataExp{:, :}), 2), :) = [];
    curTaskData(isundefined(curTaskData.school) | isundefined(curTaskData.grade), :) = [];
    curTaskData.grade = removecats(curTaskData.grade);
    grades = cellstr(unique(curTaskData.grade));
    %% Write a table of basic information statistics.
    despStats = grpstats(curTaskData, {'school', 'grade'}, 'numel', ...
        'DataVars', curTaskVarsOfExperimentData(1)); %Only for count use, no need for all variables.
    outDespStats = despStats(:, 1:3);
    writetable(outDespStats, [curTaskXlsDir, filesep, 'Counting of each school and grade.xlsx']);
    %% Outlier checking.
    chkVar = curTaskSettings.chkVar{:};
    % Output Excel.
    chkTblVar = strcat(curTaskIDName, '_', chkVar);
    chkOutlierOutVars = ['ExtremeOutlierCount_', chkVar];
    curTaskOutlier = grpstats(curTaskData, 'grade', @(x)coutlier(x, mode), ...
        'DataVars', chkTblVar, ...
        'VarNames', {'Grade', 'Total', chkOutlierOutVars});
    writetable(curTaskOutlier, fullfile(curTaskXlsDir, 'Counting of outliers of each grade.xlsx'));
    % Output boxplot figure.
    hbp = figure;
    hbp.Visible = 'off';
    whisker = 1.5 * strcmp(mode, 'mild') + 3 * strcmp(mode, 'extreme');
    bpsngtask(curTaskData, curTaskIDName, chkVar, whisker)
    bpname = fullfile(curTaskFigDir, ...
        ['Box plot of ', strrep(chkVar, '_', ' '), ' through all grades.png']);
    saveas(hbp, bpname)
    delete(hbp)
    %Remove outliers and plot histograms.
    for igrade = 1:length(grades)
        curgradeidx = curTaskData.grade == grades{igrade};
        [~, outlieridx] = coutlier(curTaskData.(chkTblVar)(curgradeidx), 'extreme');
        curgradeidx(curgradeidx == 1) = outlieridx;
        curTaskData(curgradeidx, :) = [];
    end
    [hs, hnames] =  histsngtask(curTaskData, curTaskIDName);
    cellfun(@saveas, num2cell(hs), fullfile(curTaskFigDir, hnames))
    delete(hs)
    %% Write a table about descriptive statistics of different ages.
    agingDespStats = grpstats(curTaskData, 'grade', {'mean', 'std'}, ...
        'DataVars', curTaskVarsOfExperimentData);
    writetable(agingDespStats, fullfile(curTaskXlsDir, 'Descriptive statistics of each grade.xlsx'));
    %% Errorbar plots.
    %Errorbar plot CP.
    cmbTasks = {'AssocMemory', 'SemanticMemory'};
    if ismember(curTaskIDName, cmbTasks)
        ebplotfun = @ebsngtaskcmb;
    else
        ebplotfun = @ebsngtaskmult;
    end
    curTaskChkVarsCat = strsplit(curTaskSettings.chkVarsCat{:});
    curTaskChkVarsCond = strsplit(curTaskSettings.chkVarsCond{:});
    if all(cellfun(@isempty, curTaskChkVarsCond))
        curTaskDelimiter = '';
    else
        curTaskDelimiter = '_';
    end
    [hs, hnames] = ebplotfun(curTaskData, curTaskIDName, curTaskChkVarsCat, curTaskDelimiter, curTaskChkVarsCond);
    cellfun(@saveas, num2cell(hs), fullfile(curTaskFigDir, hnames))
    delete(hs)
    %Error bar plot of singleton variables.
    curTaskSngVars = strsplit(curTaskSettings.SingletonVars{:});
    if ~all(cellfun(@isempty, curTaskSngVars))
        [hs, hnames] = ebsngtasksingleton(curTaskData, curTaskIDName, curTaskSngVars);
        cellfun(@saveas, num2cell(hs), fullfile(curTaskFigDir, hnames))
        delete(hs)
    end
    %Error bar plot of singleton variables CP.
    curTaskSngVarsCP = strsplit(curTaskSettings.SingletonVarsCP{:});
    if ~all(cellfun(@isempty, curTaskSngVarsCP))
        [hs, hnames] = ebsngtaskmult(curTaskData, curTaskIDName, curTaskSngVarsCP);
        cellfun(@saveas, num2cell(hs), fullfile(curTaskFigDir, hnames))
        delete(hs)
    end
    clearvars('-except', initialVars{:});
end
rmpath(anafunpath);
