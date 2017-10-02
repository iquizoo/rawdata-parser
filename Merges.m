function [indices, results, status, realMetavarNames] = Merges(resdata, varargin)
%MERGES merges all the results obtained data.
%   INDICES = MERGES(RESDATA) merges the resdata according to userId, and
%   some information, e.g., gender, school, grade, is also merged according
%   to some arbitrary principle.
%
%   [INDICES, RESULTS] = MERGES(RESDATA) also merges all the analysis
%   results.
%
%   [INDICES, RESULTS, STATUS] = MERGES(RESDATA) also merges task status.
%   Cheat sheet: 0 -> no data; 1 -> data valid; -1 -> data invalid (to be
%   exact, meta information found, but data appears NaN).
%
%   [INDICES, RESULTS, STATUS, METAVARS] = MERGES(RESDATA) adds metavar
%   names as an output.
%
%   See also PREPROC, PROC.

% start stopwatch.
tic
% open a log file
logfid = fopen('merge(AutoGen).log', 'a');
fprintf(logfid, '[%s] Begin merging.\n', datestr(now));

% add helper functions folder
HELPERFUNPATH = 'scripts';
addpath(HELPERFUNPATH);

% parse input arguments.
par = inputParser;
addParameter(par, 'TaskNames', '', @(x) ischar(x) | iscellstr(x) | isstring(x) | isnumeric(x))
parse(par, varargin{:});
taskInputNames = par.Results.TaskNames;
% set to merge all the tasks if not specified
if isempty(taskInputNames) || all(ismissing(taskInputNames))
    fprintf('Detected no valid tasks are specified, will continue to process all tasks.\n');
    taskInputNames = resdata.TaskID;
end

% load settings, parameters, task names, etc.
CONFIGPATH = 'config';
READPARAS = {'FileEncoding', 'UTF-8', 'Delimiter', '\t'};
taskNameStore = readtable(fullfile(CONFIGPATH, 'taskname.csv'), READPARAS{:});
% the unique key variable name
KEYMETAVARNAME = 'userId';
% participate time
TIMEMETAVARNAME = 'createTime';
% all the possible metavars
METAVARNAMES = {'userId', 'name', 'sex', 'school', 'grade', 'cls', 'birthDay'};
% classes of metadata variables
METAVARCLSES = {'numeric', 'cellstr', 'cellstr', 'cellstr', 'cellstr', 'cellstr', 'datetime'};

% input task name validation and name transformation
[~, ~, taskIDNames] = tasknamechk(taskInputNames, taskNameStore, resdata.TaskID);
% count the number of tasks to merge
taskIDNames4Merge = unique(taskIDNames, 'stable');
nTasks = length(taskIDNames4Merge);

% remove tasks not to merge
resdata(~ismember(resdata.TaskIDName, taskIDNames4Merge), :) = [];

