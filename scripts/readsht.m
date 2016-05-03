function dataExtract = readsht(fname, shtname)
%This script is used for processing raw data of CCDPro, stored originally
%in an Excel file.

%Here is a method of question category based way to read in data.
%By Zhang, Liang. 2015/11/27.
%Modified to use in another problem. 
%Modification completed at 2016/04/13.

%Folder contains all the analysis and plots functions.
anafunpath = 'analysis';
addpath(anafunpath);
%Get sheets' names.
[~, sheets] = xlsfinfo(fname);
%Check input variables. Some basic checking for shtname variable.
if nargin < 2
    shtname = sheets';
end
if ~iscell(shtname)
    %When constructing table, character array is not allowed, but cell
    %string is allowed.
    shtname = {shtname};
end
if isrow(shtname)
    shtname = shtname';
end
%Log file.
logfid = fopen('ReadLog.log', 'w');
%Initializing works.
nsht = length(sheets);
shtRange = find(ismember(sheets, shtname));
nsht4process = length(shtRange);
if isequal(shtRange, 1:nsht) %Means all the tasks will be processed.
    userin = input('Will processing all the sheets, continue([Y]/N)?', 's');
    if strcmpi(userin, 'n') || strcmpi(userin, 'no')
        dataExtract = [];
        return
    end
end
Taskname = sheets(shtRange)';
TaskIDName = cell(nsht4process, 1);
Data = cell(nsht4process, 1);
%Preallocating.
dataExtract = table(Taskname, TaskIDName, Data);
%Load parameters.
para = readtable('taskSettings.xlsx', 'Sheet', 'para');
settings = readtable('taskSettings.xlsx', 'Sheet', 'settings');
%Sheet-wise processing.
for isht = 1:nsht4process
    initialVarsSht = who;
    %Find out the setting of current task.
    curTaskName = Taskname{isht};
    fprintf('Now processing sheet %s\n', curTaskName);
    locset = ismember(settings.TaskName, curTaskName);
    if ~any(locset)
        fprintf('No settings specified for current task.\n');
        continue
    end
    %Read in all the information from the specified file.
    curTaskData = readtable(fname, 'Sheet', curTaskName);
    %Get the information of interest, and check the format.
    varsOfInterest = {'userId', 'gender', 'school', 'grade', 'birthDay', 'conditions'};
    varsOfInterestClass = {'double', 'cell', 'cell', 'cell', 'cell', 'cell'};
    curTaskData(:, ~ismember(curTaskData.Properties.VariableNames, varsOfInterest)) = [];
    for ivar = 1:length(varsOfInterest)
        curVar = varsOfInterest{ivar};
        curClass = varsOfInterestClass{ivar};
        if ~isa(curTaskData.(curVar), curClass)
            switch curClass
                case 'cell'
                    curTaskData.(curVar) = repmat({''}, height(curTaskData), 1);
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
    cursplit = rowfun(@sngproc, curTaskCfg, 'OutputVariableNames', {'splitRes', 'status'});
    %Generate some warning according to the status.
    if any(cursplit.status ~= 0)
        warning('UDF:READSHT:DATAMISMATCH', 'Oops! Data mismatch in task %s.\n', curTaskName);
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
    %Store the TaskIDName from settings, which is usually used in the
    %following analysis.
    dataExtract.TaskIDName(isht) = curTaskSetting.TaskIDName;
    curTaskData.splitRes = cursplit.splitRes; % Store the split results.
    curTaskData.status = cursplit.status; % Store the status,
    dataExtract.Data{isht} = curTaskData;
    clearvars('-except', initialVarsSht{:});
end
fclose(logfid);
rmpath(anafunpath);
