function [namesfull, ids, idnames] = tasknamechk(names, namestore, idsreal)
%TASKNAMECHK checks whether input task names are valid or not.
%   TASKNAMECHK checks the first argument according to the second input,
%   and output all the valid names: input names, ids and idnames included.

% remain namestor rows with id in idsreal
namestore = namestore(ismember(namestore.TaskID, idsreal), :);

% check input names and convert them to ids
if isnumeric(names)
    % the task names are specified by IDs, so one task name cannot denote
    % multiple tasks.
    fprintf('Detected tasks are specified in numeric type. Checking validity.\n')
    % remove input task names not in namestore
    isValid = ismember(names, namestore.TaskID);
    if ~all(isValid)
        warning('UDF:TASKNAMECHK:InvalidTaskID', ...
            'Some task identifiers are invalid, and will not be preprocessed. Please check!')
        fprintf('Invalid task identifier:\n')
        disp(names(~isValid))
        % for compatibility considerations, column number remains unchanged
        names(~isValid, :) = [];
    end
    namesfull = names;
    ids = names;
else
    % the task names are not specified by IDs, so one task name might
    % denote multiple tasks (different versions).
    fprintf('Detected tasks are specified in charater/string type. Checking validity.\n')
    % ensure task names are stored in a coloumn cellstr vector
    names = cellstr(names);
    names = reshape(names, numel(names), 1);
    % remove empty task name string
    names(ismissing(names)) = [];

    % remove input task name not in namestore
    % task name is valid if any kind of task names matches
    isValid = ismember(names, namestore.TaskName) |...
        ismember(names, namestore.TaskFullName) | ...
        ismember(names, namestore.TaskIDName);
    % remove non-matching task names from input task names
    if ~all(isValid)
        warning('UDF:TASKNAMECHK:InvalidTaskNameString', ...
            'Some task name strings are invalid, and will not be preprocessed. Please check!')
        fprintf('Invalid task name strings:\n')
        disp(names(~isValid))
        % for compatibility considerations, column number remains unchanged
        names(~isValid, :) = [];
    end
    % get the locations for each valid input task name
    namesfull = {};
    ids = [];
    for iname = 1:length(names)
        name = names{iname};
        locs = ismember(namestore.TaskName, name) |...
            ismember(namestore.TaskFullName, name) | ...
            ismember(namestore.TaskIDName, name);
        id = namestore.TaskID(locs);
        % repeat name the same times as the number of ids found
        namesfull = [namesfull; repmat({name}, size(id))]; %#ok<AGROW>
        ids = [ids; id]; %#ok<AGROW>
    end
end
% map out the id names
[~, loc] = ismember(ids, namestore.TaskID);
idnames = namestore.TaskIDName(loc);
