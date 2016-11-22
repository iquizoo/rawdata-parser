function [mrgdata, scores, indices, taskstat, metavars] = Merges(resdata)
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
%Use metavars to store all the variable names of meta data.
metavars = {'userId', 'name', 'gender', 'school', 'grade', 'cls', 'createDate'};
%Vertcat metadata.
resMetadata = cellfun(@(tbl) tbl(:, ismember(tbl.Properties.VariableNames, metavars)), ...
    resdata.Data, 'UniformOutput', false);
dataMergeMetadata = cat(1, resMetadata{:});
metavars = intersect(dataMergeMetadata.Properties.VariableNames, metavars);
%Check the following variables.
fprintf('Now trying to modify metadata: gender, school, grade, cls. Change these variables to categorical data. Please wait...\n')
chkVarsOfMetadata = intersect({'gender', 'school', 'grade', 'cls'}, metavars);
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
%Remove repetitions in the merged metadata. Note: createDate is special.
spVar = 'createDate';
metadataNoSpVar = dataMergeMetadata(:, ~ismember(metavars, spVar));
mrgdata = unique(metadataNoSpVar);
if ismember(spVar, metavars)
    %For createDate variable, only the earliest date is remained.
    fprintf('Create date is required, try remaining the earliest date.\n')
    nsubs = height(mrgdata);
    allCreateTime = dataMergeMetadata.(spVar);
    createDateTrans = repmat(NaT, nsubs, 1);
    for isub = 1:nsubs
        createDateTrans(isub) = ...
            min(allCreateTime(ismember(metadataNoSpVar, mrgdata(isub, :), 'rows')));
    end
    mrgdata.(spVar) = createDateTrans;
end
for ivomd = 1:length(chkVarsOfMetadata)
    cvomd = chkVarsOfMetadata{ivomd};
    switch cvomd
        case 'grade'
            %It is comparable for grades.
            mrgdata.(cvomd) = categorical(mrgdata.(cvomd), 'ordinal', true);
        case 'school'
            %School is best ordered in the way of differentiating different
            %districts.
            mrgdata.(cvomd) = reordercats(categorical(mrgdata.(cvomd)), ...
                unique(schInfo.SchoolIDName, 'stable'));
        otherwise
            mrgdata.(cvomd) = categorical(mrgdata.(cvomd));
    end
end
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
            if ismember(metavars, 'school')
                %The logic here is, if there is no school information for
                %current observation, set the observation as missing data; if
                %there is school information, if there is any invalid value,
                %set the observation as invalid.
                taskstat.(curTask)(isubj) = ~isundefined(taskstat(isubj, :).school) * ...
                    (-2 * (any(isnan(curTaskData(loc, :).res{:, :}))) + 1);
            else
                taskstat.(curTask)(isubj) = (-2 * (any(isnan(curTaskData(loc, :).res{:, :}))) + 1);
            end
            scores.(curTask)(isubj) = curTaskData(loc, :).score;
            indices.(curTask)(isubj) = curTaskData(loc, :).index;
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
