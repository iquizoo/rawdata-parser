function b = str_split(a, para)
%

%Get the useful field values.
delimiter = para.delimiter;
%Delete blanks in the subdelimiter.
subdelimiters = deblank(para.subdelimiters);
colnum = para.colnum;
%Unit of pattern.
unitPat = ['(\-?[\w', subdelimiters,  ']+|', delimiter, ')'];
expr = [repmat([unitPat, delimiter], 1, colnum - 1), unitPat];
if ischar(a)
    a = {a};
end
b = cell(1, length(a));
for i = 1:length(a)
    matchstr = regexp(a{i}, expr, 'tokens');
    matchstr = [matchstr{:}];
    b{i} = reshape(matchstr, colnum, numel(matchstr) / colnum)';
end
