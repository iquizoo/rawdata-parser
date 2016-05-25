function resdata = Proc(dataExtract, tasks, db, method)
%PROC Does some basic computation on data.
%   RESDATA = PROC(DATA) does some basic analysis to the
%   output of function readsht. Including basic analysis.
%
%   See also PREPROC, SNGPROC.

%Zhang, Liang. 04/14/2016, E-mail:psychelzh@gmail.com.

%% Initialization jobs.
% Checking input arguments.
if nargin < 2
    tasks = [];
end
if nargin < 3
    db = false; %Debug mode.
end
if nargin < 4
    method = 'full';
end
%Folder contains all the analysis functions.
anafunpath = 'utilis';
addpath(anafunpath);
%Log file.
logfid = fopen('readlog(AutoGen).log', 'w');
%Load basic parameters.
settings = readtable('taskSettings.xlsx', 'Sheet', 'settings');
taskIDNameMap = containers.Map(settings.TaskName, settings.TaskIDName);
%Remove rows without any data.
dataExtract(cellfun(@isempty, dataExtract.Data), :) = [];
%Display notation message.
fprintf('Now do some basic computation and transformation to the extracted data.\n');
%When constructing table, only cell string is allowed.
if isempty(tasks)
    tasks = dataExtract.TaskName;
end
tasks = cellstr(tasks);
%Check the status of existence for the to-be-processed tasks.
dataExistence = ismember(tasks, dataExtract.TaskName);
if ~all(dataExistence)
    fprintf('Oops! Data of these tasks you specified are not found, will remove these tasks...\n');
    disp(tasks(~dataExistence))
    tasks(~dataExistence) = []; %Remove not found tasks.
