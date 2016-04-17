function resdata = basicCompute(dataExtract, tasks)
%BASICCOMPUTE Does some basic computation on data.
%   RESDATA = BASICCOMPUTETOMERGE(DATA) does some basic analysis to the
%   output of function readsht. Including basic analysis.
%
%   See also readsht, sngproc.

%Zhang, Liang. 04/14/2016, E-mail:psychelzh@gmail.com.

%Checking input arguments.
if nargin < 2
    tasks = dataExtract.Taskname;
end

%Folder contains all the analysis functions.
anafunpath = 'analysis';
addpath(anafunpath);
%Load basic parameters.
settings = readtable('taskSettings.xlsx', 'Sheet', 'settings');

% Basic computation.
% Task-wise computation.
dataExtract(cellfun(@isempty, dataExtract.Data), :) = []; %Remove rows without any data.
% Initializing works.
if ~iscell(tasks)
    %When constructing table, character array is not allowed, but cell
    %string is allowed.
    tasks = {tasks};
end
if isrow(tasks)
    tasks = tasks';
end
ntasks = length(dataExtract.Taskname);
taskRange = find(ismember(dataExtract.Taskname, tasks));
ntasks4process = length(taskRange);
if isequal(taskRange, (1:ntasks)')
    fprintf('Will processing all the tasks!');
end
%Begin computing.
for itask = 1:ntasks4process
    initialVarsTask = who;
    %Find out the setting of current task.
    curTaskName = dataExtract.Taskname{taskRange(itask)};
    fprintf('Now processing task %s\n', curTaskName);
    %Setting for the computation of current task.
    curTaskData = dataExtract.Data{taskRange(itask)};
    curTaskSetting = settings(ismember(settings.TaskName, curTaskName), :);
    if isempty(curTaskSetting.AnalysisFun{:})
        fprintf('No analysis function found for current task. Will delete this task. Aborting...\n');
        dataExtract.Data{ismember(dataExtract.Taskname, curTaskName)} = [];
        continue
    elseif all(cellfun(@isempty, curTaskData.splitRes))
        fprintf('No correct recorded data is found. Will delete this task. Aborting...\n');
        dataExtract.Data{ismember(dataExtract.Taskname, curTaskName)} = [];
        continue
    end
    anafun = str2func(curTaskSetting.AnalysisFun{:});
    anavars = strsplit(curTaskSetting.AnalysisVariableNames{:});
    anares = rowfun(anafun, curTaskData, 'InputVariables', anavars, 'OutputVariableNames', 'res');
    curTaskData.res = anares.res;
    dataExtract.Data{ismember(dataExtract.Taskname, curTaskName)} = curTaskData;
    clearvars('-except', initialVarsTask{:});
end
%Concatenate data into one single table.
dataExtract(cellfun(@isempty, dataExtract.Data), :) = [];
ntaskRange = ismember(dataExtract.Taskname, tasks);
resdata = dataExtract(ntaskRange, :);
rmpath(anafunpath);
