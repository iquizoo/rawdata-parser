function [rec, status] = json2rec(jstr, ids)
%JSON2REC transforms old-formatted json data.

% variable name settings
KEYVAR = 'data';
ALTVARS = {'config', 'computeJson', 'resultJson', 'uuid', 'allTime', 'unitScore'};
ALTVARSOPTS = {{'config'}, {'computeJson', 'sdk'}, {'resultJson'}, {'uuid'}, {'allTime'}, {'unitScore', 'score'}};
vars = horzcat(KEYVAR, ALTVARS);
% decode json string
extracted = jsondecode(jstr);
% get the user number
nusers = length(extracted);
% validate ids length
nids = length(ids);
if nids == 1
    ids = repmat(nusers, 1);
else
    if nids ~= nusers
        error('UDF:JSON2REC:WRONGIDINPUT', ...
            'Ids must be the same length of number of json objects or scalar.')
    end
end

% preallocation
rec = cell2table(repmat({{''}, {''}, {''}, {''}, {''}, 0, -99}, nusers, 1), ...
    'VariableNames', vars);
% status is 0 (everything is okay) by default
status = zeros(nusers, 1);
for iUser = 1:nusers
    % get the extracted data
    curUserExtracted = extracted(iUser);
    % remove fields not containing only one row of data.
    extfields = fieldnames(curUserExtracted);
    curUserExtracted = struct2table(rmfield(curUserExtracted, ...
        extfields(structfun(@(f) size(f, 1), curUserExtracted) ~= 1)));
    curUserVarnames = curUserExtracted.Properties.VariableNames;
    if ismember('params', curUserVarnames)
        % flatten params
        % extract and remove `params` from original data
        params = curUserExtracted.params;
        curUserExtracted.params = [];
        % remove field with zero size
        parfields = fieldnames(params);
        params = struct2table(rmfield(params, ...
            parfields(structfun(@(f) size(f, 1), params) ~= 1)));
        % add params to the right of curUserExtracted
        curUserExtracted = [curUserExtracted, params]; %#ok<AGROW>
        % update var names
        curUserVarnames = curUserExtracted.Properties.VariableNames;
    end
    % extract `data` from json string
    % `datavarname` is the varible name of data in params
    % `dataprefix` is not empty when there are more than one data string
    curUserId = ids(iUser);
    switch curUserId
        case {99991, 97967} % 'AssocMemory'
            % note '|' is used because all of these cases are possible
            curUserDataVarOpts = 'tconditions|data';
            curUserDataCondPrefix = '';
        case 99986 % 'SemanticMemory'
            curUserDataVarOpts = 'sconditions&tconditions';
            curUserDataCondPrefix = 's&t';
        case {100010, 100018, 97976} % 'DivAten1', 'DivAtten2'
            curUserDataVarOpts = 'lconditions|leftconditions|leftConditions&rconditions|rightconditions|rightConditions';
            curUserDataCondPrefix = 'left&right';
        otherwise
            curUserDataVarOpts = 'conditions|data|detail|datail|llog';
            curUserDataCondPrefix = '';
    end
    % separate all the data conditions
    curUserDataConds = cellfun(@(str) strsplit(str, '|'), strsplit(curUserDataVarOpts, '&'), ...
        'UniformOutput', false);
    % found out the real variable names of all the conditions
    curUserRealDatavar = cellfun(@(strs) curUserVarnames(ismember(curUserVarnames, strs)), curUserDataConds, ...
        'UniformOutput', false);
    % split prefixes
    prefixes = strsplit(curUserDataCondPrefix, '&');
    % extract data when data vars found
    if ~any(cellfun(@isempty, curUserRealDatavar))
        rawstr = cellfun(@(field) curUserExtracted.(field{:}), curUserRealDatavar, 'UniformOutput', false);
    else
        status(iUser) = -1;
        rawstr = repmat({''}, size(curUserRealDatavar));
    end
    % add condition prefixes
    if ~any(cellfun(@isempty, prefixes))
        datastr = cellstr(strjoin(strcat(prefixes, '(', rawstr, ')')));
    else
        datastr = rawstr;
    end
    rec(iUser, KEYVAR) = datastr;
    
    % store alternative variable data
    for iAlt = 1:length(ALTVARS)
        altVar = ALTVARS{iAlt};
        altVarOpts = ALTVARSOPTS{iAlt};
        realAltVar = intersect(altVarOpts, curUserVarnames);
        if ~isempty(realAltVar)
            rec(iUser, altVar) = mat2cell(curUserExtracted.(realAltVar{:}), 1);
        else
            status(iUser) = -2;
        end
    end
end
