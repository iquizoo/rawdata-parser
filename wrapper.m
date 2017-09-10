function wrapper(varargin)
%WRAPPER shows a method to a batch job of processing of data.
%
%   Note: data were saved in v7.3 format, which is only supported by R2006b
%   or later.

%   By Zhang, Liang. E-mail:psychelzh@gmail.com

% parse input arguments
par = inputParser;
addOptional(par, 's', 1, @isnumeric);
addParameter(par, 'DataPath', '', @ischar)
addParameter(par, 'Continue', true, @(x) islogical(x) | isnumeric(x))
addParameter(par, 'TaskNames', '', @(x) ischar(x) | iscellstr(x))
addParameter(par, 'DisplayInfo', 'text', @ischar)
addParameter(par, 'DebugEntry', [], @isnumeric)
addParameter(par, 'Method', 'full', @ischar)
addParameter(par, 'RemoveAbnormal', true, @(x) islogical(x) | isnumeric(x))
addParameter(par, 'SaveAction', 2, @isnumeric)
addParameter(par, 'SaveVersion', '', @ischar)
parse(par, varargin{:});
s        = par.Results.s;
datapath = par.Results.DataPath;
cntn     = par.Results.Continue;
tasks    = cellstr(par.Results.TaskNames);
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
if isempty(saveVer), saveVer = '-v7'; end
if isempty(datapath)
    rawdataPath = uigetdir(rawdir, 'Select rawdata path');
    datapath = rawdataPath(length(rawdir) + 2:end);
end
% set environmental settings.
suffix = matlab.lang.makeValidName(datapath);
fprintf('Will use suffix ''%s'' to store data.\n', suffix)
if ~exist(resdir, 'dir'), mkdir(resdir); end
svRawFileName  = fullfile(resdir, ['RawData', suffix]);
svProcFileName = fullfile(resdir, ['ProcData', suffix]);
svResFileName  = fullfile(resdir, ['CCDRes', suffix]);
ldRawDataPath  = fullfile(rawdir, datapath);
ldRawFileName  = fullfile(resdir, ['RawData', suffix]);
ldProcFileName = fullfile(resdir, ['ProcData', suffix]);
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
            fprintf('Now saving processed data (resdata) as file %s...\n', svProcFileName)
            save(svProcFileName, 'resdata', saveVer)
            fprintf('Saving done.\n')
        end
        if ~cntn
            return
        end
    elseif s < 4 % s = 3 only
        fprintf('Now reading processed data (resdata) from file %s...\n', ldProcFileName)
        load(ldProcFileName, 'resdata')
        fprintf('Reading done.\n')
    end
    if s < 4 % s = 1, 2, 3
        [indStruct, mrgStruct, statStruct, metavars] = Merges(resdata, 'TaskNames', tasks); %#ok<ASGLU>
        fprintf('Now saving results data (mutiple variables) as file %s...\n', svResFileName)
        save(svResFileName, 'indStruct', 'mrgStruct', 'statStruct', 'metavars', saveVer)
        fprintf('Saving done.\n')
    end
end
warning('on', 'backtrace')
