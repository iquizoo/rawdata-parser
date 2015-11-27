function b = str2table(a)
%For sdk parameters.

if strcmp(a, '-') || any(isnan(a))
    b = table;
    return
end
%Match variable names of output table.
match_str  = regexp(a, '[a-zA-Z]+', 'match');
num_var    = length(match_str);

%Match data of output table.
match_data = cellfun(@str2double, regexp(a, '[\d\.]+', 'match'), 'UniformOutput', false);
num_data   = length(match_data);

%Empty padding.
if num_data < num_var
    match_data = [match_data, cell(1, num_var - num_data)];
end

b = cell2table(match_data, 'VariableNames', match_str);