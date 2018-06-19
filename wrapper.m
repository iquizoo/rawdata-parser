function wrapper(varargin)
%WRAPPER shows a method to a batch job of processing of data.

%   By Zhang, Liang. E-mail:psychelzh@gmail.com

% parse input arguments
par = inputParser;
addOptional(par, 's', 1, @isnumeric);
addParameter(par, 'DataSuffix', '', @ischar) % required when s > 1
addParameter(par, 'Continue', true, @(x) islogical(x) | isnumeric(x))
addParameter(par, 'TaskNames', '', @(x) ischar(x) | iscellstr(x) | isstring(x) | isnumeric(x))
addParameter(par, 'DisplayInfo', 'text', @ischar)
addParameter(par, 'DebugEntry', [], @isnumeric)
addParameter(par, 'Method', 'full', @ischar)
addParameter(par, 'SaveAction', 3, @isnumeric)
addParameter(par, 'SaveVersion', 'auto', @ischar)
parse(par, varargin{:});
s        = par.Results.s;
rawsuff  = par.Results.DataSuffix;
cntn     = par.Results.Continue;
tasks    = par.Results.TaskNames;
prompt   = lower(par.Results.DisplayInfo);
dbentry  = par.Results.DebugEntry;
method   = par.Results.Method;
saveIdx  = par.Results.SaveAction;
saveVer  = par.Results.SaveVersion;
saveVerAuto = strcmp(saveVer, 'auto');
% load default settings
dflts
% path to store data as matlab binary files
resdir = fullfile(dfltSet.DATARES_DIR, 'ds');
if ~exist(resdir, 'dir'), mkdir(resdir); end
% path to store data as human readable excel spreadsheat files
humandir = fullfile(dfltSet.DATARES_DIR, 'readable');
if ~exist(humandir, 'dir'), mkdir(humandir); end
rawdir = fullfile(dfltSet.DATARAW_DIR, dfltSet.PARSED_DIR);
% check input values
if isempty(rawsuff)
    if s < 2
        rawdataPath = uigetdir(rawdir, 'Select rawdata path');
        if isnumeric(rawdataPath)
            error('UDF:WRAPPER:DATASOURCEMISSING', 'No data files selected.')
        end
        rawsuff = rawdataPath(length(rawdir) + 2:end);
    else
        rawsuff = inputdlg('Input suffix for your raw data:', 'Data suffix input');
        if isempty(rawsuff)
            error('UDF:WRAPPER:EMPTYRAWSUFF', 'No raw suffix is specified.')
        end
        rawsuff = rawsuff{:};
    end
end
% set environmental settings.
if ~all(ismissing(tasks))
    suffix = matlab.lang.makeValidName([rawsuff, '_', char(datetime)]);
else
    suffix = matlab.lang.makeValidName(rawsuff);
end
fprintf('Will use suffix ''%s'' to store data.\n', suffix)
svRawXlsDataPath = fullfile(humandir, suffix, 'data');
svRawXlsMetaPath = fullfile(humandir, suffix, 'meta');
svResXlsPath = fullfile(humandir, suffix, 'res');
rawFilePrefix = 'raw_';
resFilePrefix = 'res_';
% mrgFilePrefix = 'mrg_';
svRawFileName = fullfile(resdir, [rawFilePrefix, suffix]);
svResFileName = fullfile(resdir, [resFilePrefix, suffix]);
% svMrgFileName = fullfile(resdir, [mrgFilePrefix, suffix]);
ldRawDataPath = fullfile(rawdir, rawsuff);
ldRawFileName = fullfile(resdir, [rawFilePrefix, rawsuff]);
% ldResFileName = fullfile(resdir, [resFilePrefix, suffix]);
% start by checking the starting point
if s >= 4
    error('UDF:INPUTPARERR', 'Start number larger than 3 is not supported now.\n')
