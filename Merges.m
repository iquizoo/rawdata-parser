function [indicesStruct, mrgdataStruct, taskstatStruct, metavars] = Merges(resdata, varargin)
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

% load settings, parameters, task names, etc.
configpath = 'config';
readparas = {'FileEncoding', 'UTF-8', 'Delimiter', '\t'};
taskNameStore = readtable(fullfile(configpath, 'taskname.csv'), readparas{:});
schInfo = readtable(fullfile(configpath, 'schoolinfo.csv'), readparas{:});
grdInfo = readtable(fullfile(configpath, 'gradeinfo.csv'), readparas{:});
clsInfo = readtable(fullfile(configpath, 'clsinfo.csv'), readparas{:});
%Set the school information.
schMap = containers.Map(schInfo.SchoolName, schInfo.SchoolIDName);
%Set the grade information.
grdMap = containers.Map(grdInfo.GradeStr, grdInfo.Encode);
%Set the class information.
clsMap = containers.Map(clsInfo.ClsStr, clsInfo.Encode);

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

% input task name validation and name transformation
[taskInputNames, ~, taskIDNames] = tasknamechk(taskInputNames, taskNameStore, resdata.TaskID);

nTasks = length(taskInputNames);
% metadata transformation and merge
if nTasks > 0
    %Get the metadata. Not all of the variables in meta data block is
    %interested, so descard those of no interest. And then do some basic
    %transformation of meta data, e.g. school and grade.
    fprintf('Now trying to merge the metadata. Please wait...\n')
    %Use metavars to store all the variable names of meta data.
    varsOfChk = {'userId', 'name', 'gender|sex', 'school', 'grade', 'cls', 'birthDay'};
    metavars = {'userId', 'name', 'sex', 'school', 'grade', 'cls', 'birthDay'};
    varsOfChkClass = {'double', 'cell', 'cell', 'cell', 'cell', 'cell', 'datetime'};
    % get the real metavars for the data and change some vars to the legal
    % ones.
    dataMetaVars = [];
    for iTask = 1:height(resdata)
        curTaskData = resdata.Data{iTask};
        curTaskVars = curTaskData.Properties.VariableNames;
        for ivar = 1:length(varsOfChk)
            curVarOpts = split(varsOfChk{ivar}, '|');
            metavar = metavars{ivar};
            curVar = intersect(curVarOpts, curTaskVars);
            if ~isempty(curVar) %For better compatibility.
                curTaskData.Properties.VariableNames{ismember(curTaskVars, curVar)} = metavar;
            end
        end
        dataMetaVars = union(dataMetaVars, curTaskData.Properties.VariableNames);
        resdata.Data{iTask} = curTaskData;
    end
    [metavars, imeta] = intersect(metavars, dataMetaVars, 'stable');
    varsOfChkClass = varsOfChkClass(imeta);
    % change data in case of some loss of meta data.
    for iTask = 1:height(resdata)
        curTaskData = resdata.Data{iTask};
        curTaskVars = curTaskData.Properties.VariableNames;
        metavarsExistence = ismember(metavars, curTaskVars);
        if ~all(metavarsExistence)
            metavarNotExist = find(~metavarsExistence);
            for ivar = metavarNotExist
                metavar = metavars{ivar};
                metavarClass = varsOfChkClass{ivar};
                switch metavarClass
                    case 'double'
                        curTaskData.(metavar) = nan(height(curTaskData), 1);
                    case 'cell'
                        curTaskData.(metavar) = repmat({''}, height(curTaskData), 1);
                    case 'datetime'
                        curTaskData.(metavar) = NaT(height(curTaskData), 1);
                end
            end
        end
        resdata.Data{iTask} = curTaskData;
    end
    %Vertcat metadata.
    resMetadata = cellfun(@(tbl) tbl(:, ismember(tbl.Properties.VariableNames, metavars)), ...
        resdata.Data, 'UniformOutput', false);
    resMetadata = cat(1, resMetadata{:});
    %Check the following variables.
    fprintf('Now trying to modify metadata: gender, school, grade, cls. Change these variables to categorical data. Please wait...\n')
    chkVarsOfMetadata = intersect({'name', 'gender', 'sex', 'school', 'grade', 'cls'}, metavars, 'stable');
    for ivomd = 1:length(chkVarsOfMetadata)
        initialVars = who;
        cvomd = chkVarsOfMetadata{ivomd};
        numNaNLoc = cellfun(@(item) isnumeric(item) && isnan(item), resMetadata.(cvomd));
        numNotNaNloc = cellfun(@(item) isnumeric(item) && ~isnan(item), resMetadata.(cvomd));
        resMetadata.(cvomd)(numNaNLoc) = {''}; % number NaN to ''.
        resMetadata.(cvomd)(numNotNaNloc) = ...
            cellfun(@num2str, resMetadata.(cvomd)(numNotNaNloc), ... % number and not NaN to string.
            'UniformOutput', false);
        switch cvomd
            case 'name'
                % remove all of the spaces in the name string.
                resMetadata.name = regexprep(resMetadata.name, '\s+', '');
            case 'school'
                %Set those schools of no interest into empty string, so as to
                %be transformed into undefined.
                schOIloc = ismember(resMetadata.school, schInfo.SchoolName);
                if any(~schOIloc)
                    resMetadata.school(~schOIloc) = {''};
                end
                resMetadata.school(schOIloc) = ...
                    values(schMap, resMetadata.school(schOIloc));
            case 'grade'
                %Convert grade strings to numeric data.
                allGradeStr = resMetadata.grade;
                allGradeStr(~isKey(grdMap, allGradeStr)) = {''};
                resMetadata.grade = values(grdMap, allGradeStr);
            case 'cls'
                %Convert class strings to numeric data.
                allClsStr = resMetadata.cls;
                allClsStr(~isKey(clsMap, allClsStr)) = {''};
                resMetadata.cls = values(clsMap, allClsStr);
        end
        clearvars('-except', initialVars{:})
    end
    %Remove repetitions in the merged metadata according to the userId.
    fprintf('Now remove repetitions in the metadata. Probably will takes some time.\n')
    resMetadata = unique(resMetadata);
    if ~isempty(resMetadata)
        userId = unique(resMetadata.userId);
    else
        userId = [];
    end
    nsubj = length(userId);
    prealloCell = cell(nsubj, length(metavars));
    for imeta = 1:length(metavars)
        curMetaClass = varsOfChkClass{imeta};
        switch curMetaClass
            case 'double'
                prealloCell(:, imeta) = {nan};
            case 'cell'
                prealloCell(:, imeta) = {{''}};
            case 'datetime'
                prealloCell(:, imeta) = {NaT};
        end
    end
    mrgdata = cell2table(prealloCell, 'VariableNames', metavars);
    mrgdata.userId = userId;
    idInfo = '';
    for id = 1:length(userId)
        fprintf(repmat('\b', 1, length(idInfo)));
        idInfo = sprintf('Subject %d/%d.', id, length(userId));
        fprintf(idInfo);
        curId = userId(id);
        curIdMeta = resMetadata(resMetadata.userId == curId, :);
        for imeta = 1:length(metavars)
            curMetavar = metavars{imeta};
            curMetavarIdData = curIdMeta.(curMetavar);
            msPattern = ismissing(curMetavarIdData);
            if ~all(msPattern)
                curMetavarIdData(msPattern) = [];
                uniMetavarIdData = unique(curMetavarIdData);
                % choose the first entry of not empty meta data.
                mrgdata{id, curMetavar} = uniMetavarIdData(1);
            end
        end
    end
    % transform metadata type.
    for ivomd = 1:length(chkVarsOfMetadata)
        cvomd = chkVarsOfMetadata{ivomd};
        switch cvomd
            case {'name', 'school'}
                if ~verLessThan('matlab', '9.1')
                    % change name/school cell string to string array.
                    mrgdata.(cvomd) = string(mrgdata.(cvomd));
                end
            case 'grade'
                % it is ordinal for grades.
                mrgdata.(cvomd) = categorical(mrgdata.(cvomd), 'ordinal', true);
            otherwise
                mrgdata.(cvomd) = categorical(mrgdata.(cvomd));
        end
    end
