function resdata = basicCompute(dataExtract, tasks)
%BASICCOMPUTE Does some basic computation on data.
%   RESDATA = BASICCOMPUTETOMERGE(DATA) does some basic analysis to the
%   output of function readsht. Including basic analysis.
%
%   See also readsht, sngproc.

%Zhang, Liang. 04/14/2016, E-mail:psychelzh@gmail.com.

%% Initialization jobs.
% Checking input arguments.
if nargin < 2
    tasks = dataExtract.Taskname;
end
%Folder contains all the analysis functions.
anafunpath = 'analysis';
addpath(anafunpath);
%Load basic parameters.
settings = readtable('taskSettings.xlsx', 'Sheet', 'settings');
% Basic computation.
dataExtract(cellfun(@isempty, dataExtract.Data), :) = []; %Remove rows without any data.
%When constructing table, character array is not allowed, but cell string
%is allowed.
if ~iscell(tasks)
    tasks = {tasks};
end
if isrow(tasks)
    tasks = tasks';
end
ntasks = length(dataExtract.Taskname);
taskRange = find(ismember(dataExtract.Taskname, tasks));
ntasks4process = length(taskRange);
%Display some message.
fprintf('Now do some basic computation and transformation to the extracted data.\n');
if isequal(taskRange, (1:ntasks)')
    fprintf('Will process all the tasks!\n');
end
%% Task-wise computation.
%Use lastexcept as an indicator of exception in last task.
lastexcept = false;
latestsprint = '';
%Begin computing.
for itask = 1:ntasks4process
    initialVarsTask = who;
    %% Find out the setting of current task.
    curTaskData = dataExtract.Data{taskRange(itask)};
    curTaskName = dataExtract.Taskname{taskRange(itask)};
    curTaskSetting = settings(ismember(settings.TaskName, curTaskName), :);
    curTaskIDName = curTaskSetting.TaskIDName{:};
    %Delete last line without exception.
    if ~lastexcept
        fprintf(repmat('\b', 1, length(latestsprint)))
    end
    %Get the ordinal string.
    ordStr = num2ord(itask);
    latestsprint = sprintf('Now process the %s task %s(%s).\n', ordStr, curTaskName, curTaskIDName);
    fprintf(latestsprint);
    lastexcept = false;
    if isempty(curTaskSetting.AnalysisFun{:})
        fprintf('No analysis function found for current task. Will delete this task. Aborting...\n');
        dataExtract.Data{ismember(dataExtract.Taskname, curTaskName)} = [];
        lastexcept = true;
        continue
    elseif all(cellfun(@isempty, curTaskData.splitRes))
        fprintf('No correct recorded data is found. Will delete this task. Aborting...\n');
        dataExtract.Data{ismember(dataExtract.Taskname, curTaskName)} = [];
        lastexcept = true;
        continue
    end
    anavars = 'splitRes';
    %% Get curTaskSTIMMap for some tasks (esp. for NSN), and analysis for every subject.
    switch curTaskIDName
        case {'Symbol', 'Orthograph', 'Tone', 'Pinyin', 'Lexic', 'Semantic', ...%langTasks
                'GNGLure', 'GNGFruit', ...%some of otherTasks in NSN.
                'Flanker', 'TaskSwitching', ...%Conflict
                }
            curTaskEncode = readtable('taskSettings.xlsx', 'Sheet', curTaskIDName);
            curTaskSTIMMap = containers.Map(curTaskEncode.STIM, curTaskEncode.SCat);
            %TaskIDName as one input argument because RT cutoffs are
            %different for different tasks.
            anares = rowfun(@(x) sngstats(x, curTaskSetting, curTaskSTIMMap), ...
                curTaskData, 'InputVariables', anavars, 'OutputVariableNames', 'res');
        otherwise
            anares = rowfun(@(x) sngstats(x, curTaskSetting), ...
                curTaskData, 'InputVariables', anavars, 'OutputVariableNames', 'res');
    end
    %% Post-computation jobs.
    curTaskData.res = anares.res;
    dataExtract.Data{ismember(dataExtract.Taskname, curTaskName)} = curTaskData;
    clearvars('-except', initialVarsTask{:});
end
resdata = dataExtract(taskRange, :);
resdata(cellfun(@isempty, resdata.Data), :) = []; %Remove rows without any data.
rmpath(anafunpath);