else
    warning('off', 'backtrace')
    if s < 2 % s = 1 only
        load(fullfile(ldRawDataPath, 'raw'), 'extracted')
        data = Preproc(extracted, ...
            'TaskNames', tasks, ...
            'DisplayInfo', prompt, ...
            'DebugEntry', dbentry);
        if saveIdx > 2 || ~cntn
            fprintf('Now saving raw data (dataExtract) as file %s.mat...\n', svRawFileName)
            svVars = {'data'};
            if saveVerAuto
                svVarInfo = whos(svVars{:});
                if sum([svVarInfo.bytes]) < 2 ^ 31
                    saveVer = '-v7';
                else
                    saveVer = '-v7.3';
                end
                fprintf('Auto save version detected, will use save version: %s.\n', saveVer)
            end
            save(svRawFileName, svVars{:}, saveVer)
            % save as .mat for precision
            ntasks = height(data);
            % save as .xlsx for communication
            fprintf('Now saving raw data as Excel files to %s...\n', humandir)
            if ~exist(svRawXlsDataPath, 'dir'), mkdir(svRawXlsDataPath); end
            if ~exist(svRawXlsMetaPath, 'dir'), mkdir(svRawXlsMetaPath); end
            for itask = 1:ntasks
                taskID = data.TaskID(itask);
                taskIDName = data.TaskIDName{itask};
                svRawXlsName = sprintf('%s(%d).xlsx', taskIDName, taskID);
                taskData = data.Data{itask};
                taskMeta = data.Meta{itask};
                if ~isempty(taskData)
                    writetable(taskData, fullfile(svRawXlsDataPath, svRawXlsName)); %, ...
                    % 'QuoteStrings', true, 'Encoding', 'UTF-8')
                    writetable(taskMeta, fullfile(svRawXlsMetaPath, svRawXlsName)); %, ...
                    % 'QuoteStrings', true, 'Encoding', 'UTF-8')
                end
            end
            fprintf('Saving done.\n')
        end
        if ~cntn
            warning('on', 'backtrace')
            return
        end
    elseif s < 3 % s = 2 only
        fprintf('Now reading raw data (data) from file %s.mat...\n', ldRawFileName)
        load(ldRawFileName, 'data')
        fprintf('Reading done.\n')
    end
    if s < 3 % s = 1, 2
        if s == 1 && ~isempty(dbentry), dbentry = 1; end
        res = Proc(data, ...
            'TaskNames', tasks, ....
            'DisplayInfo', prompt, ...
            'Method', method, ...
            'DebugEntry', dbentry);
        if saveIdx > 1 || ~cntn
            fprintf('Now saving processed data (resdata) as file %s.mat...\n', svResFileName)
            svVars = {'res'};
            if saveVerAuto
                svVarInfo = whos(svVars{:});
                if sum([svVarInfo.bytes]) < 2 ^ 31
                    saveVer = '-v7';
                else
                    saveVer = '-v7.3';
                end
                fprintf('Auto save version detected, will use save version: %s.\n', saveVer)
            end
            % save as .mat for precision
            save(svResFileName, svVars{:}, saveVer)
            % save as .xlsx for communication
            fprintf('Now saving processed data as Excel files to %s...\n', humandir)
            if ~exist(svResXlsPath, 'dir'), mkdir(svResXlsPath); end
            ntasks = height(res);
            for itask = 1:ntasks
                taskID = res.TaskID(itask);
                taskIDName = res.TaskIDName{itask};
                svResXlsName = sprintf('%s(%d).xlsx', taskIDName, taskID);
                if ~isempty(res.Results{itask})
                    taskMerge = outerjoin(res.Meta{itask}, res.Results{itask}, 'MergeKeys', true);
                    writetable(taskMerge, fullfile(svResXlsPath, svResXlsName))
                end
            end
            fprintf('Saving done.\n')
        end
        if ~cntn
            warning('on', 'backtrace')
            return
        end
    end
end
warning('on', 'backtrace')
