function Plots(mrgdata, tasks, cfg)
%PLOTS does a batch job of plot all the figures.
%   PLOTS(MRGDATA) plots all the figures specified in mrgdata,
%   based on 'extreme' outlier mode, and output 'jpeg' formatted figures.
%
%   PLOTS(MRGDATA, TASKS) does job only on the specified tasks,
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

%Basic signs used in markdown.
global newline secpre subsecpre slidepre
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
taskVarsOfMetaData = {'userId', 'gender', 'school', 'grade'};
taskVarsOfExperimentData = allMrgDataVars(~ismember(allMrgDataVars, taskVarsOfMetaData));
taskMetaData = mrgdata(:, ismember(allMrgDataVars, taskVarsOfMetaData));
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
    secpre = '#';
    subsecpre = '##';
    slidepre = '###';
    %Meta data.
    Title = strconv('% Beijing Brain Project');
    Authors = strconv('% Zhang Liang; Peng Maomiao; Wu Xiaomeng');
    Date = strconv(['% ', date]);
    metadata = strjoin({Title, Authors, Date}, newline);
    %Set section maps.
    [~, usedTaskLoc] = ismember(tasks, settings.TaskIDName);
    sectionNumers = settings.SlideSection(usedTaskLoc);
    sectionNumerMap = containers.Map(tasks, sectionNumers);
    sectionNames = settings.SectionSummary(usedTaskLoc);
    sectionNameMap = containers.Map(tasks, sectionNames);
    nsections = length(unique(sectionNumers));
    SectionTitles = cell(1, nsections);
    SectionData = cell(1, nsections);
    %Use lastsection as the last section number.
    lastSection = 0;
    partOrder = 0;