end
%If all the tasks in the data will be processed, display this information.
ntasks = length(dataExtract.TaskName);
taskRange = find(ismember(dataExtract.TaskName, tasks));
if isequal(taskRange, (1:ntasks)')
    fprintf('Will process all the tasks!\n');
end
ntasks4process = length(taskRange);
fprintf('OK! The total jobs are composed of %d task(s), though some may fail...\n', ...
    ntasks4process);
%Add a field to record time used to process in each task.
dataExtract.Time2Proc = repmat(cellstr('TBE'), height(dataExtract), 1);
%% Task-wise computation.
%Use a waitbar to tell the processing information.
if ~db
    hwb = waitbar(0, 'Begin processing the tasks specified by users...Please wait...', ...
        'Name', 'Process the data extracted of CCDPro',...
        'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
    setappdata(hwb, 'canceling', 0)
end
nprocessed = 0;
nignored = 0;
%Start stopwatch.
tic
elapsedTime = 0;
%Begin computing.
for itask = 1:ntasks4process
    initialVarsTask = who;
    %% In loop initialzation tasks.
    curTaskData = dataExtract.Data{taskRange(itask)};
    curTaskName = dataExtract.TaskName{taskRange(itask)};
    curTaskSetting = settings(ismember(settings.TaskName, curTaskName), :);
    curTaskIDName = curTaskSetting.TaskIDName{:};
    %Get all the analysis variables.
    anaVars = strsplit(curTaskSetting.AnalysisVars{:});
    %Merge conditions. Useful when merging data.
    mrgCond = strsplit(curTaskSetting.MergeCond{:});
    %% Update waitbar.
    if ~db
        % Check for Cancel button press
        if getappdata(hwb, 'canceling')
            fprintf('%d basic analysis task(s) completed this time. User canceled...\n', nprocessed);
            break
        end
        %Get the proportion of completion and the estimated time of arrival.
        completePercent = nprocessed / (ntasks4process - nignored);
        if nprocessed == 0
            msgSuff = 'Please wait...';
        else
            elapsedTime = toc;
            eta = seconds2human(elapsedTime * (1 - completePercent) / completePercent, 'full');
            msgSuff = strcat('TimeRem:', eta);
        end
        %Update message in the waitbar.
        msg = sprintf('Task(%d/%d): %s. %s', itask, ntasks4process, taskIDNameMap(curTaskName), msgSuff);
        waitbar(completePercent, hwb, msg);
    end
    %Unpdate processed tasks number.
    nprocessed = nprocessed + 1;
    %% Analysis for every subject.
    %Initialization tasks. Preallocation.
    nvar = length(anaVars);
    nsubj = height(curTaskData);
    anares = cell(nsubj, nvar); %To know why cell type is used, see the following.
    for ivar = 1:nvar
        %In loop initialization.
        curAnaVar = anaVars{ivar};
        curMrgCond = mrgCond{ivar};
        %Check whether the data are recorded legally or not.
        if isempty(curAnaVar) || all(cellfun(@isempty, curTaskData.(curAnaVar)))
            fprintf(logfid, ...
                'No correct recorded data is found in task %s. Will ignore this task. Aborting...\n', curTaskIDName);
            %Increment of ignored number of tasks.
            nignored = nignored + 1;
            continue
        end
        switch curTaskIDName
            case {'Symbol', 'Orthograph', 'Tone', 'Pinyin', 'Lexic', 'Semantic', ...%langTasks
                    'GNGLure', 'GNGFruit', ...%some of otherTasks in NSN.
                    'Flanker', 'TaskSwitching', ...%Conflict
                    }
                %Get curTaskSTIMMap (STIM->SCat) for these tasks.
                curTaskEncode = readtable('taskSettings.xlsx', 'Sheet', curTaskIDName);
                curTaskSTIMMap = containers.Map(curTaskEncode.STIM, curTaskEncode.SCat);
            otherwise
                %Construct an empty curTaskSTIMMap.
                curTaskSTIMMap = containers.Map;
        end
        %Table is wrapped into a cell. The table type of MATLAB has
        %something tricky when nesting table type in a table; it treats the
        %rows of the nested table as integrated when using rowfun or
        %concatenating.
        anares(:, ivar) = rowfun(@(x) sngproc(x, curTaskSetting, curMrgCond, curTaskSTIMMap, method), ...
            curTaskData, 'InputVariables', curAnaVar, 'OutputFormat', 'cell');
    end
    %% Post-computation jobs.
    allsubids = (1:nsubj)'; %Column vector is used in order to form a table.
    anaresmrg = arrayfun(@(isubj) {horzcat(anares{isubj, :})}, allsubids);
    %Remove score field in the res.
    if all(cellfun(@isempty, anaresmrg))
        fprintf(logfid, ...
            'No valid results found in task %s. Will ignore this task. Aborting...\n', curTaskIDName);
        %Increment of ignored number of tasks.
        nignored = nignored + 1;
        continue
    end
    %Get the score in an independent field.
    restbl = cat(1, anaresmrg{:});
    allresvars = restbl.Properties.VariableNames;
    scorevars = allresvars(~cellfun(@isempty, regexp(allresvars, '^score', 'once')));
    score = rowfun(@(varargin) sum([varargin{:}]), restbl, ...
        'InputVariables', scorevars, 'OutputFormat', 'uniform');
    %Get the ultimate index.
    ultIndexVar = curTaskSetting.UltimateIndex{:};
    ultIndex    = nan(height(restbl), 1);
    if ~isempty(ultIndexVar)
        switch ultIndexVar
            case 'ConflictUnion'
                conflictCondVars = strsplit(curTaskSetting.VarsCond{:});
                conflictVars = strcat(strsplit(curTaskSetting.VarsCat{:}), '_', conflictCondVars{end});
                restbl{rowfun(@(varargin) any([varargin{:}], 2), ...
                    rowfun(@(varargin) isnan([varargin{:}]), restbl, ...
                    'InputVariables', conflictVars), 'OutputFormat', 'uniform'), :} = nan;
                conflictZ = varfun(@(x) (x - nanmean(x)) / nanstd(x), restbl, 'InputVariables', conflictVars);
                ultIndex = rowfun(@(varargin) sum([varargin{:}]), conflictZ, 'OutputFormat', 'uniform');
            case 'dprimeUnion'
                indexMateVar = ~cellfun(@isempty, regexp(allresvars, 'dprime', 'once'));
                ultIndex = rowfun(@(varargin) sum([varargin{:}]), restbl, 'InputVariables', indexMateVar, 'OutputFormat', 'uniform');
            otherwise
                ultIndex = restbl.(ultIndexVar);
        end
    end
    %Remove score from anaresmrg.
    for irow = 1:length(anaresmrg)
        curresvars = anaresmrg{irow}.Properties.VariableNames;
        anaresmrg{irow}(:, ~cellfun(@isempty, regexp(curresvars, '^score', 'once'))) = [];
    end
    %Wraper.
    curTaskData.res = anaresmrg;
    curTaskData.score = score;
    curTaskData.index = ultIndex;
    dataExtract.Data{taskRange(itask)} = curTaskData;
    %Record the time used for each task.
    curTaskTimeUsed = toc - elapsedTime;
    dataExtract.Time2Proc{taskRange(itask)} = seconds2human(curTaskTimeUsed, 'full');
    clearvars('-except', initialVarsTask{:});
end
resdata = dataExtract(taskRange, :);
%Remove rows without results data.
resdata(cellfun(@(tbl) ~ismember('res', tbl.Properties.VariableNames), resdata.Data), :) = [];
%Display information of completion.
usedTimeSecs = toc;
usedTimeHuman = seconds2human(usedTimeSecs, 'full');
fprintf('Congratulations! %d basic analysis task(s) completed this time.\n', nprocessed);
fprintf('Returning without error!\nTotal time used: %s\n', usedTimeHuman);
fclose(logfid);
if ~db, delete(hwb); end
rmpath(anafunpath);
