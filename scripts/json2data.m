function [data, status] = json2data(jstr, id)
%JSON2DATA transforms old-formatted json data.

% status is 0 (everything is okay) by default
status = 0;
% preallocate output
VARS = {'rec', 'alltime', 'unitScore', 'computeJson'};
data = cell2table({{''}, 0, -99, {''}}, ...
    'VariableNames', VARS);
% decode json string
extracted = jsondecode(jstr);
% remove fields not containing only one row of data.
extfields = fieldnames(extracted);
extracted = struct2table(rmfield(extracted, ...
    extfields(structfun(@(f) size(f, 1), extracted) ~= 1)));
varnames = extracted.Properties.VariableNames;
if ismember('params', varnames)
    % flatten params
    % extract and remove `params` from original data
    params = extracted.params;
    extracted.params = [];
    % remove field with zero size
    parfields = fieldnames(params);
    params = struct2table(rmfield(params, ...
        parfields(structfun(@(f) size(f, 1), params) ~= 1)));
    % add params to the right of extracted
    extracted = [extracted, params];
    % in this instance, `id` is an optional argument
    if nargin < 2
        id = extracted.excerciseId;
    end
    % update var names
    varnames = extracted.Properties.VariableNames;
else
    if nargin < 2
        error('UDF:JSON2REC:TASKIDMISSING', 'Please specify id because the json string does not contain it.')
    end
end

% extract `rec` from json string
% `recvarname` is the varible name of data in params
% `recprefix` is not empty when there are more than one data string
switch id
    case {99991, 97967} % 'AssocMemory'
        % note '|' is used because all of these cases are possible
        recvaropts = 'tconditions|data';
        recprefix = '';
    case 99986 % 'SemanticMemory'
        recvaropts = 'sconditions&tconditions';
        recprefix = 's&t';
    case {100010, 100018, 97976} % 'DivAten1', 'DivAtten2'
        recvaropts = 'lconditions|leftconditions|leftConditions&rconditions|rightconditions|rightConditions';
        recprefix = 'left&right';
    otherwise
        recvaropts = 'conditions|data|detail|datail|llog';
        recprefix = '';
end
% separate all the data conditions
dataconds = cellfun(@(str) strsplit(str, '|'), strsplit(recvaropts, '&'), ...
    'UniformOutput', false);
% found out the real variable names of all the conditions
datavarnames = cellfun(@(strs) varnames(ismember(varnames, strs)), dataconds, ...
    'UniformOutput', false);
% split prefixes
prefixes = strsplit(recprefix, '&');
% extract data when data vars found
if ~any(cellfun(@isempty, datavarnames))
    rawstr = cellfun(@(field) extracted.(field{:}), datavarnames, 'UniformOutput', false);
else
    status = -1;
    rawstr = repmat({''}, size(datavarnames));
end
% add condition prefixes
if ~any(cellfun(@isempty, prefixes))
    datastr = cellstr(strjoin(strcat(prefixes, '(', rawstr, ')')));
else
    datastr = rawstr;
end
data.(VARS{1}) = datastr;

% store `alltime`
if ismember('allTime', varnames)
    data.(VARS{2}) = extracted.allTime;
end

% store unite score
realscoreVar = intersect({'unitScore', 'score'}, varnames);
if ~isempty(realscoreVar)
    data.(VARS{3}) = extracted.(realscoreVar{:});
else
    status = -2;
end

% store computation json
realcompVar = intersect({'computeJson', 'sdk'}, varnames);
if ~isempty(realcompVar)
    data.(VARS{4}) = cellstr(extracted.(realcompVar{:}));
else
    status = -3;
end

% wrapped the data to a cell for the catenation (hope a better version in
% future)
data = {data};
