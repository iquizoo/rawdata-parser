function [extracted, status] = sngreadxls(filename, opts)
% SNGREADXLS read data from a single excel file.

% read data set
records = readtable(filename, opts);
recvars = records.Properties.VariableNames;

% change type of two key variables
USER_KEY = 'userId';
TASK_KEY = 'excerciseId';
DATA_KEY = 'data';
keyVarNames = {USER_KEY, TASK_KEY};
if any(~ismember(keyVarNames, recvars))
    % if `userId`, or 'exceciseId' not found, return an empty table
    extracted = table;
    status = -1;
    return
else
    % transform key variable types to numeric ones
    for keyname = keyVarNames
        if ~isnumeric(records.(keyname{:}))
            records.(keyname{:}) = str2double(records.(keyname{:}));
        end
    end
end
% concatenate data string into one multiple object json string
datastr = ['[', strjoin(records.(DATA_KEY), ','), ']'];
% transform data json string
[rec, status] = json2rec(datastr, records.(TASK_KEY));
% horzcat to get form extracted
extracted = [records(:, setdiff(recvars, DATA_KEY, 'stable')), rec];
end
