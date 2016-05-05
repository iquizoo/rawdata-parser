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
%       cfg.slidegen: logical/integer capable of converting to logical.
%       When true, generate slide markdown. Default: false.

%By Zhang, Liang. Email:psychelzh@gmail.com

%% Directory setting works.
%Folder contains all the analysis and plots functions.
anafunpath = 'analysis';
addpath(anafunpath);
%Add a folder to store all the results.
curCallFullname = mfilename('fullpath');
curDir = fileparts(curCallFullname);
resFolder = fullfile(fileparts(curDir), 'DATA_RES');
%% Settings processing in total.
%Read in the settings table.
settings = readtable('taskSettings.xlsx', 'Sheet', 'settings');
% Some transformation of meta information, e.g. school and grade.
allMrgDataVars = mrgdata.Properties.VariableNames;
taskVarsOfMetaDataOfInterest = {'userId', 'gender', 'school', 'grade'};
taskVarsOfExperimentData = allMrgDataVars(~ismember(allMrgDataVars, taskVarsOfMetaDataOfInterest));
taskMetaData = mrgdata(:, ismember(allMrgDataVars, taskVarsOfMetaDataOfInterest));
%% Checking inputs and parameters.
%Check input arguments.
if nargin <= 1
    tasks = [];
end
if nargin <= 2
    cfg = [];
end
%Check configuration.
cfg = chkconfig(cfg);
minsubs = cfg.minsubs;
outliermode = cfg.outliermode;
figfmt = cfg.figfmt;
slidegen = cfg.slidegen;
if isempty(tasks) %No task specified, then plots all the tasks specified in mrgdata.
    tasks = unique(regexp(taskVarsOfExperimentData, '^.*?(?=_)', 'match', 'once'));
end
%Use cellstr data type.
if ischar(tasks)
    tasks = {tasks};
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
%Rearrange tasks in the order of tasksettings.
allTaskIDName = unique(settings.TaskIDName, 'stable');
loc4process = ismember(allTaskIDName, tasks);
allTaskIDName(~loc4process) = [];
[~, newOrder] = ismember(allTaskIDName, tasks);
origtasks = origtasks(newOrder);
tasks = tasks(newOrder);
%% Initialization works before plotting.
ntasks = length(tasks);
fprintf('Will plot figures of %d tasks...\n', ntasks);
if slidegen
    %The pandoc slides markdown string generator and output file setting.
    fid = fopen('Beijing Brain Project.md', 'w', 'n', 'UTF-8');
    %Basic signs used in markdown.
    newline = '\r\n';
    Title = '%% Beijing Brain Project';
    Authors = '%% Zhang Liang; Peng Maomiao; Wu Xiaomeng';
    Date = ['%% ', date];
    %Use lastsection as the last section number.
    lastsection = 0;
