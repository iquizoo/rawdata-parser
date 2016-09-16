function [mrgdata, scores, indices, taskstat, metavars] = Merges(resdata, verbose)
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

%Input argument checking.
if nargin <= 1, verbose = true; end
%Set the school information.
schInfo = readtable('taskSettings.xlsx', 'Sheet', 'schoolinfo');
schMap = containers.Map(schInfo.SchoolName, schInfo.SchoolIDName);
%Set the grade information.
grdInfo = readtable('taskSettings.xlsx', 'Sheet', 'gradeinfo');
grdMap = containers.Map(grdInfo.GradeStr, grdInfo.Encode);
%Set the class information.
clsInfo = readtable('taskSettings.xlsx', 'Sheet', 'clsinfo');
clsMap = containers.Map(clsInfo.ClsStr, clsInfo.Encode);
%Get the metadata. Not all of the variables in meta data block is
%interested, so descard those of no interest. And then do some basic
%transformation of meta data, e.g. school and grade.
fprintf('Now trying to merge the metadata. Please wait...\n')
varsOfMetadata = {'userId', 'name', 'gender', 'school', 'grade', 'cls'};
%Use metavars to store all the variable names of meta data.
metavars = varsOfMetadata;
%Vertcat metadata.
resMetadata = cellfun(@(tbl) tbl(:, ismember(tbl.Properties.VariableNames, varsOfMetadata)), ...
    resdata.Data, 'UniformOutput', false);
dataMergeMetadata = cat(1, resMetadata{:});
%Check the following variables.
fprintf('Now trying to modify metadata: gender, school, grade, cls. Change these variables to categorical data. Please wait...\n')
chkVarsOfMetadata = {'gender', 'school', 'grade', 'cls'};
for ivomd = 1:length(chkVarsOfMetadata)
    initialVars = who;
    cvomd = chkVarsOfMetadata{ivomd};
    if ~ismember(cvomd, dataMergeMetadata.Properties.VariableNames)
        metavars(strcmp(metavars, cvomd)) = {''};
        continue
    end
    cVarNotCharLoc = ~cellfun(@ischar, dataMergeMetadata.(cvomd));
    if any(cVarNotCharLoc)
        dataMergeMetadata.(cvomd)(cVarNotCharLoc) = {''};
    end
    switch cvomd
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
%Remove non-existent metadata variable.
metavars(cellfun(@isempty, metavars)) = [];
dataMergeMetadata = unique(dataMergeMetadata);
for ivomd = 1:length(chkVarsOfMetadata)
    cvomd = chkVarsOfMetadata{ivomd};
    switch cvomd
        case 'grade'
            %It is comparable for grades.
            dataMergeMetadata.(cvomd) = categorical(dataMergeMetadata.(cvomd), 'ordinal', true);
        case 'school'
            %School is best ordered in the way of differentiating different
            %districts.
            dataMergeMetadata.(cvomd) = reordercats(categorical(dataMergeMetadata.(cvomd)), ...
                unique(schInfo.SchoolIDName, 'stable'));
        otherwise
            dataMergeMetadata.(cvomd) = categorical(dataMergeMetadata.(cvomd));
    end
end
mrgdata = dataMergeMetadata; %Metadata done!
%Generate a table to store the completion status for each id and task.
taskstat = mrgdata;
scores = mrgdata;
indices = mrgdata;
%Get the experimental data.
resdata.TaskIDName = categorical(resdata.TaskIDName);
tasks = unique(resdata.TaskIDName, 'stable');
nTasks = length(tasks);
nsubj = height(mrgdata);
%Merge data task by task.
fprintf('Now trying to merge all the data task by task. Please wait...\n')
dispinfo = '';
for imrgtask = 1:nTasks
    initialVars = who;
    curTaskIDName = tasks(imrgtask);
    fprintf(repmat('\b', 1, length(dispinfo)));
    dispinfo = sprintf('Now merging task: %s(%d/%d).\n', curTaskIDName, imrgtask, nTasks);
    fprintf(dispinfo);
    %Get the data of current task.
    curTaskData = resdata.Data(resdata.TaskIDName == curTaskIDName, :);
    curTaskData = cat(1, curTaskData{:});
    curTaskData.res = cat(1, curTaskData.res{:});
    if verbose
        %Generate the tasks status, scores and performance indices matrices.
        curTask = char(curTaskIDName);
        taskstat.(curTask) = zeros(nsubj, 1);
        scores.(curTask) = nan(nsubj, 1);
        indices.(curTask) = nan(nsubj, 1);
        for isubj = 1:nsubj
            %Missing/not measured -> 0; OK -> 1; Measured but not valid -> -1.
            curID = taskstat.userId(isubj);
            [isexisted, loc] = ismember(curID, curTaskData.userId);
            if isexisted
                %The logic here is, if there is no school information for
                %current observation, set the observation as missing data; if
                %there is school information, if there is any invalid value,
                %set the observation as invalid.
                taskstat.(curTask)(isubj) = ~isundefined(taskstat(isubj, :).school) * ...
                    (-2 * (any(isnan(curTaskData(loc, :).res{:, :}))) + 1);
                scores.(curTask)(isubj) = curTaskData(loc, :).score;
                indices.(curTask)(isubj) = curTaskData(loc, :).index;
            end
        end
    end
    %Use the taskIDName as the variable name precedence.
    curTaskOutVars = strcat(cellstr(curTaskIDName), '_', curTaskData.res.Properties.VariableNames);
    curTaskData.res.Properties.VariableNames = curTaskOutVars;
    %Transformation for 'res'.
    curTaskData = [curTaskData, curTaskData.res]; %#ok<AGROW>
    for ivars = 1:length(curTaskOutVars)
        curvar = curTaskOutVars{ivars};
        mrgdata.(curvar) = nan(height(mrgdata), 1);
        [LiMrgData, LocCurTaskData] = ismember(mrgdata.userId, curTaskData.userId);
        mrgdata.(curvar)(LiMrgData) = curTaskData.(curvar)(LocCurTaskData(LocCurTaskData ~= 0));
    end
    clearvars('-except', initialVars{:});
end
