function dataExtract = Preproc(fname, shtname, db)
%PREPROC is used for processing raw data of CCDPro.
%   Raw data are originally stored in an Excel file. Input argument named
%   SHTNAME is short of sheet name.
%
%   See also SNGPREPROC.

%Here is a method of question category based way to read in data.
%By Zhang, Liang. 2015/11/27.
%Modified to use in another problem.
%Modification completed at 2016/04/13.

%Folder contains all the analysis and plots functions.
anafunpath = 'utilis';
addpath(anafunpath);
%Log file.
logfid = fopen('readlog(AutoGen).log', 'w');
%Load parameters.
para = readtable('taskSettings.xlsx', 'Sheet', 'para');
settings = readtable('taskSettings.xlsx', 'Sheet', 'settings');
taskIDNameMap = containers.Map(settings.TaskName, settings.TaskIDName);
%Get sheets' names.
[~, sheets] = xlsfinfo(fname);
%Check input variables. Some basic checking for shtname variable.
if nargin < 3
    db = false; %Debug mode.
end
if nargin < 2
    shtname = sheets';
end
%When constructing table, only cell string is allowed.
shtname = cellstr(shtname);
%If all the tasks in the data will be processed, ask if continue.
shtRange = find(ismember(sheets, shtname));
nsht = length(sheets);
if isequal(shtRange, 1:nsht) %Means all the tasks will be processed.
    userin = input('Will processing all the tasks found in the original data file, continue([Y]/N)?', 's');
    if isempty(userin)
        userin = 'yes';
    end
    if ~strcmpi(userin, 'y') && ~strcmpi(userin, 'yes')
        fprintf('No preprocessing task completed this time. User canceled...\n');
        dataExtract = [];
        return
    end
end
%Initializing works.
%Check the status of existence for the to-be-processed tasks (in shtname).
% 1. Checking the existence in the original data (in the Excel file).
dataExistence = ismember(shtname, sheets);
if ~all(dataExistence)
    fprintf('Oops! Data of these tasks you specified are not found, will remove these tasks...\n');
    disp(shtname(~dataExistence))
    shtname(~dataExistence) = []; %Remove not found tasks.
end
% 2. Checking the existence in the settings.
setExistence = ismember(shtname, settings.TaskName);
if ~all(setExistence)
    fprintf('Oops! Settings of these tasks you specified are not found, will remove these tasks...\n');
    disp(shtname(~setExistence))
    shtname(~setExistence) = []; %Remove not found tasks.
end
%Use the task order formed in the settings.
TaskName = settings.TaskName(ismember(settings.TaskName, shtname));
ntasks4process = length(TaskName);
TaskIDName = cell(ntasks4process, 1);
Data = cell(ntasks4process, 1);
Time2Preproc = repmat(cellstr('TBE'), ntasks4process, 1);
%Preallocating.
dataExtract = table(TaskName, TaskIDName, Data, Time2Preproc);
%Display the information of processing.
fprintf('Here it goes! The total jobs are composed of %d task(s), though some may fail...\n', ...
    ntasks4process);
