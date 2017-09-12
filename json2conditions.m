function json2conditions(origfilename, resfolder)
% Extract data from JSON formatted strings.

% create log file.
logfile = fopen('j2c.log', 'a');
fprintf(logfile, ...
    '[%s] Start transforming from %s.\n', datestr(now), origfilename);
if ~exist(resfolder, 'dir'), mkdir(resfolder); end
% Read data.
records  = readtable(origfilename);
% basic checking of original data for the existence of task ids.
idvar = 'excerciseId';
if ~ismember(idvar, records.Properties.VariableNames)
    error('UDF:DATAINVALID', ...
        '`excerciseId` or `exerciseId` field not found, please check the data.')
end
outVars  = union(setdiff(records.Properties.VariableNames, 'data'), {'alltime', 'conditions'});
records(cellfun(@isempty, records.data), :) = [];
% Parse json formatted data into a structure and select the conditions (experimental data).
records.dataPar = rowfun(@(x) jsondecode(x{:}), records, 'InputVariables', 'data', 'OutputFormat', 'cell');
records.alltime = nan(height(records), 1);
records.conditions = repmat({''}, height(records), 1);
% settings.
paraVar = 'params';
spVar = 'allTime';
% transform taskIDs to double type
taskIDs = unique(records.(idvar));
if iscellstr(taskIDs), taskIDs = str2double(taskIDs); end
% get the field names of data records and transform it
dataFieldNames = repmat({''}, size(taskIDs));
dataTransNames = dataFieldNames;
for iTask = 1:length(taskIDs)
    switch taskIDs(iTask)
        case 97989 % '联系记忆（高级版）'
            dataFieldNames{iTask} = 'tconditions';
        case 99986 %'语义记忆'
            dataFieldNames{iTask} = 'sconditions&tconditions';
            dataTransNames{iTask} = 's&t';
        case {100010, 100018, 97976} %{'分配注意中级', '分配注意初级'}
            dataFieldNames{iTask} = 'lconditions|leftconditions|leftConditions&rconditions|rightconditions|rightConditions';
            dataTransNames{iTask} = 'left&right';
        otherwise
            dataFieldNames{iTask} = 'conditions|data|detail|datail|llog'; % Note '|' is used for special issue: modification occured.
    end
end
dataSettings = table(taskIDs, dataFieldNames, dataTransNames);
% get the recorded data and do some transformations.
for itask = 1:length(taskIDs)
    taskID = taskIDs(itask);
    taskRec = records(ismember(records.(idvar), taskID), :);
    for iEntry = 1:height(taskRec)
        dataPar = taskRec.dataPar{iEntry};
        dataNames = fieldnames(dataPar);
        % pull out the 'params' field values as data if existed
        if ismember(paraVar, dataNames)
            dataPar   = dataPar.(paraVar);
            dataNames = fieldnames(dataPar);
        end
        % remove empty fields from structure
        rmfields  = dataNames(structfun(@(val) ...
            isempty(val) || (isnumeric(val) && val == 0), dataPar));
        dataPar   = rmfield(dataPar, rmfields);
        dataNames = setdiff(dataNames, rmfields);
        % pull out main raw data and store it in conditions
        dataSetting  = dataSettings(ismember(dataSettings.taskIDs, taskID), :);
        curDataField = dataSetting.dataFieldNames{:};
        curDataTrans = dataSetting.dataTransNames{:};
        curDataConds = cellfun(@(str) strsplit(str, '|'), strsplit(curDataField, '&'), ...
            'UniformOutput', false);
        curDataField = cellfun(@(strs) dataNames(ismember(dataNames, strs)), curDataConds, ...
            'UniformOutput', false);
        curDataTrans = strsplit(curDataTrans, '&');
        if ~any(cellfun(@isempty, curDataField))
            dataRawStr = cellfun(@(field) dataPar.(field{:}), curDataField, 'UniformOutput', false);
        else
            fprintf(logfile, 'The field specified not found/not normal in row %d.\n', iEntry);
            dataRawStr = repmat({''}, size(curDataField));
        end
        if ~any(cellfun(@isempty, curDataTrans))
            taskRec.conditions{iEntry} = strjoin(strcat(curDataTrans, '(', dataRawStr, ')'));
        else
            taskRec.conditions{iEntry} = dataRawStr{:};
        end
        % deal with special variables
        if isfield(dataPar, spVar) && ~isempty(dataPar.(spVar))
            taskRec.alltime(iEntry) = dataPar.allTime;
        end
        if isfield(dataPar, 'sdk')
            sdkStr = jsondecode(dataPar.sdk);
            if isfield(sdkStr, spVar)
                taskRec.alltime(iEntry) = sdkStr.allTime;
            end
        end
    end
    taskOutVars = outVars;
    if all(isnan(taskRec.alltime))
        taskOutVars = setdiff(taskOutVars, 'alltime');
    end
    outRecords = taskRec(:, ismember(taskRec.Properties.VariableNames, taskOutVars));
    writetable(outRecords, fullfile(resfolder, [num2str(taskID), '.txt']), ...
        'QuoteStrings', true, 'Delimiter', '\t', 'Encoding', 'UTF-8')
end
fprintf('Now move the old file to obsolete directory...\n')
obsolDir = 'obsolete';
if ~exist(obsolDir, 'dir'), mkdir(obsolDir); end
movefile(origfilename, obsolDir)
fprintf('Done!\n')
fclose(logfile);