end
%Use lastexcept as an indicator of exception in last task.
lastExcept = false;
latestPrint = '';
%Task-wise checking.
for itask = 1:ntasks
    initialVars = who;
    close all
    curTaskIDName = tasks{itask};
    origTaskName = origtasks{itask};
    %Delete last line without exception.
    if ~lastExcept
        fprintf(repmat('\b', 1, length(latestPrint)))
    end
    %Get the ordinal string.
    ordStr = num2ord(itask);
    latestPrint = sprintf('Now plot figures of the %s task %s(%s).\n', ordStr, origTaskName, curTaskIDName);
    fprintf(latestPrint);
    lastExcept = false;
    curTaskSettings = settings(strcmp(settings.TaskIDName, curTaskIDName), :);
    if isempty(curTaskSettings)
        fprintf('No tasksetting found when processing task %s, aborting!\n', origTaskName);
        lastExcept = true;
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
        lastExcept = true;
        continue
    end
    curTaskMetaData = taskMetaData;
    curTaskVarsOfMetaData = curTaskMetaData.Properties.VariableNames;
    curTaskExpData = mrgdata(:, curTaskLoc);
    curTaskVarsOfExperimentData = curTaskExpData.Properties.VariableNames;
    %Pre-plot data clean job.
    curTaskMissingMetadataRow = isundefined(curTaskMetaData.school) | isundefined(curTaskMetaData.grade);
    curTaskMissingExpDataRows = all(isnan(curTaskExpData{:, :}), 2);
    curTaskMetaData(curTaskMissingMetadataRow | curTaskMissingExpDataRows, :) = [];
    curTaskExpData(curTaskMissingMetadataRow | curTaskMissingExpDataRows, :) = [];
    curTaskMetaData.grade = removecats(curTaskMetaData.grade);
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
    %% Create section titles.
    if slidegen
        curSectionNum = sectionNumerMap(curTaskIDName);
        curSectionName = sectionNameMap(curTaskIDName);
        curSectionOrder = find(sectionNumers, curSectionNum);
        if curSectionNum ~= lastSection
            partOrder = partOrder + 1;
            SectionTitles{curSectionOrder} = [secpre, ' Part ', num2str(partOrder), ' ', curSectionName];
            lastSection = curSectionNum;
        end
    end
    %% Write a table of meta data.
    curTaskVarsOfMetaDataOfInterest = {'school', 'grade'};
    curTaskMetaDataOfInterest = curTaskMetaData(:, ismember(curTaskVarsOfMetaData, curTaskVarsOfMetaDataOfInterest));
    despStats = grpstats(curTaskMetaDataOfInterest, {'school', 'grade'}, 'numel');
    despStats.Properties.VariableNames = {'School', 'Grade', 'Count'};
    writetable(despStats, fullfile(curTaskXlsDir, 'Counting of each school and grade.xlsx'));
    %Special issue: see if delete those data with too few subjects (less than 10).
    minorLoc = despStats.Count < minsubs;
    shadyEntryInd = find(minorLoc);
    if ~isempty(shadyEntryInd)
        lastExcept = true;
        fprintf('Entry with too few subjects encountered, will delete following entries in the displayed data table:\n')
        disp(despStats(shadyEntryInd, :))
        disp(despStats)
        resp = input('Sure to delete?[Y]/N:', 's');
        if isempty(resp)
            resp = 'yes';
        end
        if strcmpi(resp, 'y') || strcmpi(resp, 'yes')
            curTaskMinorRowRemoved = ismember(curTaskMetaData.school, despStats.School(shadyEntryInd)) ...
                & ismember(curTaskMetaData.grade, despStats.Grade(shadyEntryInd));
            curTaskMetaData(curTaskMinorRowRemoved, :) = [];
            curTaskMetaData.grade = removecats(curTaskMetaData.grade);
            curTaskExpData(curTaskMinorRowRemoved, :) = [];
        end
    end
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
        sngplotbox(curCondTaskData, curTaskIDName, chkVar, whisker)
        bpname = fullfile(curCondTaskFigDir, ...
            ['Box plot of ', strrep(chkVar, '_', ' '), ' through all grades']);
        saveas(hbp, bpname, figfmt)
        delete(hbp)
        if slidegen
            bpSlideTitle = strjoin({[subsecpre, curTaskIDName], ...
                [slidepre, 'Box plot to show outliers based on ', var2caption(curTaskIDName, chkVar)]}, ...
                newline);
            figfullpath = [bpname, '.', figfmt];
            caption = ['Box plot of ' var2caption(curTaskIDName, chkVar)];
            bpSlideContent = putimage(figfullpath, caption);
            SectionData{curSectionOrder} = [SectionData{curSectionOrder}, strjoin({bpSlideTitle, bpSlideContent}, newline)];
        end
        %Remove outliers and plot histograms.
        grades = cellstr(unique(curTaskMetaData.grade));
        for igrade = 1:length(grades)
            curgradeidx = curCondTaskData.grade == grades{igrade};
            [~, outlieridx] = coutlier(curCondTaskData.(chkTblVar)(curgradeidx), 'extreme');
            curgradeidx(curgradeidx == 1) = outlieridx;
            curCondTaskData(curgradeidx, :) = [];
        end
        [hs, hnames] =  sngplothist(curCondTaskData, curTaskIDName);
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
            ebplotfun = @sngplotebcmb;
        else
            ebplotfun = @sngplotebmult;
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
            [hs, hnames] = sngplotebsingleton(curCondTaskData, curTaskIDName, curTaskSngVars);
            cellfun(@(x, y) saveas(x, y, figfmt), ...
                num2cell(hs), cellstr(fullfile(curCondTaskFigDir, hnames)))
            delete(hs)
        end
        %Error bar plot of singleton variables CP.
        curTaskSngVarsCP = strsplit(curTaskSettings.SingletonVarsCP{:});
        if ~all(cellfun(@isempty, curTaskSngVarsCP))
            [hs, hnames] = sngplotebmult(curCondTaskData, curTaskIDName, curTaskSngVarsCP);
            cellfun(@(x, y) saveas(x, y, figfmt), ...
                num2cell(hs), cellstr(fullfile(curCondTaskFigDir, hnames)))
            delete(hs)
        end
        %Error bar plot of special variables.
        curTaskSpVars = strsplit(curTaskSettings.SpecialVars{:});
        if ~all(cellfun(@isempty, curTaskSpVars))
            [hs, hnames] = sngplotebmult(curCondTaskData, curTaskIDName, curTaskSpVars);
            cellfun(@(x, y) saveas(x, y, figfmt), ...
                num2cell(hs), cellstr(fullfile(curCondTaskFigDir, hnames)))
            delete(hs)
        end
    end
    clearvars('-except', initialVars{:});
end
if slidegen
    slidesdata = strjoin([SectionTitles, SectionData], newline);
    slidesMarkdown = strjoin({metadata, slidesdata}, newline);
    fprintf(fid, slidesMarkdown);
    fclose(fid);
end
rmpath(anafunpath);
end

function cfg = chkconfig(cfg)
%CHKCONFIG converts cfg into the standard configuration.

fields = {'minsubs' 'outliermode' 'figfmt' 'slidegen'};
dflts  = {     20     'extreme'    'jpg'     false  };
for ifield = 1:length(fields)
    curfield = fields{ifield};
    if ~isfield(cfg, curfield) || isempty(cfg.(curfield))
        cfg.(curfield) = dflts{ifield};
    end
end
end

function emstr = emphasis(str, flank)
%EMPHASIS generates pandoc bold string.

emstr = strcat(flank, str, flank);
end

function imstr = putimage(figpath, caption)
%PUTIMAGE generates a string of pandoc code to put image onto slide.

global newline
figpath = strconv(figpath);
%two newlines are added posterior.
imstr = ['![' caption '](' figpath ')' newline];
end

function converted = strconv(origstr)
%TRANSLATE removes wrongly placed escape characters.

orig = {'\', '%'};
trans = {'\\', '%%'};
converted = origstr;
for itrans = 1:length(orig)
    converted = strrep(converted, orig{itrans}, trans{itrans});
end
end
