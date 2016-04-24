function statsPlotBatch(mrgdata, tasks, cfg)
%STATSPLOTBATCH does a batch job of plot all the figures.
%   STATSPLOTBATCH(MRGDATA) plots all the figures specified in mrgdata,
%   based on 'extreme' outlier mode, and output 'jpeg' formatted figures.
%
%   STATSPLOTBATCH(MRGDATA, TASKS) does job only on the specified tasks,
%   also based on 'extreme' outlier mode, and output 'jpeg' formatted
%   figures.
%
%   CFG is a structure used to specify the following information.
%       cfg.minsubs:  One numeric data, means the minimum subjects number
%       of each entry (one grade in a school). Default: 20.
%       cfg.outliermode: String. Either 'extreme' or 'mild'. Default:
%       'extreme'.
%       cfg.figfmt: String. One supported figure format. See help saveas.
%       Default: 'jpeg'.

%By Zhang, Liang. Email:psychelzh@gmail.com

%Folder contains all the analysis and plots functions.
anafunpath = 'analysis';
addpath(anafunpath);
%Add a folder to store all the results.
curCallFullname = mfilename('fullpath');
curDir = fileparts(curCallFullname);
resFolder = fullfile(fileparts(curDir), 'DATA_RES');
%Read in the settings table.
settings = readtable('taskSettings.xlsx', 'Sheet', 'settings');
%Check input arguments.
if nargin <= 1
    tasks = unique(settings.TaskIDName, 'stable');
end
if nargin <= 2
    cfg = [];
end
%Check configuration.
if ~isfield(cfg, 'minsubs') || isempty(cfg.minsubs)
    cfg.minsubs = 20;
end
if ~isfield(cfg, 'outliermode') || isempty(cfg.outliermode)
    cfg.outliermode = 'extreme';
end
if ~isfield(cfg, 'figfmt') || isempty(cfg.figfmt)
    cfg.figfmt = 'jpeg';
end
minsubs = cfg.minsubs;
outliermode = cfg.outliermode;
figfmt = cfg.figfmt;
%Use cellstr data type.
if ischar(tasks)
    tasks = {tasks};
