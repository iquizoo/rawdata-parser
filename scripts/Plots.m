function timeinfo = Plots(mrgdata, tasks, cfg)
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
global newline slidepre
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
figfmtext = readtable('taskSettings.xlsx', 'Sheet', 'fmtext');
figfmtextmap = containers.Map(figfmtext.fmt, figfmtext.ext);
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
cfg         = chkconfig(cfg);
cfg.ext     = figfmtextmap(cfg.figfmt);
outliermode = cfg.outliermode;
if isempty(tasks) %No task specified, then plots all the tasks specified in mrgdata.
    tasks = unique(regexp(taskVarsOfExperimentData, '^.*?(?=_)', 'match', 'once'));
end
%Use cellstr data type.
tasks = cellstr(tasks);
if isrow(tasks), tasks = tasks'; end
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
%Set section maps.
[~, usedTaskLoc]  = ismember(tasks, settings.TaskIDName);
sectionNumers     = settings.SlideSection(usedTaskLoc);
sectionNames      = settings.SectionSummary(usedTaskLoc);
uniSectionNumbers = unique(sectionNumers, 'stable');
uniSectionNames   = unique(sectionNames, 'stable');
nsections         = length(uniSectionNumbers);
%Display information of begin processing.
ntasks = length(tasks);
fprintf('Will plot figures of %d tasks...\n', ntasks);
%Use a waitbar to tell the processing information.
hwb = waitbar(0, 'Begin plotting figures of the tasks specified by users...Please wait...', ...
    'Name', 'Plotting merged data of CCDPro',...
    'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
setappdata(hwb, 'canceling', 0)
nprocessed = 0;
nignored = 0;
plottime = cellstr(repmat('TBE', ntasks, 1));
timeinfo =  table;
timeinfo.TaskIDName = tasks;
timeinfo.Time2Plot  = plottime;
%The pandoc slides markdown string generator and output file setting.
fid = fopen('Beijing Brain Project.pmd', 'w', 'n', 'UTF-8');
%Basic signs used in markdown.
newline   = '\r\n';
secpre    = '#';
subsecpre = '##';
slidepre  = '###';
%Meta data.
Title    = strconv('% Beijing Brain Project');
Authors  = strconv('% Zhang Liang; Peng Maomiao; Wu Xiaomeng');
Date     = strconv(['% ', date]);
metadata = strjoin({Title, Authors, Date}, newline);
%Initiate section data.
SectionTitles    = repmat(cellstr(''), 1, nsections);
SectionSlideData = repmat(cellstr(''), 1, nsections);
%% Plotting.
%Section-wise checking.
for isec = 1:nsections
    initialVarsSec = who;
    tic
    %Set section titles.
    curSecNum = uniSectionNumbers(isec);
    curSecName = uniSectionNames{isec};
    SectionTitles{isec} = sprintf('%s Part %d %s', secpre, curSecNum, curSecName);
    %Task-wise checking.
    curSecTasks = tasks(sectionNumers == curSecNum);
    curSecOrigTasks = origtasks(sectionNumers == curSecNum);
    ncursectasks = length(curSecTasks);
    curSectionSlideData = repmat(cellstr(''), 1, ncursectasks);
    for itask = 1:ncursectasks
        initialVarsTask = who;
        % Check for Cancel button press
        if getappdata(hwb, 'canceling')
            fprintf('%d plotting task(s) completed this time. User canceled...\n', nprocessed);
            break
        end
        curTaskIDName = curSecTasks{itask};
        cfg.task = curTaskIDName;
        origTaskName = curSecOrigTasks{itask};
        %For each task, there are following part.
        %   metadata bar3, outliers boxplot of each condition, development
        %   errorbar of each condition (main), histograms.
        curTaskSlideData = sprintf('%s %s', subsecpre, curTaskIDName);
        %% Update waitbar.
        %Get the proportion of completion and the estimated time of arrival.
        completePercent = nprocessed / (ntasks - nignored);
        if itask == 1 && isec == 1
            msgSuff = 'Please wait...';
            elapsedTime = 0;
        else
            elapsedTime = toc;
            eta = seconds2human(elapsedTime * (1 - completePercent) / completePercent, 'full');
            msgSuff = strcat('TimeRem:', eta);
        end
        %Update message in the waitbar.
        msg = sprintf('Task: %s. %s', curTaskIDName, msgSuff);
        waitbar(completePercent, hwb, msg);
        %Unpdate processed tasks number.
        nprocessed = nprocessed + 1;
        %% Get the settings of current task.
        curTaskSettings = settings(strcmp(settings.TaskIDName, curTaskIDName), :);
        if isempty(curTaskSettings)
            fprintf('No tasksetting found when processing task %s, aborting!\n', origTaskName);
            nignored = nignored + 1;
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
            nignored = nignored + 1;
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
        curTaskMetaData.grade = removecats(curTaskMetaData.grade);
        curTaskExpData(curTaskMissingMetadataRow | curTaskMissingExpDataRows, :) = [];
        %% Set the store directories and file names of figures and excels.
        % Remove the existing items.
        curTaskResDir = fullfile(resFolder, curTaskIDName);
        if exist(curTaskResDir, 'dir')
            rmdir(curTaskResDir, 's')
        end
        % Excel file.
        xlsDir = 'Docs';
        curTaskXlsDir = fullfile(curTaskResDir, xlsDir);
        cfg.xlsdir = curTaskXlsDir;
        mkdir(curTaskXlsDir)
        % Figures.
        figDir = 'Figs';
        curTaskFigDir = fullfile(curTaskResDir, figDir);
        cfg.figdir = curTaskFigDir;
        mkdir(curTaskFigDir)
        %% Write a table of meta data. Summary report.
        curTaskVarsOfMetaDataOfInterest = {'school', 'grade'};
        curTaskMetaDataOfInterest = curTaskMetaData(:, ismember(curTaskVarsOfMetaData, curTaskVarsOfMetaDataOfInterest));
        despStats = grpstats(curTaskMetaDataOfInterest, {'school', 'grade'}, 'numel');
        despStats.Properties.VariableNames = {'School', 'Grade', 'Count'};
        writetable(despStats, fullfile(curTaskXlsDir, 'Counting of each school and grade.xlsx'));
        %Special issue: see if delete those data with too few subjects
        %(less than minsubs-modified in cfg).
        minorLoc = despStats.Count < cfg.minsubs;
        shadyEntryInd = find(minorLoc);
        if ~isempty(shadyEntryInd)
            curTaskMinorRowRemoved = ismember(curTaskMetaData.school, despStats.School(shadyEntryInd)) ...
                & ismember(curTaskMetaData.grade, despStats.Grade(shadyEntryInd));
            curTaskMetaData(curTaskMinorRowRemoved, :) = [];
            curTaskMetaData.grade = removecats(curTaskMetaData.grade);
            curTaskExpData(curTaskMinorRowRemoved, :) = [];
        end
        % Output bar figure (report the summary of data collection).
        barcaption       = 'Data collection summary';
        plotargin  = {curTaskMetaDataOfInterest};
        plotfun    = @sngplotmetabar;
        metadataSlide = genplotslides(plotfun, plotargin, barcaption, cfg);
        curTaskSlideData = strcat(curTaskSlideData, newline, metadataSlide);
        %% Condition-wise plotting.
        curTaskMrgConds = strsplit(curTaskSettings.MergeCond{:});
        if all(cellfun(@isempty, curTaskMrgConds))
            curTaskDelimiterMC = '';
        else
            curTaskDelimiterMC = '_';
        end
        ncond = length(curTaskMrgConds);
        curTaskCondSlidesData = repmat(cellstr(''), 1, ncond);
        for icond = 1:ncond
            curMrgCond = curTaskMrgConds{icond};
            cfg.cond = curMrgCond;
            %Update file storage directory.
            curCondTaskXlsDir = fullfile(curTaskXlsDir, curMrgCond);
            if ~exist(curCondTaskXlsDir, 'dir')
                mkdir(curCondTaskXlsDir)
                cfg.xlsdir = curCondTaskXlsDir;
            end
            curCondTaskFigDir = fullfile(curTaskFigDir, curMrgCond);
            if ~exist(curCondTaskFigDir, 'dir')
                mkdir(curCondTaskFigDir)
                cfg.figdir = curCondTaskFigDir;
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
            curCondTaskData                 = [curTaskMetaData, curCondTaskExpData];
            curCondTaskVarsOfExperimentData = curCondTaskExpData.Properties.VariableNames;
            %% Outlier checking.
            chkVar = curTaskSettings.chkVar{:};
            % Output Excel.
            chkTblVar = strcat(curTaskIDName, '_', chkVar);
            chkOutlierOutVars = 'Outliers';
            curTaskOutlier = grpstats(curCondTaskData, 'grade', @(x)coutlier(x, outliermode), ...
                'DataVars', chkTblVar, ...
                'VarNames', {'Grade', 'Total', chkOutlierOutVars});
            writetable(curTaskOutlier, ...
                fullfile(curCondTaskXlsDir, 'Counting of outliers of each grade.xlsx'));
            % Output boxplot figure.
            bpcaption = 'Outliers information';
            plotargin = {curCondTaskData, curTaskIDName, chkVar, outliermode};
            plotfun   = @sngplotbox;
            bpSlide   = genplotslides(plotfun, plotargin, bpcaption, cfg);
            %% Distribution of all variables and grades.
            %Remove outliers and plot histograms.
            grades = cellstr(unique(curTaskMetaData.grade));
            for igrade = 1:length(grades)
                curgradeidx = curCondTaskData.grade == grades{igrade};
                [~, outlieridx] = coutlier(curCondTaskData.(chkTblVar)(curgradeidx), 'extreme');
                curgradeidx(curgradeidx == 1) = outlieridx;
                curCondTaskData(curgradeidx, :) = [];
            end
            % Output boxplot figure.
            caption    = 'Histogram to show distribution';
            plotargin  = {curCondTaskData, curTaskIDName};
            plotfun    = @sngplothist;
            histSlides = genplotslides(plotfun, plotargin, caption, cfg);
            %% Write a table about descriptive statistics of different ages.
            agingDespStats = grpstats(curCondTaskData, 'grade', {'mean', 'std'}, ...
                'DataVars', curCondTaskVarsOfExperimentData);
            writetable(agingDespStats, ...
                fullfile(curCondTaskXlsDir, 'Descriptive statistics of each grade.xlsx'));
            %% Errorbar plots.
            %The caption of figures.
            caption = 'Development through ages';
            %Errorbar plot CP.
            cmbTasks = {'AssocMemory', 'SemanticMemory'};
            if ismember(curTaskIDName, cmbTasks)
                plotfun = @sngplotebcmb;
            else
                plotfun = @sngplotebmult;
            end
            curTaskChkVarsCat = strsplit(curTaskSettings.VarsCat{:});
            curTaskChkVarsCond = strsplit(curTaskSettings.VarsCond{:});
            if all(cellfun(@isempty, curTaskChkVarsCond))
                curTaskDelimiter = '';
            else
                curTaskDelimiter = '_';
            end
            ebcpSlides = '';
            if ~all(cellfun(@isempty, curTaskChkVarsCat)) || ~all(cellfun(@isempty, curTaskChkVarsCond))
                plotargin    = {curCondTaskData, curTaskIDName, curTaskChkVarsCat, curTaskDelimiter, curTaskChkVarsCond};
                ebcpSlides   = genplotslides(plotfun, plotargin, caption, cfg);
            end
            %Error bar plot of singleton variables.
            curTaskSngVars = strsplit(curTaskSettings.SingletonVars{:});
            ebsngSlides    = '';
            if ~all(cellfun(@isempty, curTaskSngVars))
                plotfun      = @sngplotebsingleton;
                plotargin    = {curCondTaskData, curTaskIDName, curTaskSngVars};
                ebsngSlides  = genplotslides(plotfun, plotargin, caption, cfg);
            end
            %Error bar plot of singleton variables CP.
            curTaskSngVarsCP = strsplit(curTaskSettings.SingletonVarsCP{:});
            ebsngcpSlides    = '';
            if ~all(cellfun(@isempty, curTaskSngVarsCP))
                plotfun       = @sngplotebmult;
                plotargin     = {curCondTaskData, curTaskIDName, curTaskSngVarsCP};
                ebsngcpSlides = genplotslides(plotfun, plotargin, caption, cfg);
            end
            %Error bar plot of special variables.
            curTaskSpVars = strsplit(curTaskSettings.SpecialVars{:});
            ebspSlides    = '';
            if ~all(cellfun(@isempty, curTaskSpVars))
                plotfun       = @sngplotebmult;
                plotargin     = {curCondTaskData, curTaskIDName, curTaskSpVars};
                ebspSlides    = genplotslides(plotfun, plotargin, caption, cfg);
            end
            curTaskCondSlidesData{icond} = strcat(...
                bpSlide, newline, ...
                ebcpSlides, newline, ...
                ebsngSlides, newline, ...
                ebsngcpSlides, newline, ...
                ebspSlides, newline, ...
                histSlides);
        end %for icond
        curTaskCondSlidesData = strjoin(curTaskCondSlidesData, newline);
        curTaskSlideData = strcat(curTaskSlideData, newline, curTaskCondSlidesData);
        curSectionSlideData{itask} = curTaskSlideData;
        %Record the time used for each task.
        curTaskTimeUsed = toc - elapsedTime;
        timeinfo.Time2Proc{ismember(tasks, curTaskIDName)} = seconds2human(curTaskTimeUsed, 'full');
        clearvars('-except', initialVarsTask{:});
    end %for itask
    SectionSlideData{isec} = strjoin(curSectionSlideData, newline);
    clearvars('-except', initialVarsSec{:});
end %for isec
if cfg.slidegen
    slidesdata = strjoin(cat(1, SectionTitles, SectionSlideData), newline);
    slidesMarkdown = [metadata, newline, slidesdata];
    fprintf(fid, slidesMarkdown);
    fclose(fid);
end
%Display information of completion.
usedTimeSecs = toc;
usedTimeHuman = seconds2human(usedTimeSecs, 'full');
fprintf('Congratulations! %d preprocessing task(s) completed this time.\n', nprocessed);
fprintf('Returning without error!\nTotal time used: %s\n', usedTimeHuman);
delete(hwb);
rmpath(anafunpath);
end %Plots

function cfg = chkconfig(cfg)
%CHKCONFIG converts cfg into the standard configuration.

fields = {'minsubs' 'outliermode' 'figfmt' 'slidegen' 'ext' 'task' 'cond' 'xlsdir' 'figdir'};
dflts  = {     20     'extreme'    'jpeg'     true     ''     ''     ''      ''       ''   };
for ifield = 1:length(fields)
    curfield = fields{ifield};
    if ~isfield(cfg, curfield) || isempty(cfg.(curfield))
        cfg.(curfield) = dflts{ifield};
    end
end
end %chkconfig

function h = setpaper(h)
%SETPAPER sets paper properties for figure printing and saving.

% Set the print parameters.
h.PaperUnits    = 'centimeters';
h.PaperSize     = [30, 25];
normalpappos       = [0.1, 0.1, 0.8, 0.8];
h.PaperPosition = repmat(h.PaperSize, 1, 2) .* normalpappos;
end %setpaper

function imstr = putimage(figfullname, caption)
%PUTIMAGE generates a string of pandoc code to put image onto slide.

global newline
figfullname = strconv(figfullname);
%two newlines are added posterior.
imstr = sprintf('![%s](%s)%s', caption, figfullname, newline);
end %putimage

function slidesmd = genplotslides(plotfun, plotargin, caption, cfg)
%GENPLOTSLIDES generates pandoc code for one single type of plots.

global newline slidepre
%Note use cell type to wrap all the figures for consistency.
[hs, hnames] =  plotfun(plotargin{:});
%Use cell type for further process.
if ~iscell(hs), hs = num2cell(hs); hnames = cellstr(hnames); end
%Set the print parameters.
hs = cellfun(@setpaper, hs, 'UniformOutput', false);
%Save figures.
figfullnames   = strcat(fullfile(cfg.figdir, hnames), cfg.ext);
cellfun(@saveas, hs, figfullnames)
cellfun(@delete, hs)
% Generate the markdown of current slide.
if ~isempty(cfg.cond)
    cfg.cond = ['-', cfg.cond];
end
slidetitle   = sprintf('%s %s%s', slidepre, cfg.task, cfg.cond);
slidecontent = cellfun(@(fp) putimage(fp, caption), cellstr(figfullnames), 'UniformOutput', false);
slides       = strcat(slidetitle, newline, slidecontent);
slidesmd     = strjoin(slides, newline);
end

function converted = strconv(origstr)
%TRANSLATE removes wrongly placed escape characters.

orig = {'\', '%'};
trans = {'\\', '%%'};
converted = origstr;
for itrans = 1:length(orig)
    converted = strrep(converted, orig{itrans}, trans{itrans});
end
end %strconv