%Use a waitbar to tell the processing information.
if ~db
    hwb = waitbar(0, 'Begin processing the tasks specified by users...Please wait...', ...
        'Name', 'Preprocess raw data of CCDPro',...
        'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
    setappdata(hwb, 'canceling', 0)
end
nprocessed = 0;
nignored = 0;
%Start stopwatch.
tic
elapsedTime = 0;
%Sheet-wise processing.
for itask = 1:ntasks4process
    initialVarsSht = who;
    curTaskName = TaskName{itask};
    if ~db
        % Check for Cancel button press.
        if getappdata(hwb, 'canceling')
            fprintf('User canceled...\n');
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
        msg = sprintf('Task: %s. %s', taskIDNameMap(curTaskName), msgSuff);
        waitbar(completePercent, hwb, msg);
    end
    %Find out the setting of current task.
    locset = ismember(settings.TaskName, curTaskName);
    if ~any(locset)
        fprintf(logfid, ...
            'No settings specified for task %s. Continue to the next task.\n', curTaskName);
        %Increment of ignored number of tasks.
        nignored = nignored + 1;
        continue
    end
    %Unpdate processed tasks number.
    nprocessed = nprocessed + 1;
    %Read in all the information from the specified file.
    curTaskData = readtable(fname, 'Sheet', curTaskName);
    %Check if the data fields are in the correct type.
    varsOfChk = {'Taskname', 'userId', 'gender', 'school', 'grade', 'birthDay', 'conditions'};
    varsOfChkClass = {'cell', 'double', 'cell', 'cell', 'cell', 'cell', 'cell'};
    for ivar = 1:length(varsOfChk)
        curVar = varsOfChk{ivar};
        curClass = varsOfChkClass{ivar};
        if ~isa(curTaskData.(curVar), curClass)
            switch curClass
                case 'cell'
                    curTaskData.(curVar) = num2cell(curTaskData.(curVar));
                case 'double'
                    curTaskData.(curVar) = str2double(curTaskData.(curVar));
            end
        end
    end
    %Get a table curTaskCfg to combine two variables: conditions and para,
    %which are used in the function sngproc. See more in function sngproc.
    curTaskSetting = settings(locset, :);
    curTaskPara = para(ismember(para.TemplateToken, curTaskSetting.TemplateToken), :);
    curTaskCfg = table;
    curTaskCfg.conditions = curTaskData.conditions;
    curTaskCfg.para = repmat({curTaskPara}, height(curTaskData), 1);
    cursplit = rowfun(@sngpreproc, curTaskCfg, 'OutputVariableNames', {'splitRes', 'status'});
    curTaskRes = cat(1, cursplit.splitRes{:});
    curTaskRes.status = cursplit.status;
    %Generate some warning according to the status.
    if any(cursplit.status ~= 0)
        warning('UDF:PREPROC:DATAMISMATCH', 'Oops! Data mismatch in task %s.\n', curTaskName);
        if any(cursplit.status == -1) %Data mismatch found.
            fprintf(logfid, ...
                'Data mismatch encountered in task %s. Normally, its format is ''%s''.\r\n', ...
                curTaskName, curTaskPara.VariablesNames{:});
        end
        if any(cursplit.status == -2) %Parameters for this task not found.
            fprintf(logfid, ...
                'No parameters specification found in task %s.\r\n', ...
                curTaskName);
        end
    end
    %Use curTaskRes as the results variable store. And store the TaskIDName
    %from settings, which is usually used in the following analysis.
    curTaskOutVarsOIMetadata = ...
        {'userId', 'gender', 'school', 'grade', 'birthDay'};
    curTaskRes = curTaskData(:, ismember(curTaskData.Properties.VariableNames, curTaskOutVarsOIMetadata));
    %Store the taskIDName.
    dataExtract.TaskIDName(itask) = curTaskSetting.TaskIDName;
    %Store the spitting results.
    curTaskSpitRes = cat(1, cursplit.splitRes{:});
    curTaskSplitResVars = curTaskSpitRes.Properties.VariableNames;
    nvars = length(curTaskSplitResVars);
    for ivar = 1:nvars
        curTaskRes.(curTaskSplitResVars{ivar}) = curTaskSpitRes.(curTaskSplitResVars{ivar});
    end
    curTaskRes.status = cursplit.status;
    dataExtract.Data{itask} = curTaskRes;
    %Record the time used for each task.
    curTaskTimeUsed = toc - elapsedTime;
    dataExtract.Time2Preproc{itask} = seconds2human(curTaskTimeUsed, 'full');
    clearvars('-except', initialVarsSht{:});
end
%Display information of completion.
usedTimeSecs = toc;
usedTimeHuman = seconds2human(usedTimeSecs, 'full');
fprintf('Congratulations! %d preprocessing task(s) completed this time.\n', nprocessed);
fprintf('Returning without error!\nTotal time used: %s\n', usedTimeHuman);
fclose(logfid);
if ~db, delete(hwb); end
rmpath(anafunpath);
