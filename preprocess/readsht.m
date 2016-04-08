function dataExtract = readsht(fname, shtname)
%This script is used for processing data from HQH, mainly about some
%examination used by students.

%Here is a method of question category based way to read in data.
%By Zhang, Liang. 2015/11/27.
%Modified to use in another problem. 

%Check input variables.
if nargin < 2
    shtname = '';
end

%Load parameters.
para = readtable('para.xlsx', 'Sheet', 'para');
settings = readtable('settings.xlsx', 'Sheet', 'settings');

%Get sheets' names.
[~, sheets] = xlsfinfo(fname);

%Log file.
logfid = fopen('ReadLog.log', 'w');

%Sheet-wise processing.
nsht = length(sheets);
%Initializing works.
insht = find(ismember(sheets, shtname));
if isempty(insht)
    userin = input('Will processing all the sheets, continue([Y]/N)?', 's');
    if strcmpi(userin, 'n') || strcmpi(userin, 'no')
        return
    end
    ssht = 1;
    dataExtract = struct('TaskName', sheets', 'Data', cell(nsht, 1));
else %Only do jobs in the specified sheet.
    ssht = insht;
    nsht = insht;
    dataExtract = struct('TaskName', shtname, 'Data', cell(1, 1));
end
%Begin processing.
for isht = ssht:nsht
    initialVarsSht = who;
    %Find out the setting of current task.
    curTaskName = sheets{isht};
    locset = ismember(settings.TaskName, curTaskName);
    if ~any(locset)
        continue
    end
    fprintf('Now processing sheet %s\n', curTaskName);
    
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
    dataExtract(isht).Data = curTaskData;
    clearvars('-except', initialVarsSht{:});
end
fclose(logfid);
