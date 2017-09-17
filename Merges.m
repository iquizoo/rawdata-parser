function [indicesStruct, mrgdataStruct, taskstatStruct, realMetavarsName] = Merges(resdata, varargin)
%MERGES merges all the results obtained data.
%   MRGDATA = MERGES(RESDATA) merges the resdata according to userId, and
%   some information, e.g., gender, school, grade, is also merged according
%   to some arbitrary principle.
%
%   [MRGDATA, SCORES] = MERGES(RESDATA) also merges scores into the result,
%   the regulation of which is from Prof. He.
%
%   [MRGDATA, SCORES, INDICES] = MERGES(RESDATA) also merges indices into
%   the result, which are regulated by Prof. Xue.
%
%   [MRGDATA, SCORES, INDICES, TASKSTAT] = MERGES(RESDATA) gets the status
%   of each task. Cheat sheet: 0 -> no data; 1 -> data valid; -1 -> data
%   invalid (to be exact, meta information found, but data appears NaN).
%
%   See also PREPROC, PROC.

% start stopwatch.
tic
% open a log file
logfid = fopen('merge(AutoGen).log', 'a');
fprintf(logfid, '[%s] Begin merging.\n', datestr(now));

% add helper functions folder
helperFunPath = 'utilis';
addpath(helperFunPath);

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
configpath = 'config';
readparas = {'FileEncoding', 'UTF-8', 'Delimiter', '\t'};
taskNameStore = readtable(fullfile(configpath, 'taskname.csv'), readparas{:});
% the unique key variable name
keyMetavarName = 'userId';
% all the possible metavars
metavarsName = {'userId', 'name', 'sex', 'school', 'grade', 'cls', 'birthDay'};
% some metadata variables could have aliases, use `|` to separate
metavarsOpts = {'userId', 'name', 'gender|sex', 'school', 'grade', 'cls', 'birthDay'};
% classes of metadata variables
metavarsClass = {'numeric', 'cell', 'cell', 'cell', 'numeric', 'numeric', 'datetime'};


% input task name validation and name transformation
[taskInputNames, ~, taskIDNames] = tasknamechk(taskInputNames, taskNameStore, resdata.TaskID);
% count the number of tasks to merge
nTasks = length(taskInputNames);

% remove tasks not to merge
resdata(~ismember(resdata.TaskIDName, taskIDNames), :) = [];

