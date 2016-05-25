function [mrgdata, scores, indices, taskstat] = Merges(resdata)
%MERGES merges all the results obtained data.
%   MRGDATA = MERGES(RESDATA) merges the resdata according to userId, and
%   some information, e.g., gender, school, grade, is also merged according
%   to some arbitrary principle.
%
%   See also PREPROC, PROC.

%Set the school information.
schInfo = readtable('taskSettings.xlsx', 'Sheet', 'schoolinfo');
schMap = containers.Map(schInfo.SchoolName, schInfo.SchoolIDName);
schIDMap = containers.Map(schInfo.SchoolIDName, schInfo.SID);
%Set the grade information.
grdInfo = readtable('taskSettings.xlsx', 'Sheet', 'gradeinfo');
grdMap = containers.Map(grdInfo.GradeStr, grdInfo.Encode);
%Get the metadata. Not all of the variables in meta data block is
%interested, so descard those of no interest. And then do some basic
%transformation of meta data, e.g. school and grade.
varsOfMetadata = {'userId', 'gender', 'school', 'grade'};
%Vertcat metadata.
resMetadata = cellfun(@(tbl) tbl(:, ismember(tbl.Properties.VariableNames, varsOfMetadata)), ...
    resdata.Data, 'UniformOutput', false);
dataMergeMetadata = cat(1, resMetadata{:});
%Check the following variables.
chkVarsOfMetadata = {'gender', 'school', 'grade'};
for ivomd = 1:length(chkVarsOfMetadata)
    cvomd = chkVarsOfMetadata{ivomd};
    cVarNotCharLoc = ~cellfun(@ischar, dataMergeMetadata.(cvomd));
    if any(cVarNotCharLoc)
        dataMergeMetadata.(cvomd)(cVarNotCharLoc) = {''};
    end
    %Set those schools of no interest into empty string, so as to be
    %transformed into undefined.
    if strcmp(cvomd, 'school')
        %Locations of schools of interest.
        schOIloc = ismember(dataMergeMetadata.school, schInfo.SchoolName);
        if any(~schOIloc)
            dataMergeMetadata.school(~schOIloc) = {''};
        end
        dataMergeMetadata.school(schOIloc) = values(schMap, dataMergeMetadata.school(schOIloc));
    end
    %Convert grade strings to numeric data.
    if strcmp(cvomd, 'grade')
        allGradeStr = dataMergeMetadata.grade;
        allGradeStr(~isKey(grdMap, allGradeStr)) = {''};
        dataMergeMetadata.grade = values(grdMap, allGradeStr);
    end
    dataMergeMetadata.(cvomd) = categorical(dataMergeMetadata.(cvomd));
end
dataMergeMetadata = unique(dataMergeMetadata);
%Merge undefined. Basic logic, of each checking variable, one of the
%following circumstances indicated an auto merge.
%   1. if all the instances are undefined, just make it undefined.
%     Then there is no unique categories of defined instances.
%   2. other than undefined, only one defined category found, use this
%   found category.
%     Then there is only one unique categories of defined instances.
usrID = dataMergeMetadata.userId;
uniUsrID = unique(usrID);
nusr = length(uniUsrID);
for iusr = 1:nusr
    curUsrID = uniUsrID(iusr);
    curUsrMetadata = dataMergeMetadata(dataMergeMetadata.userId == curUsrID, :);
    if height(curUsrMetadata) > 1 %Mutiple entries for current user's basic information.
        mrgResolved = true;
        for ivomd = 1:length(chkVarsOfMetadata)
            cvomd = chkVarsOfMetadata{ivomd};
            curUsrCurVarData = curUsrMetadata.(cvomd);
            udfLoc = isundefined(curUsrCurVarData);
            if length(unique(curUsrCurVarData(~udfLoc))) > 1
                mrgResolved = false;
            else
                inentry = find(~udfLoc);
                if isempty(inentry)
                    inentry = 1; %Use the first entry.
                else
                    inentry = inentry(1); %Use the first defined instance.
                end
            end
        end
        if ~mrgResolved
            disp(curUsrMetadata)
            inentry = input(...
                'Please input an integer to denote which entry is used as current user''s information.\n');
        end
        curUsrMetadata.userId(~ismember(1:height(curUsrMetadata), inentry)) = nan;
        dataMergeMetadata(dataMergeMetadata.userId == curUsrID, :) = curUsrMetadata;
    end
end
dataMergeMetadata(isnan(dataMergeMetadata.userId), :) = [];
mrgdata = dataMergeMetadata; %Metadata done!
%Change the subjects order according the order of school in schInfo.
mrgdata.schID = nan(height(mrgdata), 1);
definedSchRowsIdx = ~isundefined(mrgdata.school);
mrgdata.schID(definedSchRowsIdx) = cell2mat(values(schIDMap, cellstr(mrgdata.school(definedSchRowsIdx))));
mrgdata = sortrows(mrgdata, 'schID');
mrgdata.schID = [];
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
for imrgtask = 1:nTasks
    initialVars = who;
    curTaskIDName = tasks(imrgtask);
    %Get the data of current task.
    curTaskData = resdata.Data(resdata.TaskIDName == curTaskIDName, :);
    curTaskData = cat(1, curTaskData{:});
    curTaskData.res = cat(1, curTaskData.res{:});
    %Generate the tasks status matrix.
    curTask = char(curTaskIDName);
    taskstat.(curTask) = zeros(nsubj, 1);
    scores.(curTask) = nan(nsubj, 1);
    indices.(curTask) = nan(nsubj, 1);
    for isubj = 1:nsubj
        curID = taskstat.userId(isubj);
        [isexisted, loc] = ismember(curID, curTaskData.userId);
        if isexisted
            taskstat.(curTask)(isubj) = ~any(isnan(curTaskData(loc, :).res{:, :}));
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
