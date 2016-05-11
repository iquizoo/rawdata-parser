function r = isnum(a)
%Determine if a is a numeric string, or numeric data.
if (isnumeric(a))
    r = 1;
else
    o = str2double(a);
    r = ~isnan(o);
end
