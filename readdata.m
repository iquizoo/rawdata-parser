%This script is used for processing data from HQH, mainly about some
%examination used by students.

%Here is a method of question category based way to read in data.
%By Zhang, Liang. 2015/11/27.

clear, clc
filesInfo = dir('*.xls');
%Load parameters.
load('para.mat')

%The sheets of interest.
SHT_OF_INT = {'Export', '原始数据与sdk参数'};

%Columns of interest.
COL_OF_INT.info = {'id', '姓名', '性别', '学校'};
info_var_name = {'name', 'gender', 'school'};
COL_OF_INT.data = {'原始记录', 'sdk参数', '分数'};
ID_COL_DATA     = 1;

%Label row of data processing.
ROW_LABEL.info = 1;
ROW_LABEL.data = 2;

%File-wise processing.
dataExtract = [];
for ifile = 1:length(filesInfo)
    initialVarsFile = who;
    fprintf('Now processing %s\n', filesInfo(ifile).name);
    
    %Read in the information of interest.
    [~, ~, info] = xlsread(filesInfo(ifile).name, SHT_OF_INT{1});
    [~, ~, data] = xlsread(filesInfo(ifile).name, SHT_OF_INT{2});
    
    %Processing basic information.
    loc_of_int.info = ismember(info(ROW_LABEL.info, :), COL_OF_INT.info);
    info_of_int = info(:, loc_of_int.info);
    
    %Processing recorded data.
    loc_of_int.data(1, :) = strcmpi(data(ROW_LABEL.data, :), COL_OF_INT.data{1});
    loc_of_int.data(2, :) = strcmpi(data(ROW_LABEL.data, :), COL_OF_INT.data{2});
    loc_of_int.data(3, :) = strcmpi(data(ROW_LABEL.data, :), COL_OF_INT.data{3});
    if any(loc_of_int.data(1, :))
        record_loc = find(loc_of_int.data(1, :));
        sdk_loc    = find(loc_of_int.data(2, :));
        score_loc  = find(loc_of_int.data(3, :));
        %SUBJECT-wise processing.
        for isub = ROW_LABEL.data + 1:size(data, 1)
            initialVarsSub = who;
            %Extract subject id.
            thisID = data{isub, ID_COL_DATA};
            if ~isnumeric(thisID)
                thisData.sid = str2double(thisID);
            else
                thisData.sid = thisID;
            end
            
            if ~isnan(thisID)
                thisInfo = info_of_int(ismember(info_of_int(:, ismember(COL_OF_INT.info, 'id')), thisID), ~ismember(COL_OF_INT.info, 'id'));
                thisData.info = cell2table(thisInfo, 'VariableNames', info_var_name);
                thisData.data = [];
                
                %QUESTION-wise processing.
                for iloc = 1:length(record_loc)
                    initialVarsQuest = who;
                    %Extract question id.
                    thisQID = data{1, record_loc(iloc)};
                    if ischar(thisQID)
                        thisQID = str2double(thisQID);
                    end
                    thisQuestData.QID = thisQID;
                    
                    %Get the record information and split it into readable
                    %information.
                    pre_record = data(isub, record_loc(iloc));
                    if ~isequal(pre_record, {'-'})
                        %Determine parameter for this question. 
                        thispara = para(para.QID == thisQID, :);

                        %Pre-split.
                        if ~isequal(thispara.presplit, {'no'})
                            num_split = length(thispara.presplit{1});
                            %Find out all of the split locations.
                            loc_split = nan(1, num_split);
                            for i_split = 1:num_split
                                loc_split(i_split) = strfind(data{isub, record_loc(iloc)}, thispara.presplit{1}{i_split});
                            end
                            presplit = [thispara.presplit{1}; num2cell(loc_split)]';
                            %Sort the locations.
                            presplit = sortrows(presplit, 2);
                            %Do the pre-split.
                            presplitres = cell(1, num_split);
                            for i_split = 1:num_split
                                if i_split ~= num_split
                                    presplitres{i_split} = ...
                                        data{isub, record_loc(iloc)}(presplit{i_split, 2} + length(presplit{i_split, 1}) + 1:presplit{i_split + 1, 2} - 2);
                                else
                                    presplitres{i_split} = ...
                                        data{isub, record_loc(iloc)}(presplit{i_split, 2} + length(presplit{i_split, 1}) + 1:end);
                                end
                            end
                            pre_record = presplitres;
                        end

                        %Split the record.                    
                        record = str_split(pre_record, thispara.delimiter, thispara.colnum);
                        num_record = length(record);
                        col_ind = 1:thispara.colnum;
                        col_num = col_ind(~ismember(col_ind, cell2mat(thispara.charcol)));
                        for i_rec = 1:num_record
                            record{i_rec}(:, col_num) = cellfun(@str2double, record{i_rec}(:, col_num), 'UniformOutput', false);
                            record{i_rec} = cell2table(record{i_rec}, 'VariableNames', thispara.collabel{1});
                        end                    
                        if num_record > 1
                            for i_rec = 1:num_record
                                thisQuestData.record.(presplit{i_rec, 1}) = record{i_rec};
                            end
                        else
                            thisQuestData.record = record{1};
                        end
                    else
                        thisQuestData.record = table;
                    end
                    thisQuestData.sdk = str2table(data{isub, sdk_loc(iloc)});
                    thisQuestData.score  = data{isub, score_loc(iloc)};
                    thisData.data = [thisData.data, thisQuestData];
                    clearvars('-except', initialVarsQuest{:});
                end
            else
                thisData.data.record = table;
                thisData.data.sdk = table;
                thisData.data.score = [];
            end
            dataExtract = [dataExtract, thisData];
            clearvars('-except', initialVarsSub{:});
        end
    end
    clearvars('-except', initialVarsFile{:});
end
