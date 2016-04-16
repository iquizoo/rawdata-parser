function mrgdata = mergeData(resdata)
%MERGEDATA merges all the results data obtained from basicCompute.m
%   MRGDATA = MRGEDATA(RESDATA) merges the resdata according to userId, and
%   some information, e.g., gender, school, grade, is also merged according
%   to some arbitrary principle.
%
%   See also basicCompute.

resdata = cat(1, resdata.Data{:});
% Some transformation of basic information, e.g. school and grade.
varsOfBasicInformation = {'userId', 'gender', 'school', 'grade'};
dataMergeBI = resdata(:, ismember(resdata.Properties.VariableNames, varsOfBasicInformation));
for ivobi = 2:length(varsOfBasicInformation)
    cvobi = varsOfBasicInformation{ivobi};
    cVarNotCharLoc = ~cellfun(@ischar, dataMergeBI.(cvobi));
    if any(cVarNotCharLoc)
        dataMergeBI.(cvobi)(cVarNotCharLoc) = {''};
    end
    %Set those schools of no interest into empty string, so as to be
    %transformed into undefined.
    if strcmp(cvobi, 'school')
        schOI = {'劳卫小学';'北房中学';'新开路东总布小学';...
            '棠中外语学校附属小学';'棠湖中学外语实验学校';'玉带山小学';'石楼中学';'重庆市劳卫小学'};
        schONIloc = ~ismember(dataMergeBI.school, schOI);
        if any(schONIloc)
            dataMergeBI.school(schONIloc) = {''};
        end
    end
    %Convert grade strings to numeric data.
    if strcmp(cvobi, 'grade')
        gradestr = dataMergeBI.grade;
        gradestr = regexprep(gradestr, '一(年级)?', '1');
        gradestr = regexprep(gradestr, '二(年级)?', '2');
        gradestr = regexprep(gradestr, '三(年级)?', '3');
        gradestr = regexprep(gradestr, '四(年级)?', '4');
        gradestr = regexprep(gradestr, '五(年级)?', '5');
        gradestr = regexprep(gradestr, '六(年级)?', '6');
        gradestr = regexprep(gradestr, '七(年级)?', '7');
        gradestr = regexprep(gradestr, '八(年级)?', '8');
        gradenum = str2double(gradestr);
        dataMergeBI.grade = gradenum;
    end    
    dataMergeBI.(cvobi) = categorical(dataMergeBI.(cvobi));
end
dataMergeBI = unique(dataMergeBI);
%Merge undefined.
usrID = resdata.userId;
uniUsrID = unique(usrID);
nusr = length(uniUsrID);
for iusr = 1:nusr
    curUsrID = uniUsrID(iusr);
    curUsrBI = dataMergeBI(dataMergeBI.userId == curUsrID, :);
    if height(curUsrBI) > 1 %Mutiple entries for current user's basic information.
        mrgResolved = true;
        for ivobi = 2:length(varsOfBasicInformation)
            cvobi = varsOfBasicInformation{ivobi};
            if ~all(isundefined(curUsrBI.(cvobi))) && ... %All of the information is undefined.
                    length(unique(curUsrBI.(cvobi))) ~= 1 %Only one category is found.
                mrgResolved = false;
            end
        end
        if mrgResolved
            inentry = 1;
        else
            disp(curUsrBI)
            inentry = input(...
                'Please input an integer to denote which entry is used as current user''s information.\n');
        end
        curUsrBI.userId(~ismember(1:height(curUsrBI), inentry)) = nan;
        dataMergeBI(dataMergeBI.userId == curUsrID, :) = curUsrBI;
    end
end
dataMergeBI(isnan(dataMergeBI.userId), :) = [];
mrgdata = dataMergeBI;

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
