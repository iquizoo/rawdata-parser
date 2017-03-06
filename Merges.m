function [indicesStruct, scoresStruct, mrgdataStruct, taskstatStruct, metavars] = Merges(resdata, varargin)
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

%Start stopwatch.
tic
% Parse input arguments.
par = inputParser;
parNames   = {         'TaskNames'          };
parDflts   = {              [],             };
parValFuns = {@(x) ischar(x) | iscellstr(x) };
cellfun(@(x, y, z) addParameter(par, x, y, z), parNames, parDflts, parValFuns);
parse(par, varargin{:});
tasknames = par.Results.TaskNames;
%Log file.
logfid = fopen('mergeLog(AutoGen).log', 'w');
% check tasks existence.
tasks = unique(resdata.TaskIDName, 'stable');
if isempty(tasknames)
    tasknames = tasks;
end
tasknames = cellstr(tasknames);
taskExistence = ismember(tasknames, tasks);
if any(~taskExistence)
    fprintf('Oops! Data of these following tasks you specified are not found, will remove these tasks...\n');
    disp(tasknames(~taskExistence))
end
tasks4merge = tasknames(taskExistence);
nTasks = length(tasks4merge);
if nTasks > 0
    fprintf('Please wait, now reading tasks settings...\n');
    %Set the school information.
    schInfo = readtable('taskSettings.xlsx', 'Sheet', 'schoolinfo');
    schMap = containers.Map(schInfo.SchoolName, schInfo.SchoolIDName);
    %Set the grade information.
    grdInfo = readtable('taskSettings.xlsx', 'Sheet', 'gradeinfo');
    grdMap = containers.Map(grdInfo.GradeStr, grdInfo.Encode);
    %Set the class information.
    clsInfo = readtable('taskSettings.xlsx', 'Sheet', 'clsinfo');
    clsMap = containers.Map(clsInfo.ClsStr, clsInfo.Encode);
    fprintf('Reading done!\n')
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
        curTaskData = resdata.Data{iTask, :};
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
    end
    [metavars, imeta] = intersect(metavars, dataMetaVars, 'stable');
    varsOfChkClass = varsOfChkClass(imeta);
    % change data in case of some loss of meta data.
    for iTask = 1:height(resdata)
        curTaskData = resdata.Data{iTask, :};
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
        resdata.Data{iTask, :} = curTaskData;
    end
    %Vertcat metadata.
    resMetadata = cellfun(@(tbl) tbl(:, ismember(tbl.Properties.VariableNames, metavars)), ...
        resdata.Data, 'UniformOutput', false);
    dataMergeMetadata = cat(1, resMetadata{:});
    %Check the following variables.
    fprintf('Now trying to modify metadata: gender, school, grade, cls. Change these variables to categorical data. Please wait...\n')
    chkVarsOfMetadata = intersect({'name', 'gender', 'sex', 'school', 'grade', 'cls'}, metavars, 'stable');
    for ivomd = 1:length(chkVarsOfMetadata)
        initialVars = who;
        cvomd = chkVarsOfMetadata{ivomd};
        cVarNotCharLoc = cellfun(@(item) ~ischar(item) | isempty(item), dataMergeMetadata.(cvomd));
        if any(cVarNotCharLoc)
            dataMergeMetadata.(cvomd)(cVarNotCharLoc) = {''};
        end
        switch cvomd
            case 'name'
                % remove all of the spaces in the name string.
                dataMergeMetadata.name = regexprep(dataMergeMetadata.name, '\s+', '');
            case 'school'
                %Set those schools of no interest into empty string, so as to
                %be transformed into undefined.
                schOIloc = ismember(dataMergeMetadata.school, schInfo.SchoolName);
                if any(~schOIloc)
                    dataMergeMetadata.school(~schOIloc) = {''};
                end
                dataMergeMetadata.school(schOIloc) = ...
                    values(schMap, dataMergeMetadata.school(schOIloc));
            case 'grade'
                %Convert grade strings to numeric data.
                allGradeStr = dataMergeMetadata.grade;
                allGradeStr(~isKey(grdMap, allGradeStr)) = {''};
                dataMergeMetadata.grade = values(grdMap, allGradeStr);
            case 'cls'
                %Convert class strings to numeric data.
                allClsStr = dataMergeMetadata.cls;
                allClsStr(~isKey(clsMap, allClsStr)) = {''};
                dataMergeMetadata.cls = values(clsMap, allClsStr);
        end
        clearvars('-except', initialVars{:})
    end
    %Remove repetitions in the merged metadata according to the userId.
    fprintf('Now remove repetitions in the metadata. Probably will takes some time.\n')
    dataMergeMetadata = unique(dataMergeMetadata);
    if ~isempty(dataMergeMetadata)
        userId = unique(dataMergeMetadata.userId);
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
        idInfo = sprintf('Subject %d/%d.\n', id, length(userId));
        fprintf(idInfo);
        curId = userId(id);
        curIdMeta = dataMergeMetadata(dataMergeMetadata.userId == curId, :);
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
                % change name/school cell string to string array.
                mrgdata.(cvomd) = string(mrgdata.(cvomd));
            case 'grade'
                % it is ordinal for grades.
                mrgdata.(cvomd) = categorical(mrgdata.(cvomd), 'ordinal', true);
            otherwise
                mrgdata.(cvomd) = categorical(mrgdata.(cvomd));
        end
    end
