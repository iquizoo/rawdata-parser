function dataExtract = Preproc(fname, varargin)
%PREPROC is used for processing raw data of CCDPro.
%   Raw data are originally stored in an Excel file. Input argument named
%   SHTNAME is short of sheet name.
%
%   See also SNGPREPROC.

%Here is a method of question category based way to read in data.
%By Zhang, Liang. 2015/11/27.
%Modified to use in another problem.
%Modification completed at 2016/04/13.

% Parse input arguments.
par = inputParser;
parNames   = {         'TaskNames',       'DisplayInfo'};
parDflts   = {              [],              'text'    };
parValFuns = {@(x) ischar(x) | iscellstr(x), @ischar   };
cellfun(@(x, y, z) addParameter(par, x, y, z), parNames, parDflts, parValFuns);
parse(par, varargin{:});
shtname = par.Results.TaskNames;
prompt  = lower(par.Results.DisplayInfo);
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
%Check whether shtname is empty, if so, change it to denote all the sheets.
if isempty(shtname)
    shtname = sheets';
end
%When constructing table, only cell string is allowed.
shtname = cellstr(shtname);
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
switch prompt
    case 'waitbar'
        hwb = waitbar(0, 'Begin processing the tasks specified by users...Please wait...', ...
            'Name', 'Preprocess raw data of CCDPro',...
            'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
        setappdata(hwb, 'canceling', 0)
    case 'text'
        except  = false;
        dispinfo = '';
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
    %Update prompt information.
    %Get the proportion of completion and the estimated time of arrival.
    completePercent = nprocessed / (ntasks4process - nignored);
    if nprocessed == 0
        msgSuff = 'Please wait...';
    else
        elapsedTime = toc;
        eta = seconds2human(elapsedTime * (1 - completePercent) / completePercent, 'full');
        msgSuff = strcat('TimeRem:', eta);
    end
    switch prompt
        case 'waitbar'
            % Check for Cancel button press.
            if getappdata(hwb, 'canceling')
                fprintf('User canceled...\n');
                break
            end
            %Update message in the waitbar.
            msg = sprintf('Task: %s. %s', taskIDNameMap(curTaskName), msgSuff);
            waitbar(completePercent, hwb, msg);
        case 'text'
            if ~except
                fprintf(repmat('\b', 1, length(dispinfo)));
            end
            dispinfo = sprintf('Now processing %s (total: %d) task: %s(%s). %s\n', ...
                num2ord(nprocessed + 1), ntasks4process, curTaskName, taskIDNameMap(curTaskName), msgSuff);
            fprintf(dispinfo);
            except = false;
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
    varsOfChk = {'Taskname', 'userId', 'name', 'gender', 'school', 'grade', 'cls', 'birthDay', 'createDate', 'conditions'};
    varsOfChkClass = {'cell', 'double', 'cell', 'cell', 'cell', 'cell', 'cell', 'datetime', 'datetime', 'cell'};
    for ivar = 1:length(varsOfChk)
        curVar = varsOfChk{ivar};
        curClass = varsOfChkClass{ivar};
        if ismember(curVar, curTaskData.Properties.VariableNames) %For better compatibility.
            if ~isa(curTaskData.(curVar), curClass)
                switch curClass
                    case 'cell'
                        curTaskData.(curVar) = num2cell(curTaskData.(curVar));
                    case 'double'
                        curTaskData.(curVar) = str2double(curTaskData.(curVar));
                    case 'datetime'
                        curTaskData.(curVar) = datetime(curTaskData.(curVar));
                end
            end
        end
    end
    %Get the setting of current task.
    curTaskSetting = settings(locset, :);
    %Store the taskIDName.
    dataExtract.TaskIDName(itask) = curTaskSetting.TaskIDName;
    %Get a table curTaskCfg to combine two variables: conditions and para,
    %which are used in the function sngproc. See more in function sngproc.
    curTaskPara = para(ismember(para.TemplateToken, curTaskSetting.TemplateToken), :);
    curTaskCfg = table;
    curTaskCfg.conditions = curTaskData.conditions;
    curTaskCfg.para = repmat({curTaskPara}, height(curTaskData), 1);
    cursplit = rowfun(@sngpreproc, curTaskCfg, 'OutputVariableNames', {'splitRes', 'status'});
    if isempty(cursplit)
        warning('UDF:PREPROC:DATAMISMATCH', 'No data found for task %s. Will keep it empty.\n', curTaskName);
        fprintf(logfid, ...
            'No data found for task %s.\r\n', curTaskName);
        except = true;
    else
        curTaskRes = cat(1, cursplit.splitRes{:});
        curTaskRes.status = cursplit.status;
        %Generate some warning according to the status.
        if any(cursplit.status ~= 0)
            except = true;
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
            {'userId', 'name', 'gender', 'school', 'grade', 'cls', 'birthDay', 'createDate'};
        curTaskRes = curTaskData(:, ismember(curTaskData.Properties.VariableNames, curTaskOutVarsOIMetadata));
        %Store the spitting results.
        curTaskSplitRes = cat(1, cursplit.splitRes{:});
        curTaskSplitResVars = curTaskSplitRes.Properties.VariableNames;
        nvars = length(curTaskSplitResVars);
        for ivar = 1:nvars
            curTaskRes.(curTaskSplitResVars{ivar}) = curTaskSplitRes.(curTaskSplitResVars{ivar});
        end
        curTaskRes.status = cursplit.status;
        dataExtract.Data{itask} = curTaskRes;
    end
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
if strcmp(prompt, 'waitbar'), delete(hwb); end
rmpath(anafunpath);
