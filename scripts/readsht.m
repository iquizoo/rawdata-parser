function dataExtract = readsht(fname, shtname)
%This script is used for processing raw data of CCDPro, stored originally
%in an Excel file.

%Here is a method of question category based way to read in data.
%By Zhang, Liang. 2015/11/27.
%Modified to use in another problem. 
%Modification completed at 2016/04/13.

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

%Sheet-wise processing.
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
Taskname = shtname;
Data = cell(nsht4process, 1);
%Preallocating.
dataExtract = table(Taskname, Data);
%Load parameters.
para = readtable('taskSettings.xlsx', 'Sheet', 'para');
settings = readtable('taskSettings.xlsx', 'Sheet', 'settings');
%Begin processing.
for isht = 1:nsht4process
    initialVarsSht = who;
    %Find out the setting of current task.
    curTaskName = sheets{shtRange(isht)};
    fprintf('Now processing sheet %s\n', curTaskName);
    locset = ismember(settings.TaskName, curTaskName);
    if ~any(locset)
        fprintf('No settings specified for current task.\n');
        continue
    end
    %Read in the information of interest.
    curTaskData = readtable(fname, 'Sheet', curTaskName);
    curTaskSetting = settings(locset, :);
    curTaskPara = para(ismember(para.TemplateIdentity, curTaskSetting.TemplateIdentity), :);
    curTaskCfg = table;
    curTaskCfg.conditions = curTaskData.conditions;
    curTaskCfg.para = repmat({curTaskPara}, height(curTaskData), 1);
    cursplit = rowfun(@sngproc, curTaskCfg, 'OutputVariableNames', {'splitRes', 'status'});
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
    curTaskData.splitRes = cursplit.splitRes;
    curTaskData.status = cursplit.status;
    dataExtract.Data{isht} = curTaskData;
    clearvars('-except', initialVarsSht{:});
end
fclose(logfid);