end
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
    if ~lastexcept
        fprintf(repmat('\b', 1, length(latestsprint)))
    end
    %Get the ordinal string.
    ordStr = num2ord(itask);
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
    % Experiment data.
    curTaskLoc = ~cellfun(@isempty, ...
        regexp(allMrgDataVars, ['^', curTaskSettings.TaskIDName{:}, '(?=_)'], 'start', 'once'));
    if ~any(curTaskLoc)
        fprintf('No experiment data result found for current task. Aborting...\n')
        lastexcept = true;
        continue
    end
    curTaskMetaData = taskMetaData;
    curTaskVarsOfMetaData = curTaskMetaData.Properties.VariableNames;
    curTaskExpData = mrgdata(:, curTaskLoc);
    curTaskVarsOfExperimentData = curTaskExpData.Properties.VariableNames;
    curTaskData = [curTaskMetaData, curTaskExpData];
    curTaskVarsData = curTaskData.Properties.VariableNames;
    %Pre-plot data clean job.
    curTaskData(all(isnan(curTaskExpData{:, :}), 2), :) = [];
    curTaskData(isundefined(curTaskData.school) | isundefined(curTaskData.grade), :) = [];
    curTaskData.grade = removecats(curTaskData.grade);
    grades = cellstr(unique(curTaskData.grade));
    %% Set the store directories and file names of figures and excels.
    % Remove the existing items.
    curTaskResDir = fullfile(resFolder, curTaskIDName);
    if exist(curTaskResDir, 'dir')
        rmdir(curTaskResDir, 's')
    end
    % Excel file.
    xlsDir = 'Docs';
    curTaskXlsDir = fullfile(curTaskResDir, xlsDir);
    mkdir(curTaskXlsDir)
    % Figures.
    figDir = 'Figs';
    curTaskFigDir = fullfile(curTaskResDir, figDir);
    mkdir(curTaskFigDir)
    %% Write a table of meta data.
    despStats = grpstats(curTaskData, {'school', 'grade'}, 'numel', ...
        'DataVars', curTaskVarsOfExperimentData(1)); %Only for count use, no need for all variables.
    outDespStats = despStats(:, 1:3);
    outDespStats.Properties.VariableNames = {'School', 'Grade', 'Count'};
    writetable(outDespStats, fullfile(curTaskXlsDir, 'Counting of each school and grade.xlsx'));
    %Special issue: see if delete those data with too few subjects (less than 10).
    minorLoc = outDespStats.Count < minsubs;
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
            curTaskData(ismember(curTaskData.school, outDespStats.School(shadyEntryInd)) ...
                & ismember(curTaskData.grade, outDespStats.Grade(shadyEntryInd)), :) = [];
            curTaskData.grade = removecats(curTaskData.grade);
            grades = cellstr(unique(curTaskData.grade));
        end
    end
    %% Get metadata and expdata seperated again.
    curTaskMetaData = curTaskData(:, ismember(curTaskVarsData, curTaskVarsOfMetaData));
    curTaskExpData = curTaskData(:, ismember(curTaskVarsData, curTaskVarsOfExperimentData));
    %% Condition-wise plotting.
    curTaskMrgConds = strsplit(curTaskSettings.MergeCond{:});
    if all(cellfun(@isempty, curTaskMrgConds))
        curTaskDelimiterMC = '';
    else
        curTaskDelimiterMC = '_';
    end
    ncond = length(curTaskMrgConds);
    for icond = 1:ncond
        %% Outlier checking.
        curMrgCond = curTaskMrgConds{icond};
        %Update file storage directory.
        curCondTaskXlsDir = fullfile(curTaskXlsDir, curMrgCond);
        if ~exist(curCondTaskXlsDir, 'dir')
            mkdir(curCondTaskXlsDir)
        end
        curCondTaskFigDir = fullfile(curTaskFigDir, curMrgCond);
        if ~exist(curCondTaskFigDir, 'dir')
            mkdir(curCondTaskFigDir)
        end
        %Get the data of current condition.
        if isempty(curMrgCond)
            curCondTaskExpData = curTaskExpData;
        else
            curCondTaskExpData = curTaskExpData(:, ~cellfun(@isempty, ...
                cellfun(@(x) regexp(x, [curTaskDelimiterMC, curMrgCond, '$'], 'once'), ...
                curTaskVarsOfExperimentData, 'UniformOutput', false)));
            curCondTaskExpData.Properties.VariableNames = ...
                regexprep(curCondTaskExpData.Properties.VariableNames, [curTaskDelimiterMC, curMrgCond, '$'], '');
        end
        curCondTaskData = [curTaskMetaData, curCondTaskExpData];
        curCondTaskVarsOfExperimentData = curCondTaskExpData.Properties.VariableNames;
        chkVar = strcat(curTaskSettings.chkVar{:});
        % Output Excel.
        chkTblVar = strcat(curTaskIDName, '_', chkVar);
        chkOutlierOutVars = 'Outliers';
        curTaskOutlier = grpstats(curCondTaskData, 'grade', @(x)coutlier(x, outliermode), ...
            'DataVars', chkTblVar, ...
            'VarNames', {'Grade', 'Total', chkOutlierOutVars});
        writetable(curTaskOutlier, ...
            fullfile(curCondTaskXlsDir, 'Counting of outliers of each grade.xlsx'));
        % Output boxplot figure.
        hbp = figure;
        hbp.Visible = 'off';
        whisker = 1.5 * strcmp(outliermode, 'mild') + 3 * strcmp(outliermode, 'extreme');
        bpsngtask(curCondTaskData, curTaskIDName, chkVar, whisker)
        bpname = fullfile(curCondTaskFigDir, ...
            ['Box plot of ', strrep(chkVar, '_', ' '), ' through all grades']);
        saveas(hbp, bpname, figfmt)
        delete(hbp)
        %Remove outliers and plot histograms.
        for igrade = 1:length(grades)
            curgradeidx = curCondTaskData.grade == grades{igrade};
            [~, outlieridx] = coutlier(curCondTaskData.(chkTblVar)(curgradeidx), 'extreme');
            curgradeidx(curgradeidx == 1) = outlieridx;
            curCondTaskData(curgradeidx, :) = [];
        end
        [hs, hnames] =  histsngtask(curCondTaskData, curTaskIDName);
        cellfun(@(x, y) saveas(x, y, figfmt), ...
            num2cell(hs), cellstr(fullfile(curCondTaskFigDir, hnames)))
        delete(hs)
        %% Write a table about descriptive statistics of different ages.
        agingDespStats = grpstats(curCondTaskData, 'grade', {'mean', 'std'}, ...
            'DataVars', curCondTaskVarsOfExperimentData);
        writetable(agingDespStats, ...
            fullfile(curCondTaskXlsDir, 'Descriptive statistics of each grade.xlsx'));
        %% Errorbar plots.
        %Errorbar plot CP.
        cmbTasks = {'AssocMemory', 'SemanticMemory'};
        if ismember(curTaskIDName, cmbTasks)
            ebplotfun = @ebsngtaskcmb;
        else
            ebplotfun = @ebsngtaskmult;
        end
        curTaskChkVarsCat = strsplit(curTaskSettings.VarsCat{:});
        curTaskChkVarsCond = strsplit(curTaskSettings.VarsCond{:});
        if all(cellfun(@isempty, curTaskChkVarsCond))
            curTaskDelimiter = '';
        else
            curTaskDelimiter = '_';
        end
        [hs, hnames] = ebplotfun(curCondTaskData, curTaskIDName, curTaskChkVarsCat, curTaskDelimiter, curTaskChkVarsCond);
        cellfun(@(x, y) saveas(x, y, figfmt), ...
            num2cell(hs), cellstr(fullfile(curCondTaskFigDir, hnames)))
        delete(hs)
        %Error bar plot of singleton variables.
        curTaskSngVars = strsplit(curTaskSettings.SingletonVars{:});
        if ~all(cellfun(@isempty, curTaskSngVars))
            [hs, hnames] = ebsngtasksingleton(curCondTaskData, curTaskIDName, curTaskSngVars);
            cellfun(@(x, y) saveas(x, y, figfmt), ...
                num2cell(hs), cellstr(fullfile(curCondTaskFigDir, hnames)))
            delete(hs)
        end
        %Error bar plot of singleton variables CP.
        curTaskSngVarsCP = strsplit(curTaskSettings.SingletonVarsCP{:});
        if ~all(cellfun(@isempty, curTaskSngVarsCP))
            [hs, hnames] = ebsngtaskmult(curCondTaskData, curTaskIDName, curTaskSngVarsCP);
            cellfun(@(x, y) saveas(x, y, figfmt), ...
                num2cell(hs), cellstr(fullfile(curCondTaskFigDir, hnames)))
            delete(hs)
        end
    end
    clearvars('-except', initialVars{:});
end
if slidegen
    slidesMarkdown = strjoin({Title, Authors, Date, }, newline);
    fprintf(fid, slidesMarkdown);
    fclose(fid);
end
rmpath(anafunpath);

function cfg = chkconfig(cfg)
%CHKCONFIG converts cfg into the standard configuration.

fields = {'minsubs' 'outliermode' 'figfmt' 'slidegen'};
dflts  = {     20     'extreme'    'jpeg'     false  };
for ifield = 1:length(fields)
    curfield = fields{ifield};
    if ~isfield(cfg, curfield) || isempty(cfg.(curfield))
        cfg.(curfield) = dflts{ifield};
    end
end