% metadata transformation (type conversion) and merge (different tasks)
if nTasks > 0
    fprintf('Now trying to merge the metadata. Please wait...\n') 
    % check metadata variables and change them to legal ones
    realMetavarsName = []; % store all the metavars used in any of the tasks
    for iTask = 1:height(resdata)
        curTaskData = resdata.Data{iTask};
        curTaskVars = curTaskData.Properties.VariableNames;
        for iMetavarOpts = 1:length(metavarsOpts)
            % get the real metadata varname
            curMetavarOpts = split(metavarsOpts{iMetavarOpts}, '|');
            curMetavarName = metavarsName{iMetavarOpts};
            % real location of current metadata variable
            curMetavarRealLoc = ismember(curTaskVars, ...
                intersect(curMetavarOpts, curTaskVars));
            if any(curMetavarRealLoc)
                % when the current metadata is included, name it legally
                curTaskData.Properties.VariableNames{curMetavarRealLoc} = curMetavarName;
            end
        end
        realMetavarsName = union(realMetavarsName, curTaskData.Properties.VariableNames);
        resdata.Data{iTask} = curTaskData;
    end
    % change metavars and classes to real ones
    [realMetavarsName, iMetavar] = intersect(metavarsName, realMetavarsName, 'stable');
    realMetavarsClass = metavarsClass(iMetavar);

    % impute missing real metadata and merge metadata from all tasks
    for iTask = 1:height(resdata)
        curTaskData = resdata.Data{iTask};
        curTaskVars = curTaskData.Properties.VariableNames;
        curTaskMetaExisted = ismember(realMetavarsName, curTaskVars);
        if ~all(curTaskMetaExisted)
            % get all the missing meta variables index as a row vector
            curTaskMetaMissIdx = find(~curTaskMetaExisted);
            curTaskMetaMissIdx = reshape(curTaskMetaMissIdx, 1, length(curTaskMetaMissIdx));
            for iMetavar = curTaskMetaMissIdx
                % impute metadata as missing values
                curMetavarName = realMetavarsName{iMetavar};
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
    resMetadata = cellfun(@(tbl) tbl(:, realMetavarsName), resdata.Data, ...
        'UniformOutput', false);
    resMetadata = cat(1, resMetadata{:});

    % check all the real metadata 
    fprintf('Now do some transformation to metadata, e.g., change Chinese numeric string to arabic.\n')
    for iMetavar = 1:length(realMetavarsName)
        initialVars = who;
        curMetavarName = realMetavarsName{iMetavar};
        curMetavarClass = realMetavarsClass{iMetavar};
        curMetadata = resMetadata.(curMetavarName);
        curMetadataClass = class(curMetadata);
        if ~isa(curMetadata, curMetavarClass)
            warning('UDF:MERGES:MetaTypeMismatch', ...
                'The type for metadata variable %s is %s, and mismatches the supposed type %s.', ...
                curMetavarName, curMetadataClass, curMetavarClass);
            fprintf(logfid, ...
                '[%s] The type for metadata variable %s is %s, and mismatches the supposed type %s.\n', ...
                datestr(now), curMetavarName, curMetadataClass, curMetavarClass);
            fprintf('Try to transform mismatched metadata.\n')
            metaTypeMismatch = true;
        else
            metaTypeMismatch = false;
        end
        metaTypeWarnTransFailed = false;
        metaTypeErrInvalid = false;
        switch curMetavarName
            case 'userId'
                if metaTypeMismatch
                    % if stored as cellstr, transform to double
                    if iscellstr(curMetadata)
                        curMetadata = str2double(curMetadata);
                        if any(isnan(curMetadata))
                            metaTypeWarnTransFailed = true;
                        end
                    else % otherwise throw an error
                        metaTypeErrInvalid = true;
                    end
                end
            case {'name', 'sex', 'school'}
                if metaTypeMismatch
                    if isnumeric(curMetadata)
                        curMetadata = cellfun(@num2str, num2cell(curMetadata), ...
                            'UniformOutput', false);
                    elseif ischar(curMetadata)
                        curMetadata = num2cell(curMetadata, 2);
                    else
                        metaTypeErrInvalid = true;
                    end
                end
                % remove spaces in the names because they are in Chinese
                curMetadata = regexprep(curMetadata, '\s+', '');
            case {'grade', 'cls'}
                if metaTypeMismatch
                    if iscellstr(curMetadata)
                        cellMetadata = curMetadata;
                        % arabic numeric string to arabic number
                        matMetadata = str2double(cellMetadata);
                        % Chinese numeic string to arabic number
                        matMetadata(isnan(matMetadata)) = ...
                            cellfun(@cn2digit, cellMetadata(isnan(matMetadata)));
                        if any(isnan(matMetadata))
                            metaTypeWarnTransFailed = true;
                        end
                        curMetadata = matMetadata;
                    else
                        metaTypeErrInvalid = true;
                    end
                end
            case 'datetime'
                if metaTypeMismatch
                    try
                        curMetadata = datetime(curMetadata);
                    catch
                        metaTypeWarnTransFailed = true;
                        curMetadata = NaT(size(curMetadata));
                    end
                end
        end
        % display warning/error message in case failed
        if metaTypeWarnTransFailed
            warning('UDF:MERGES:MetaTransFailed', ...
                'Some cases of metadata variable %s failed to transform.', ...
                curMetavarName)
            fprintf(logfid, ...
                '[%s] Some cases of metadata variable %s failed to transform.\n', ...
                datestr(now), curMetavarName);
        end
        if metaTypeErrInvalid
            fprintf(logfid, ...
                '[%s] Not valid type for metadata variable %s, the program will terminate.\n', datestr(now), curMetavarName);
            fclose(logfid);
            error('UDF:MERGES:MetaTypeInvalid', ...
                'Not a valid type for metadata variable %s', curMetavarName)
        end
        resMetadata.(curMetavarName) = curMetadata;
        clearvars('-except', initialVars{:})
    end

    % remove repetitions in the merged metadata
    fprintf('Now remove repetitions in the metadata. Probably will takes some time.\n')
    % remove complete missing metadata variables
    incompAllMetaColIdx = all(ismissing(resMetadata), 1);
    realMetavarsName(incompAllMetaColIdx) = [];
    realMetavarsClass(incompAllMetaColIdx) = [];
    resMetadata(:, incompAllMetaColIdx) = [];
    nRealMetavars = length(realMetavarsName);
    % remove repetions not considering NaNs, NaTs
    resMetadata = unique(resMetadata);
    % will try to merge incomlete metadata
    incompAnyMetaRowIdx = any(ismissing(resMetadata), 2);
    compMetadata = resMetadata(~incompAnyMetaRowIdx, :);
    incompMetadata = resMetadata(incompAnyMetaRowIdx, :);
    % if there are incomplete meta data, merge them by key variable
    if ~isempty(incompMetadata)
        % preallocate a table for all the incomplete metadata cases
        incompKeys = unique(incompMetadata.(keyMetavarName));
        nIncmpKeys = length(incompKeys);
        incompMetaMrg = cell(nIncmpKeys, nRealMetavars);
        for iMetavar = 1:nRealMetavars
            curMetavarClass = realMetavarsClass{iMetavar};
            switch curMetavarClass
                case 'numeric'
                    incompMetaMrg(:, iMetavar) = {nan};
                case 'cell'
                    incompMetaMrg(:, iMetavar) = {{''}};
                case 'datetime'
                    incompMetaMrg(:, iMetavar) = {NaT};
            end
        end
        incompMetaMrg = cell2table(incompMetaMrg, 'VariableNames', realMetavarsName);
        incompMetaMrg.(keyMetavarName) = incompKeys;
        % add existing info to the preallocated metadata
        for iIncomp = 1:length(incompKeys)
            curIncompKey = incompKeys(iIncomp);
            curKeyMetadata = incompMetadata(incompMetadata.userId == curIncompKey, :);
            for iMetavar = 1:nRealMetavars
                curMetavarName = realMetavarsName{iMetavar};
                if ~strcmp(curMetavarName, keyMetavarName)
                    curUsrSnglMetadata = curKeyMetadata.(curMetavarName);
                    curUsrSnglMetaMSPattern = ismissing(curUsrSnglMetadata);
                    if ~all(curUsrSnglMetaMSPattern)
                        curUsrSnglMetadata(curUsrSnglMetaMSPattern) = [];
                        curUsrSnglMetaExtract = unique(curUsrSnglMetadata);
                        % choose the first entry if multiple extracted data
                        incompMetaMrg{iIncomp, curMetavarName} = curUsrSnglMetaExtract(1);
                    end
                end
            end
        end
    end
    mrgmeta = sortrows([compMetadata; incompMetaMrg], keyMetavarName);
    
    % transform metadata type.
    for iMetavar = 1:length(realMetavarsName)
        curMetavarName = realMetavarsName{iMetavar};
        curMetavarData = mrgmeta.(curMetavarName);
        switch curMetavarName
            case {'name', 'school'}
                if ~verLessThan('matlab', '9.1')
                    % change name/school cell string to string array.
                    curMetavarData = string(curMetavarData);
                end
            case {'grade', 'cls'}
                % it is ordinal for grades.
                curMetavarData = categorical(curMetavarData, 'ordinal', true);
            case 'sex'
                curMetavarData = categorical(curMetavarData);
        end
        mrgmeta.(curMetavarName) = curMetavarData;
    end