else
    mrgdata = table;
end
% Preallocate for the output.
indices  = mrgdata;
scores   = mrgdata;
taskstat = mrgdata; % Generate a table to store the completion status for each id and task.
% for the repetition test.
indicesRep  = mrgdata;
scoresRep   = mrgdata;
taskstatRep = mrgdata;
mrgdataRep  = mrgdata;
%Merge data task by task.
fprintf('Now trying to merge all the data task by task. Please wait...\n')
dispInfo = '';
subDispInfo = '';
for imrgtask = 1:nTasks
    initialVars = who;
    curTaskIDName = tasks4merge{imrgtask};
    fprintf(repmat('\b', 1, length(subDispInfo)));
    fprintf(repmat('\b', 1, length(dispInfo)));
    dispInfo = sprintf('Now merging task: %s(%d/%d).\n', curTaskIDName, imrgtask, nTasks);
    fprintf(dispInfo);
    %Get the data of current task.
    curTaskData = resdata.Data(ismember(resdata.TaskIDName, curTaskIDName), :);
    curTaskData = cat(1, curTaskData{:});
    curTaskData.res = cat(1, curTaskData.res{:});
    curTaskResVars = curTaskData.res.Properties.VariableNames;
    if ~isempty(curTaskResVars)
        %Generate the tasks status, scores and performance indices matrices.
        taskstat.(curTaskIDName) = zeros(nsubj, 1);
        scores.(curTaskIDName) = nan(nsubj, 1);
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
            subDispInfo = sprintf('Subject %d/%d.\n', isubj, nsubj);
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
                fprintf(logfid, strcat('More than two (%d) test phases found for subject ID: %d, in task: %s. ', ...
                    'Will try to remain the earlist two only.\n'), curIDnPart, curID, curTaskIDName);
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
                scores{isubj, curTaskIDName} = curSubTaskData.score(ind(1));
                indices{isubj, curTaskIDName} = curSubTaskData.index(ind(1));
                mrgdata{isubj, curTaskOutVars} = curSubTaskData.res{ind(1), :};
            end
            if curIDnPart > 1
                if ismember(metavars, 'school')
                    %The logic here is the same as above.
                    taskstatRep.(curTaskIDName)(isubj) = ~isundefined(taskstatRep(isubj, :).school) * ...
                        (-2 * (any(isnan(curSubTaskData.res{ind(2), :}))) + 1);
                else
                    taskstatRep.(curTaskIDName)(isubj) = (-2 * (any(isnan(curSubTaskData.res{ind(2), :}))) + 1);
                end
                scoresRep.(curTaskIDName)(isubj) = curSubTaskData.score(ind(2));
                indicesRep.(curTaskIDName)(isubj) = curSubTaskData.index(ind(2));
                mrgdataRep{isubj, curTaskOutVars} = curSubTaskData.res{ind(2), :};
            end
        end
    end
    clearvars('-except', initialVars{:});
end
fclose(logfid);
% get all the resulting structures.
indicesStruct.indices = indices;
indicesStruct.indicesRep = indicesRep;
scoresStruct.scores = scores;
scoresStruct.scoresRep = scoresRep;
mrgdataStruct.mrgdata = mrgdata;
mrgdataStruct.mrgdataRep = mrgdataRep;
taskstatStruct.taskstat = taskstat;
taskstatStruct.taskstatRep = taskstatRep;
usedTimeSecs = toc;
addpath utilis
usedTimeHuman = seconds2human(usedTimeSecs, 'full');
rmpath utilis
fprintf('Congratulations! Data of %d task(s) merged completely this time.\n', nTasks);
fprintf('Returning without error!\nTotal time used: %s\n', usedTimeHuman);
