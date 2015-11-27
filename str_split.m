function b = str_split(a, delimiter, colnum)
%

expr = [repmat(['(\-?\w+|:)', delimiter], 1, colnum - 1), '(\-?\w+)'];
b = cell(1, length(a));
for i = 1:length(a)
    matchstr = regexp(a{i}, expr, 'tokens');
    matchstr = [matchstr{:}];
    b{i} = reshape(matchstr, colnum, numel(matchstr) / colnum)';
end
