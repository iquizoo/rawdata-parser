function [extracted, status] = sngreadjson(filename)
% SNGREADJSON read data from a single json text file.

% status is 0 (everything is okay) by default
status = 0;
% raw data fields
RAW_FIELDS = {'abId' 'allTime' 'basicOverPercent' 'basicScore' 'basicZ' ...
    'cls' 'computeJson' 'config' 'createTime' 'data' 'examId' ...
    'excerciseId' 'grade' 'resultJson' 'standardOverPercent' ...
    'standardScore' 'standardZ' 'subId' 'subjectId' 'taskName' ...
    'unitScore' 'userId' 'uuid'};
% raw data field-types
RAW_TYPES = {'double' 'double' 'double' 'double' 'double' ...
    'char' 'char' 'char' 'char' 'char' 'double' ...
    'double' 'char' 'char' 'double' ...
    'double' 'double' 'double' 'double' 'char' ...
    'double' 'double' 'char'};
% json text file is stored in 'UTF-8' encoding
fid = fopen(filename, 'r', 'n', 'UTF-8');
datastr = fgetl(fid);
fclose(fid);
try
    decoded = jsondecode(datastr);
    % when decoded into a cell, some missing fields should be filled
    if iscell(decoded)
        miss_fields = cellfun(@(s) setdiff(RAW_FIELDS, fieldnames(s)), decoded, ...
            'UniformOutput', false);
        miss_types = cellfun(@(c) RAW_TYPES(ismember(RAW_FIELDS, c)), miss_fields, ...
            'UniformOutput', false);
        % fill missed fields
        decoded = cellfun(@fill_missing, decoded, miss_fields, miss_types, ...
            'UniformOutput', false);
        decoded = cat(1, decoded{:});
    end
    extracted = struct2table(decoded);
catch
    % error proof programming
    extracted = table;
    status = -1;
end
end

function old = fill_missing(old, fill_fields, fill_type)
% fill missing fields

for i = 1:length(fill_fields)
    switch fill_type{i}
        case 'double'
            old.(fill_fields{i}) = nan;
        case 'char'
            old.(fill_fields{i}) = '';
    end
end
end
