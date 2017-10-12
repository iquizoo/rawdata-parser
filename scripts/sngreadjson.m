function [extracted, status] = sngreadjson(filename)
% SNGREADJSON read data from a single json text file.

% status is 0 (everything is okay) by default
status = 0;
% json text file is stored in 'UTF-8' encoding
fid = fopen(filename, 'r', 'n', 'UTF-8');
datastr = fgetl(fid);
fclose(fid);
try
    extracted = struct2table(jsondecode(datastr));
catch
    extracted = table;
    status = -1;
end
