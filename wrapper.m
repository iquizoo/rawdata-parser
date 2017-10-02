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
addParameter(par, 'RemoveAbnormal', false, @(x) islogical(x) | isnumeric(x))
addParameter(par, 'SaveAction', 3, @isnumeric)
addParameter(par, 'SaveVersion', '-v7', @ischar)
parse(par, varargin{:});
s        = par.Results.s;
rawsuff  = par.Results.DataSuffix;
cntn     = par.Results.Continue;
tasks    = par.Results.TaskNames;
prompt   = lower(par.Results.DisplayInfo);
dbentry  = par.Results.DebugEntry;
method   = par.Results.Method;
rmanml   = par.Results.RemoveAbnormal;
saveIdx  = par.Results.SaveAction;
saveVer  = par.Results.SaveVersion;
% load default settings
dflts
resdir = fullfile(dfltSet.DATARES_DIR, 'ds');
rawdir = dfltSet.DATARAW_DIR;
% check input values
if isempty(rawsuff)
    if s < 2
        rawdataPath = uigetdir(rawdir, 'Select rawdata path');
        rawsuff = rawdataPath(length(rawdir) + 2:end);
    else
        rawsuff = inputdlg('Input suffix for your raw data:', 'Data suffix input');
        rawsuff = rawsuff{:};
    end
end
% set environmental settings.
suffix = matlab.lang.makeValidName(rawsuff);
fprintf('Will use suffix ''%s'' to store data.\n', suffix)
if ~exist(resdir, 'dir'), mkdir(resdir); end
rawFilePrefix = 'raw_';
resFilePrefix = 'res_';
mrgFilePrefix = 'mrg_'
svRawFileName = fullfile(resdir, [rawFilePrefix, suffix]);
svResFileName = fullfile(resdir, [resFilePrefix, suffix]);
svMrgFileName = fullfile(resdir, [mrgFilePrefix, suffix]);
ldRawDataPath = fullfile(rawdir, rawsuff);
ldRawFileName = fullfile(resdir, [rawFilePrefix, suffix]);
ldResFileName = fullfile(resdir, [resFilePrefix, suffix]);
% start by checking the starting point
if s >= 4
    error('UDF:INPUTPARERR', 'Start number larger than 3 is not supported now.\n')
else
    warning('off', 'backtrace')
    if s < 2 % s = 1 only
        dataExtract = Preproc(ldRawDataPath, ...
            'TaskNames', tasks, ...
            'DisplayInfo', prompt, ...
            'DebugEntry', dbentry);
        if saveIdx > 2 || ~cntn
            fprintf('Now saving raw data (dataExtract) as file %s...\n', svRawFileName)
            save(svRawFileName, 'dataExtract', saveVer)
            fprintf('Saving done.\n')
        end
        if ~cntn
            return
        end
    elseif s < 3 % s = 2 only
        fprintf('Now reading raw data (dataExtract) from file %s...\n', ldRawFileName)
        load(ldRawFileName, 'dataExtract')
        fprintf('Reading done.\n')
    end
    if s < 3 % s = 1, 2
        if s == 1 && ~isempty(dbentry), dbentry = 1; end
        resdata = Proc(dataExtract, ...
            'TaskNames', tasks, ....
            'DisplayInfo', prompt, ...
            'RemoveAbnormal', rmanml, ...
            'Method', method, ...
            'DebugEntry', dbentry);
        if saveIdx > 1 || ~cntn
            fprintf('Now saving processed data (resdata) as file %s...\n', svResFileName)
            save(svResFileName, 'resdata', saveVer)
            fprintf('Saving done.\n')
        end
        if ~cntn
            return
        end
    elseif s < 4 % s = 3 only
        fprintf('Now reading processed data (resdata) from file %s...\n', ldResFileName)
        load(ldResFileName, 'resdata')
        fprintf('Reading done.\n')
    end
    if s < 4 % s = 1, 2, 3
        [indices, results, status, metavars] = Merges(resdata, 'TaskNames', tasks); %#ok<ASGLU>
        fprintf('Now saving results data (mutiple variables) as file %s...\n', svMrgFileName)
        save(svMrgFileName, 'indices', 'results', 'status', 'metavars', saveVer)
        fprintf('Saving done.\n')
    end
end
warning('on', 'backtrace')
