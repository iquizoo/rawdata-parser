function str = num2ord(n)
%NUM2ORD converts number to ordinal number, i.e., 1 -> 1st, 2 -> 2nd.
%   STR = NUM2ORD(N) converts numeric data n to a string. Only scalar
%   numeric is supported now.

str = [num2str(n), 'th'];
str = regexprep(str, '(?<!1)1th', '1st');
str = regexprep(str, '(?<!1)2th', '2nd');
str = regexprep(str, '(?<!1)3th', '3rd');