end
if isempty(tasks) %No task specified, then plots all the tasks.
    tasks = unique(settings.TaskIDName, 'stable');
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
%Use lastexcept as an indicator of exception in last task.
lastexcept = false;
latestsprint = '';
%Task-wise checking.
for itask = 1:ntasks
    initialVars = who;
    close all
    curTaskIDName = tasks{itask};
    origTaskName = origtasks{itask};
    %Delete last line without exception.
    if ~lastexcept && itask ~= 1
        fprintf(repmat('\b', 1, length(latestsprint)))
    end
    %Get the ordinal string.
    ordStr = [num2str(itask), 'th'];
    ordStr = strrep(ordStr, '1th', '1st');
    ordStr = strrep(ordStr, '2th', '2nd');
    ordStr = strrep(ordStr, '3th', '3rd');
    latestsprint = sprintf('Now plot figures of the %s task %s(%s).\n', ordStr, origTaskName, curTaskIDName);
    fprintf(latestsprint);
    lastexcept = false;
    curTaskSettings = settings(strcmp(settings.TaskIDName, curTaskIDName), :);
    if isempty(curTaskSettings)
        fprintf('No tasksetting found when processing task %s, aborting!\n', origTaskName);
        lastexcept = true;
        continue
    elseif height(curTaskSettings) > 1
        curTaskSettings = curTaskSettings(1, :);
    end
    %% Get the data of current task.
    allMrgDataVars = mrgdata.Properties.VariableNames;
    % Some transformation of basic information, e.g. school and grade.
    curTaskVarsOfBasicInformation = {'userId', 'gender', 'school', 'grade'};
    curTaskDataBI = mrgdata(:, ismember(allMrgDataVars, curTaskVarsOfBasicInformation));
    % Experiment data.
    curTaskLoc = ~cellfun(@isempty, ...
        regexp(allMrgDataVars, ['^', curTaskSettings.TaskIDName{:}, '(?=_)'], 'start', 'once'));
    if ~any(curTaskLoc)
        fprintf('No experiment data result found for current task. Aborting...\n')
        lastexcept = true;
        continue
    end
    curTaskDataExp = mrgdata(:, curTaskLoc);
    curTaskVarsOfExperimentData = curTaskDataExp.Properties.VariableNames;
    curTaskData = [curTaskDataBI, curTaskDataExp];
    %Pre-plot data clean job.
    curTaskData(all(isnan(curTaskDataExp{:, :}), 2), :) = [];
    curTaskData(isundefined(curTaskData.school) | isundefined(curTaskData.grade), :) = [];
    curTaskData.grade = removecats(curTaskData.grade);
    grades = cellstr(unique(curTaskData.grade));
    %% Set the store directories and file names of figures and excels.
    % Excel file.
    xlsDir = 'Docs';
    curTaskXlsDir = fullfile(resFolder, curTaskIDName, xlsDir);
    if ~exist(curTaskXlsDir, 'dir')
        mkdir(curTaskXlsDir)
    end
    % Figures.
    figDir = 'Figs';
    curTaskFigDir = fullfile(resFolder, curTaskIDName, figDir);
    if ~exist(curTaskFigDir, 'dir')
        mkdir(curTaskFigDir)
    end
    %% Write a table of basic information statistics.
    despStats = grpstats(curTaskData, {'school', 'grade'}, 'numel', ...
        'DataVars', curTaskVarsOfExperimentData(1)); %Only for count use, no need for all variables.
    outDespStats = despStats(:, 1:3);
    writetable(outDespStats, fullfile(curTaskXlsDir, 'Counting of each school and grade.xlsx'));
    %Special issue: see if delete those data with too few subjects (less than 10).
    minorLoc = outDespStats.GroupCount < minsubs;
    shadyEntryInd = find(minorLoc);
    if ~isempty(shadyEntryInd)
        lastexcept = true;
        fprintf('Entry with too few subjects encountered, will delete following entries in the displayed data table:\n')
        disp(outDespStats(shadyEntryInd, :))
        disp(outDespStats)
        resp = input('Sure to delete?[Y]/N:', 's');
        if isempty(resp)
            resp = 'yes';
        end
        if strcmpi(resp, 'y') || strcmpi(resp, 'yes')
            curTaskData(ismember(curTaskData.school, outDespStats.school(shadyEntryInd)) ...
                & ismember(curTaskData.grade, outDespStats.grade(shadyEntryInd)), :) = [];
            curTaskData.grade = removecats(curTaskData.grade);
            grades = cellstr(unique(curTaskData.grade));
        end
    end
    %% Outlier checking.
    chkVar = curTaskSettings.chkVar{:};
    % Output Excel.
    chkTblVar = strcat(curTaskIDName, '_', chkVar);
    chkOutlierOutVars = ['ExtremeOutlierCount_', chkVar];
    curTaskOutlier = grpstats(curTaskData, 'grade', @(x)coutlier(x, outliermode), ...
        'DataVars', chkTblVar, ...
        'VarNames', {'Grade', 'Total', chkOutlierOutVars});
    writetable(curTaskOutlier, fullfile(curTaskXlsDir, 'Counting of outliers of each grade.xlsx'));
    % Output boxplot figure.
    hbp = figure;
    hbp.Visible = 'off';
    whisker = 1.5 * strcmp(outliermode, 'mild') + 3 * strcmp(outliermode, 'extreme');
    bpsngtask(curTaskData, curTaskIDName, chkVar, whisker)
    bpname = fullfile(curTaskFigDir, ...
        ['Box plot of ', strrep(chkVar, '_', ' '), ' through all grades']);
    saveas(hbp, bpname, figfmt)
    delete(hbp)
    %Remove outliers and plot histograms.
    for igrade = 1:length(grades)
        curgradeidx = curTaskData.grade == grades{igrade};
        [~, outlieridx] = coutlier(curTaskData.(chkTblVar)(curgradeidx), 'extreme');
        curgradeidx(curgradeidx == 1) = outlieridx;
        curTaskData(curgradeidx, :) = [];
    end
    [hs, hnames] =  histsngtask(curTaskData, curTaskIDName);
    cellfun(@saveas, num2cell(hs), cellstr(fullfile(curTaskFigDir, hnames)), repmat({figfmt}, size(hs)))
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
    cellfun(@saveas, num2cell(hs), cellstr(fullfile(curTaskFigDir, hnames)), repmat({figfmt}, size(hs)))
    delete(hs)
    %Error bar plot of singleton variables.
    curTaskSngVars = strsplit(curTaskSettings.SingletonVars{:});
    if ~all(cellfun(@isempty, curTaskSngVars))
        [hs, hnames] = ebsngtasksingleton(curTaskData, curTaskIDName, curTaskSngVars);
        cellfun(@saveas, num2cell(hs), cellstr(fullfile(curTaskFigDir, hnames)), repmat({figfmt}, size(hs)))
        delete(hs)
    end
    %Error bar plot of singleton variables CP.
    curTaskSngVarsCP = strsplit(curTaskSettings.SingletonVarsCP{:});
    if ~all(cellfun(@isempty, curTaskSngVarsCP))
        [hs, hnames] = ebsngtaskmult(curTaskData, curTaskIDName, curTaskSngVarsCP);
        cellfun(@saveas, num2cell(hs), cellstr(fullfile(curTaskFigDir, hnames)))
        delete(hs)
    end
    clearvars('-except', initialVars{:});
end
rmpath(anafunpath);