else
    realMetavarsName = {};
    mrgmeta = table;
end

% preallocate for the output.
testIndices = mrgmeta;
testTaskstat = mrgmeta;
testMrgdata = mrgmeta;
% for the retest
retestIndices = mrgmeta;
retestTaskstat = mrgmeta;
retestMrgdata = mrgmeta;
% notation message
fprintf('Now trying to merge all the data task by task. Please wait...')
dispInfo = '';
subDispInfo = '';
nsubj = height(mrgmeta);
% data transformation and merge
for imrgtask = 1:nTasks
    initialVars = who;
    curTaskIDName = taskIDNames{imrgtask};
    fprintf(repmat('\b', 1, length(subDispInfo)));
    fprintf(repmat('\b', 1, length(dispInfo)));
    dispInfo = sprintf('\nNow merging task: %s(%d/%d).\n', curTaskIDName, imrgtask, nTasks);
    fprintf(dispInfo);
    % extract the data of current task.
    curTaskData = resdata.Data(ismember(resdata.TaskIDName, curTaskIDName), :);
    curTaskData = cat(1, curTaskData{:});
    curTaskData.res = cat(1, curTaskData.res{:});
    curTaskResVars = curTaskData.res.Properties.VariableNames;
    if ~isempty(curTaskResVars)
        % preallocate
        testTaskstat.(curTaskIDName) = zeros(nsubj, 1);
        testIndices.(curTaskIDName) = nan(nsubj, 1);
        retestTaskstat.(curTaskIDName) = zeros(nsubj, 1);
        retestIndices.(curTaskIDName) = nan(nsubj, 1);
        %Use the taskIDName as the variable name precedence.
        curTaskOutVars = strcat(curTaskIDName, '_', curTaskResVars);
        testMrgdata = [testMrgdata, array2table(nan(nsubj, length(curTaskOutVars)), 'VariableNames', curTaskOutVars)]; %#ok<*AGROW>
        retestMrgdata = [retestMrgdata, array2table(nan(nsubj, length(curTaskOutVars)), 'VariableNames', curTaskOutVars)];
        subDispInfo = '';
        for isubj = 1:nsubj
            fprintf(repmat('\b', 1, length(subDispInfo)));
            subDispInfo = sprintf('Subject %d/%d.', isubj, nsubj);
            fprintf(subDispInfo);
            %Missing/not measured -> 0; OK -> 1; Measured but not valid -> -1.
            curID      = testTaskstat.userId(isubj);
            curIDloc   = find(ismember(curTaskData.userId, curID));
            curIDnPart = length(curIDloc);
            curSubTaskData = curTaskData(curIDloc, :);
            % find the entry of earlier date.
            createTimeVar = intersect(curSubTaskData.Properties.VariableNames, {'createDate', 'createTime'});
            [~, ind] = sort(curSubTaskData.(createTimeVar{:}));
            if curIDnPart > 2
                fprintf(logfid, strcat('[%s] More than two (%d) test phases found for subject ID: %d, in task: %s. ', ...
                    'Will try to remain the earlist two only.\n'), datestr(now), curIDnPart, curID, curTaskIDName);
            end
            if curIDnPart > 0
                if ismember(realMetavarsName, 'school')
                    %The logic here is, if there is no school information
                    %for current observation, set the observation as
                    %missing data; if there is school information, if there
                    %is any invalid value, set the observation as invalid.
                    testTaskstat{isubj, curTaskIDName} = ~isundefined(testTaskstat(isubj, :).school) * ...
                        (-2 * (any(isnan(curSubTaskData.res{ind(1), :}))) + 1);
                else
                    testTaskstat{isubj, curTaskIDName} = (-2 * (any(isnan(curSubTaskData.res{ind(1), :}))) + 1);
                end
                testIndices{isubj, curTaskIDName} = curSubTaskData.index(ind(1));
                testMrgdata{isubj, curTaskOutVars} = curSubTaskData.res{ind(1), :};
            end
            if curIDnPart > 1
                if ismember(realMetavarsName, 'school')
                    %The logic here is the same as above.
                    retestTaskstat.(curTaskIDName)(isubj) = ...
                        ~isundefined(retestTaskstat(isubj, :).school) * ...
                        (-2 * (any(isnan(curSubTaskData.res{ind(2), :}))) + 1);
                else
                    retestTaskstat.(curTaskIDName)(isubj) = ...
                        (-2 * (any(isnan(curSubTaskData.res{ind(2), :}))) + 1);
                end
                retestIndices.(curTaskIDName)(isubj) = curSubTaskData.index(ind(2));
                retestMrgdata{isubj, curTaskOutVars} = curSubTaskData.res{ind(2), :};
            end
        end
    end
    clearvars('-except', initialVars{:});
end
% get all the resulting structures.
indicesStruct.test = testIndices;
indicesStruct.retest = retestIndices;
mrgdataStruct.test = testMrgdata;
mrgdataStruct.retest = retestMrgdata;
taskstatStruct.test = testTaskstat;
taskstatStruct.retest = retestTaskstat;
usedTimeSecs = toc;
usedTimeHuman = seconds2human(usedTimeSecs, 'full');
fprintf('\nCongratulations! Data of %d task(s) merged completely this time.\n', nTasks);
fprintf('Returning without error!\nTotal time used: %s\n', usedTimeHuman);
fprintf(logfid, '[%s] Completed merging without error.\n', datestr(now));
fclose(logfid);
rmpath(helperFunPath)