else
    metavars = {};
    mrgdata = table;
end
% Preallocate for the output.
indices  = mrgdata;
% scores   = mrgdata;
taskstat = mrgdata; % Generate a table to store the completion status for each id and task.
% for the repetition test.
indicesRep  = mrgdata;
scoresRep   = mrgdata;
taskstatRep = mrgdata;
mrgdataRep  = mrgdata;
% notation message
fprintf('\nNow trying to merge all the data task by task. Please wait...')
dispInfo = '';
subDispInfo = '';
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
    % remove subjects without any results
    curTaskData(cellfun(@isempty, curTaskData.res), :) = [];
    curTaskData.res = cat(1, curTaskData.res{:});
    curTaskResVars = curTaskData.res.Properties.VariableNames;
    if ~isempty(curTaskResVars)
        % preallocate
        taskstat.(curTaskIDName) = zeros(nsubj, 1);
        indices.(curTaskIDName) = nan(nsubj, 1);
        taskstatRep.(curTaskIDName) = zeros(nsubj, 1);
        scoresRep.(curTaskIDName) = nan(nsubj, 1);
        indicesRep.(curTaskIDName) = nan(nsubj, 1);
        %Use the taskIDName as the variable name precedence.
        curTaskOutVars = strcat(curTaskIDName, '_', curTaskResVars);
        mrgdata = [mrgdata, array2table(nan(nsubj, length(curTaskOutVars)), 'VariableNames', curTaskOutVars)]; %#ok<*AGROW>
        mrgdataRep = [mrgdataRep, array2table(nan(nsubj, length(curTaskOutVars)), 'VariableNames', curTaskOutVars)];
        subDispInfo = '';
        for isubj = 1:nsubj
            fprintf(repmat('\b', 1, length(subDispInfo)));
            subDispInfo = sprintf('Subject %d/%d.', isubj, nsubj);
            fprintf(subDispInfo);
            %Missing/not measured -> 0; OK -> 1; Measured but not valid -> -1.
            curID      = taskstat.userId(isubj);
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
                if ismember(metavars, 'school')
                    %The logic here is, if there is no school information
                    %for current observation, set the observation as
                    %missing data; if there is school information, if there
                    %is any invalid value, set the observation as invalid.
                    taskstat{isubj, curTaskIDName} = ~isundefined(taskstat(isubj, :).school) * ...
                        (-2 * (any(isnan(curSubTaskData.res{ind(1), :}))) + 1);
                else
                    taskstat{isubj, curTaskIDName} = (-2 * (any(isnan(curSubTaskData.res{ind(1), :}))) + 1);
                end
                indices{isubj, curTaskIDName} = curSubTaskData.index(ind(1));
                mrgdata{isubj, curTaskOutVars} = curSubTaskData.res{ind(1), :};
            end
            if curIDnPart > 1
                if ismember(metavars, 'school')
                    %The logic here is the same as above.
                    taskstatRep.(curTaskIDName)(isubj) = ...
                        ~isundefined(taskstatRep(isubj, :).school) * ...
                        (-2 * (any(isnan(curSubTaskData.res{ind(2), :}))) + 1);
                else
                    taskstatRep.(curTaskIDName)(isubj) = ...
                        (-2 * (any(isnan(curSubTaskData.res{ind(2), :}))) + 1);
                end
                indicesRep.(curTaskIDName)(isubj) = curSubTaskData.index(ind(2));
                mrgdataRep{isubj, curTaskOutVars} = curSubTaskData.res{ind(2), :};
            end
        end
    end
    clearvars('-except', initialVars{:});
end
% get all the resulting structures.
indicesStruct.indices = indices;
indicesStruct.indicesRep = indicesRep;
mrgdataStruct.mrgdata = mrgdata;
mrgdataStruct.mrgdataRep = mrgdataRep;
taskstatStruct.taskstat = taskstat;
taskstatStruct.taskstatRep = taskstatRep;
usedTimeSecs = toc;
usedTimeHuman = seconds2human(usedTimeSecs, 'full');
fprintf('\nCongratulations! Data of %d task(s) merged completely this time.\n', nTasks);
fprintf('Returning without error!\nTotal time used: %s\n', usedTimeHuman);
fprintf(logfid, '[%s] Completed merging without error.\n', datestr(now));
fclose(logfid);
rmpath(helperFunPath)
