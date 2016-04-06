function dataExtract = readshtdata(fname, shtname)
%This script is used for processing data from HQH, mainly about some
%examination used by students.

%Here is a method of question category based way to read in data.
%By Zhang, Liang. 2015/11/27.
%Modified to use in another problem. 

%Check input variables.
if nargin < 2
    shtname = '';
end

%Get sheets' names.
[~, sheets] = xlsfinfo(fname);

%Load parameters.
paraSet
setting = itemSet(sheets);

%Sheet-wise processing.
nsht = length(sheets);
%Determine the processing.
insht = find(ismember(sheets, shtname));
if isempty(insht)
    userin = input('Will processing all the sheets, continue([Y]/N)?', 's');
    if strcmpi(userin, 'n') || strcmpi(userin, 'no')
        return
    end
    ssht = 1;
    dataExtract = cell(nsht, 2);
    dataExtract(:, 1) = sheets;
else
    ssht = insht;
    nsht = insht;
    dataExtract = cell(1, 2);
    dataExtract(1, 1) = {shtname};
end
%Begin processing.
for isht = ssht:nsht
    initialVarsSht = who;
    locset = ismember(setting.sheets, sheets{isht});
    currentsetting = setting(locset, :);
    fprintf('Now processing sheet %s\n', currentsetting.sheets{:});
    
    %Read in the information of interest.
    [~, ~, rawdata] = xlsread(fname, currentsetting.sheets{:});
    
    if size(rawdata, 1) >= 2
        %Extrat useful data.
        vars = currentsetting.variables{:};
        varlen = length(vars);
        data = rawdata(2:end, 1:varlen);
        %Some clear job.
        data(isnan(cell2mat(data(:, ismember(vars, 'pid')))), :) = [];

        %Participant-wise processing.
        %Preallocating.
        nsubj = size(data, 1);
        celldata = cell(nsubj, varlen);
        currentdata = cell2struct(celldata, vars, 2);
        for isub = 1:nsubj
            initialVarsSub = who;
            %Transform all the data of this subject into a structure.
            for ivar = 1:varlen
                currentdata(isub).(vars{ivar}) = data{isub, ivar};
            end
            %Processing question record in data.
            total_record_loc = find(~cellfun(@isempty, regexp(vars, '^qrecord\w*', 'start', 'once')));
            if ~isempty(total_record_loc)
                %Record-wise processing.
                for iloc = 1:length(total_record_loc)
                    initialVarsRec = who;
                    record_loc = total_record_loc(iloc);
                    %Get the record information and split it into readable
                    %information.
                    pre_record = data(isub, record_loc);
                    if ~isequal(pre_record, {'-'})
                        %Determine parameter for this question. 
                        currentqid = currentsetting.QID;
                        currentpara = para(para.QID == currentqid, :); %#ok<NODEF>

                        %Pre-split.
                        if ~isequal(currentpara.presplit, {'no'})
                            num_split = length(currentpara.presplit{1});
                            %Find out all of the split locations.
                            loc_split = nan(1, num_split);
                            for i_split = 1:num_split
                                loc_split(i_split) = strfind(data{isub, record_loc}, currentpara.presplit{1}{i_split});
                            end
                            presplit = [currentpara.presplit{1}; num2cell(loc_split)]';
                            %Sort the locations.
                            presplit = sortrows(presplit, 2);
                            %Do the pre-split.
                            presplitres = cell(1, num_split);
                            for i_split = 1:num_split
                                if i_split ~= num_split
                                    presplitres{i_split} = ...
                                        data{isub, record_loc}(presplit{i_split, 2} + length(presplit{i_split, 1}) + 1:presplit{i_split + 1, 2} - 2);
                                else
                                    presplitres{i_split} = ...
                                        data{isub, record_loc}(presplit{i_split, 2} + length(presplit{i_split, 1}) + 1:end);
                                end
                            end
                            pre_record = presplitres;
                        end

                        %Split the record.                    
                        record = str_split(pre_record, currentpara);

                        %Alternative splitting if necessary.
                        if currentsetting.Alternative && isempty(record{:})
                            currentqid = currentsetting.Alternative;
                            currentpara = para(para.QID == currentqid, :);

                            %Pre-split.
                            if ~isequal(currentpara.presplit, {'no'})
                                num_split = length(currentpara.presplit{1});
                                %Find out all of the split locations.
                                loc_split = nan(1, num_split);
                                for i_split = 1:num_split
                                    loc_split(i_split) = strfind(data{isub, record_loc}, currentpara.presplit{1}{i_split});
                                end
                                presplit = [currentpara.presplit{1}; num2cell(loc_split)]';
                                %Sort the locations.
                                presplit = sortrows(presplit, 2);
                                %Do the pre-split.
                                presplitres = cell(1, num_split);
                                for i_split = 1:num_split
                                    if i_split ~= num_split
                                        presplitres{i_split} = ...
                                            data{isub, record_loc}(presplit{i_split, 2} + length(presplit{i_split, 1}) + 1:presplit{i_split + 1, 2} - 2);
                                    else
                                        presplitres{i_split} = ...
                                            data{isub, record_loc}(presplit{i_split, 2} + length(presplit{i_split, 1}) + 1:end);
                                    end
                                end
                                pre_record = presplitres;
                            end

                            %Split the record.                    
                            record = str_split(pre_record, currentpara);
                        end

                        %Postsplit transformation and store.
                        num_record = length(record);
                        col_ind = 1:currentpara.colnum;
                        col_num = col_ind(~ismember(col_ind, cell2mat(currentpara.charcol)));
                        for i_rec = 1:num_record
                            record{i_rec}(:, col_num) = cellfun(@str2double, record{i_rec}(:, col_num), 'UniformOutput', false);
                            record{i_rec} = cell2table(record{i_rec}, 'VariableNames', currentpara.collabel{1});
                        end
                        if num_record > 1
                            for i_rec = 1:num_record
                                currentdata(isub).record.(presplit{i_rec, 1}) = record{i_rec};
                            end
                        else
                            currentdata(isub).(vars{record_loc}) = record{1};
                        end
                    else
                        currentdata(isub).qrecord = table;
                    end
                    clearvars('-except', initialVarsRec{:});
                end
            end
            %Processing sdk data.
            sdk_loc = ismember(vars, 'sdk');
            if any(sdk_loc)
                currentdata(isub).sdk = str2table(data{isub, sdk_loc});
            end            
            clearvars('-except', initialVarsSub{:});
        end
        currentdata = struct2table(currentdata);
        if isempty(insht)
            dataExtract{isht, 2} = currentdata;
        else
            dataExtract{1, 2} = currentdata;
        end
    end
    clearvars('-except', initialVarsSht{:});
end
dataExtract = cell2table(dataExtract, 'VariableNames', {'TaskName', 'TaskRecord'});