% metadata transformation (type conversion) and merge (different tasks)
if nTasks > 0
    fprintf('Now trying to merge the metadata. Please wait...\n')
    % check metadata variables and change them to legal ones
    dataVarNames = cellfun(@(tbl) tbl.Properties.VariableNames, resdata.Data, ...
        'UniformOutput', false);
    dataVarNames = unique(cat(2, dataVarNames{:}));
    % change metavars and classes to real ones
    [realMetavarNames, iMetavar] = intersect(METAVARNAMES, dataVarNames, 'stable');
    realMetavarsClass = METAVARCLSES(iMetavar);

    % impute missing real metadata and merge metadata from all tasks
    for iTask = 1:height(resdata)
        curTaskData = resdata.Data{iTask};
        curTaskVars = curTaskData.Properties.VariableNames;
        curTaskMetaExisted = ismember(realMetavarNames, curTaskVars);
        if ~all(curTaskMetaExisted)
            % get all the missing meta variables index as a row vector
            curTaskMetaMissIdx = find(~curTaskMetaExisted);
            curTaskMetaMissIdx = reshape(curTaskMetaMissIdx, 1, length(curTaskMetaMissIdx));
            for iMetavar = curTaskMetaMissIdx
                % impute metadata as missing values
                curMetavarName = realMetavarNames{iMetavar};
                curMetavarClass = realMetavarsClass{iMetavar};
                switch curMetavarClass
                    case 'numeric'
                        curTaskData.(curMetavarName) = nan(height(curTaskData), 1);
                    case 'cellstr'
                        curTaskData.(curMetavarName) = repmat({''}, height(curTaskData), 1);
                    case 'datetime'
                        curTaskData.(curMetavarName) = NaT(height(curTaskData), 1);
                end
            end
        end
        resdata.Data{iTask} = curTaskData;
    end
    % merge metadata from all the tasks
    resMetadata = cellfun(@(tbl) tbl(:, realMetavarNames), resdata.Data, ...
        'UniformOutput', false);
    resMetadata = cat(1, resMetadata{:});

    % check all the real metadata
    fprintf('Now do some transformation to metadata, e.g., change Chinese numeric string to arabic.\n')
    for iMetavar = 1:length(realMetavarNames)
        initialVars = who;
        curMetavarName = realMetavarNames{iMetavar};
        curMetadata = resMetadata.(curMetavarName);
        metaTypeWarnTransFailed = false;
        switch curMetavarName
            case {'name', 'sex', 'school'}
                % remove spaces in the names because they are in Chinese
                curMetadata = regexprep(curMetadata, '\s+', '');
            case {'grade', 'cls'}
                % find the string and numeric metadata locations
                cellstrLoc = cellfun(@ischar, curMetadata);
                cellnumLoc = cellfun(@isnumeric, curMetadata);
                % transform numeric type to string type
                curMetadata(cellnumLoc) = cellfun(@num2str, curMetadata(cellnumLoc), ...
                    'UniformOutput', false);
                % transform non-string/numeric metadata to empty string
                curMetadata(~cellstrLoc & ~cellnumLoc) = {''};

                % try to transform non-digit string to digit string
                nondigitLoc = cellfun(@(str) ~all(isstrprop(str, 'digit')), curMetadata);
                nondigitMetadata = curMetadata(nondigitLoc);
                transMetadata = cellfun(@cn2digit, nondigitMetadata, 'UniformOutput', false);
                nanTransLoc = cellfun(@isnan, transMetadata);
                if any(nanTransLoc)
                    % some entries cannot be correctly transformed
                    metaTypeWarnTransFailed = true;
                    msg = 'Failing: string to numeric, will use raw string for NaN locations.';
                end
                transMetadata(nanTransLoc) = nondigitMetadata(nanTransLoc);
                transMetadata(~nanTransLoc) = cellfun(@num2str, transMetadata(~nanTransLoc), ...
                    'UniformOutput', false);
                curMetadata(nondigitLoc) = transMetadata;
        end
        % display warning/error message in case failed
        if metaTypeWarnTransFailed
            warning('UDF:MERGES:MetaTransFailed', ...
                'Some cases of `%s` metadata failed to transform. %s', ...
                curMetavarName, msg)
            fprintf(logfid, ...
                '[%s] Some cases of `%s` metadata failed to transform. %s\n', ...
                datestr(now), curMetavarName, msg);
        end
        resMetadata.(curMetavarName) = curMetadata;
        clearvars('-except', initialVars{:})
    end

    % remove repetitions in the merged metadata
    fprintf('Now remove repetitions in the metadata. Probably will takes some time.\n')
    % remove complete missing metadata variables
    incompAllMetaColIdx = all(ismissing(resMetadata), 1);
    realMetavarNames(incompAllMetaColIdx) = [];
    realMetavarsClass(incompAllMetaColIdx) = [];
    resMetadata(:, incompAllMetaColIdx) = [];
    nRealMetavars = length(realMetavarNames);
    % remove repetions not considering NaNs, NaTs
    resMetadata = unique(resMetadata);
    % will try to merge incomlete metadata
    incompAnyMetaRowIdx = any(ismissing(resMetadata), 2);
    compMetadata = resMetadata(~incompAnyMetaRowIdx, :);
    incompMetadata = resMetadata(incompAnyMetaRowIdx, :);
    % if there are incomplete meta data, merge them by key variable
    if ~isempty(incompMetadata)
        % preallocate a table for all the incomplete metadata cases
        incompKeys = unique(incompMetadata.(KEYMETAVARNAME));
        nIncmpKeys = length(incompKeys);
        incompMetaMrg = cell(nIncmpKeys, nRealMetavars);
        for iMetavar = 1:nRealMetavars
            curMetavarClass = realMetavarsClass{iMetavar};
            switch curMetavarClass
                case 'numeric'
                    incompMetaMrg(:, iMetavar) = {nan};
                case 'cellstr'
                    incompMetaMrg(:, iMetavar) = {{''}};
                case 'datetime'
                    incompMetaMrg(:, iMetavar) = {NaT};
            end
        end
        incompMetaMrg = cell2table(incompMetaMrg, 'VariableNames', realMetavarNames);
        incompMetaMrg.(KEYMETAVARNAME) = incompKeys;
        % incomplete data missed in one task, recovered from another task
        for iIncomp = 1:length(incompKeys)
            % try to recover each piece of metadate for each user
            curIncompKey = incompKeys(iIncomp);
            curKeyMetadata = incompMetadata(incompMetadata.userId == curIncompKey, :);
            for iMetavar = 1:nRealMetavars
                curMetavarName = realMetavarNames{iMetavar};
                % do not need to care about key meta here
                if ~strcmp(curMetavarName, KEYMETAVARNAME)
                    curUsrSnglMetadata = curKeyMetadata.(curMetavarName);
                    curUsrSnglMetaMSPattern = ismissing(curUsrSnglMetadata);
                    if ~all(curUsrSnglMetaMSPattern)
                        curUsrSnglMetadata(curUsrSnglMetaMSPattern) = [];
                        curUsrSnglMetaExtract = unique(curUsrSnglMetadata);
                        if numel(curUsrSnglMetaExtract) > 1
                            % inconsistent metadata found, throw a warning
                            warning('UDF:MERGES:INCONSISTENTMETADATA', ...
                                ['Mutiple inconsistent metadata found for user %d on variable %s.', ...
                                'Will use the first only.'], ...
                                curIncompKey, curMetavarName);
                            fprintf(logfid, '[%s] Mutiple inconsistent metadata found for user %d on variable %s.\n', ...
                                datestr(now), curIncompKey, curMetavarName);
                            curUsrSnglMetaExtract = curUsrSnglMetaExtract(1);
                        end
                        incompMetaMrg{iIncomp, curMetavarName} = curUsrSnglMetaExtract;
                    end
                end
            end
        end
    else
        incompMetaMrg = incompMetadata;
    end
    mrgmeta = sortrows([compMetadata; incompMetaMrg], KEYMETAVARNAME);

    % transform metadata type.
    for iMetavar = 1:length(realMetavarNames)
        curMetavarName = realMetavarNames{iMetavar};
        curMetavarData = mrgmeta.(curMetavarName);
        switch curMetavarName
            case {'name', 'school'}
                if ~verLessThan('matlab', '9.1')
                    % change name/school cell string to string array.
                    curMetavarData = string(curMetavarData);
                end
            case 'grade'
                % it is ordinal for grades
                curMetavarData = categorical(curMetavarData, 'ordinal', true);
            case 'cls'
                % classes are not ordinal
                curMetavarData = categorical(curMetavarData);
            case 'sex'
                % sex is also a nominal variable
                curMetavarData = categorical(curMetavarData);
        end
        mrgmeta.(curMetavarName) = curMetavarData;
    end
