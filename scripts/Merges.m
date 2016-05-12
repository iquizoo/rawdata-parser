function mrgdata = Merges(resdata)
%MERGES merges all the results obtained data.
%   MRGDATA = MERGES(RESDATA) merges the resdata according to userId, and
%   some information, e.g., gender, school, grade, is also merged according
%   to some arbitrary principle.
%
%   See also PREPROC, PROC.

%Set the school information.
schInfo = readtable('taskSettings.xlsx', 'Sheet', 'schoolinfo');
schMap = containers.Map(schInfo.SchoolName, schInfo.SchoolIDName);
%Set the grade information.
grdInfo = readtable('taskSettings.xlsx', 'Sheet', 'gradeinfo');
grdMap = containers.Map(grdInfo.GradeStr, grdInfo.Encode);
%Vertcat data.
resdata = cat(1, resdata.Data{:});
%Get the metadata. Not all of the variables in meta data block is
%interested, so descard those of no interest. And then do some basic
%transformation of meta data, e.g. school and grade.
varsOfMetadata = {'userId', 'gender', 'school', 'grade'};
dataMergeMetadata = resdata(:, ismember(resdata.Properties.VariableNames, varsOfMetadata));
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
%     Then the unique categories of defined instances count 0.
%   2. other than undefined, only one defined category found, use this
%   found category.
%     Then the unique categories of defined instances count 1.
usrID = resdata.userId;
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
mrgdata = dataMergeMetadata;
%Merge data task by task.
%Load basic parameters.
settings = readtable('taskSettings.xlsx', 'Sheet', 'settings');
resdata.TaskIDName = categorical(resdata.TaskIDName);
tasks = unique(resdata.TaskIDName, 'stable');
nTasks = length(tasks);
for imrgtask = 1:nTasks
    initialVars = who;
    curTaskIDName = tasks(imrgtask);
    curTaskSetting = settings(ismember(settings.TaskIDName, curTaskIDName), :);
    curTaskData = resdata(resdata.TaskIDName == curTaskIDName, :);
    curTaskData.res = cat(1, curTaskData.res{:});
    % Note: there might be multiple entries of task settings for some
    % tasks, e.g., 'SRT', and then just choose the first entry.
    curTaskOutVars = strcat(curTaskSetting.TaskIDName{1}, '_', curTaskData.res.Properties.VariableNames);
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