else
    realMetavarNames = {};
    mrgmeta = table;
end

% get all the test kinds, test and retest
testKinds = {'test', 'retest'};
testOccurs = 1:2;
% save metadata to all the output variables
% ultimate index
indices.(testKinds{1}) = mrgmeta;
indices.(testKinds{2}) = mrgmeta;
% calculation status
status.(testKinds{1}) = mrgmeta;
status.(testKinds{2}) = mrgmeta;
% calculation results
results.(testKinds{1}) = mrgmeta;
results.(testKinds{2}) = mrgmeta;
% variables to merge
indiceVarName = 'index';
statusVarName = 'status';
% notation message
fprintf('Now trying to merge all the data task by task. Please wait...\n')
dispInfo = '';
% data transformation and merge
for imrgtask = 1:nTasks
    initialVars = who;
    % get the current task name
    curTaskIDName = taskIDNames4Merge{imrgtask};
    % display processing information
    fprintf(repmat('\b', 1, length(dispInfo)));
    dispInfo = sprintf('Now merging task: %s(%d/%d).\n', curTaskIDName, imrgtask, nTasks);
    fprintf(dispInfo);

    % extract the data of current task
    curTaskData = resdata.Data(ismember(resdata.TaskIDName, curTaskIDName), :);
    % gather when multiple versions found
    curTaskData = cat(1, curTaskData{:});
    % remove empty entries
    curTaskData(cellfun(@isempty, curTaskData.res), :) = [];

    % extract results from data
    curTaskRes = cat(1, curTaskData.res{:});
    % get the result variable names
    curTaskResVarNames = curTaskRes.Properties.VariableNames;
    % join results to the right of data
    curTaskData = [curTaskData, curTaskRes]; %#ok<AGROW>

    % get the occur time for all the subjects
    if ~isempty(curTaskResVarNames)
        % separte data according occurrences
        occurrences = grpstats(curTaskData, KEYMETAVARNAME, 'numel', 'DataVars', KEYMETAVARNAME);
        occurs = ones(height(curTaskData), 1);
        if ~all(occurrences.GroupCount == 1)
            curTaskSubIDs = curTaskData.(KEYMETAVARNAME);
            repeatIDs = unique(occurrences.(KEYMETAVARNAME)(occurrences.GroupCount > 1));
            for irepeat = 1:length(repeatIDs)
                curRepeatID = repeatIDs(irepeat);
                curIDLoc = curTaskSubIDs == curRepeatID;
                if ismember(TIMEMETAVARNAME, dataVarNames)
                    % use participate time to set the occur time
                    [~, ~, occurs(curIDLoc)] = unique(curTaskData.(TIMEMETAVARNAME)(curIDLoc));
                else
                    % use the raw occur order to set the occur time
                    occurs(curIDLoc) = 1:sum(curIDLoc);
                end
            end
        end
        % separate data into corresponding test kind
        for iTestKind = 1:length(testKinds)
            testKind = testKinds{iTestKind};
            testKindTaskData = curTaskData(occurs == testOccurs(iTestKind), :);

            % get the indices by outer join
            indices.(testKind) = outerjoin(indices.(testKind), testKindTaskData, ...
                'Keys', KEYMETAVARNAME, ...
                'MergeKeys', true, ...
                'RightVariables', indiceVarName);
            % rename `indice` variable as the task ID name
            indices.(testKind).Properties.VariableNames{indiceVarName} = curTaskIDName;

            % get the status by outer join
            status.(testKind) = outerjoin(status.(testKind), testKindTaskData, ...
                'Keys', KEYMETAVARNAME, ...
                'MergeKeys', true, ...
                'RightVariables', statusVarName);
            % rename `status` variable as the task ID name
            status.(testKind).Properties.VariableNames{statusVarName} = curTaskIDName;

             % get the results by outer join
            results.(testKind) = outerjoin(results.(testKind), testKindTaskData, ...
                'Keys', KEYMETAVARNAME, ...
                'MergeKeys', true, ...
                'RightVariables', curTaskResVarNames);
            % add the task ID name to  reults variable to separate
            results.(testKind).Properties.VariableNames(curTaskResVarNames)= ...
                strcat(curTaskIDName, '_', curTaskResVarNames);
        end
    end
    clearvars('-except', initialVars{:});
end
% get all the resulting structures.
usedTimeSecs = toc;
usedTimeHuman = seconds2human(usedTimeSecs, 'full');
fprintf('Congratulations! Data of %d task(s) merged completely this time.\n', nTasks);
fprintf('Returning without error!\nTotal time used: %s\n', usedTimeHuman);
fprintf(logfid, '[%s] Completed merging without error.\n', datestr(now));
fclose(logfid);
rmpath(HELPERFUNPATH)
