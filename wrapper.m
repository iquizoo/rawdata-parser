function wrapper(varargin)
%WRAPPER shows a method to a batch job of processing of data.
%
%   Note: data were saved in v7.3 format, which is only supported by R2006b
%   or later.

%   By Zhang, Liang. E-mail:psychelzh@gmail.com

par = inputParser;
addOptional(par, 's', 1, @isnumeric);
parNames   = {            'Continue',                      'TaskNames',      'DisplayInfo', 'DebugEntry',          'RemoveAbnormal',      'SaveAction', 'SaveVersion'};
parDflts   = {               true   ,                          '',             'text',           [],                   false,                     2 ,        ''      };
parValFuns = {@(x) islogical(x) | isnumeric(x), @(x) ischar(x) | iscellstr(x), @ischar,       @isnumeric, @(x) islogical(x) | isnumeric(x),  @isnumeric, @ischar     };
cellfun(@(x, y, z) addParameter(par, x, y, z), parNames, parDflts, parValFuns);
parse(par, varargin{:});
s        = par.Results.s;
cntn     = par.Results.Continue;
tasks    = cellstr(par.Results.TaskNames);
prompt   = lower(par.Results.DisplayInfo);
dbentry  = par.Results.DebugEntry;
rmanml   = par.Results.RemoveAbnormal;
saveIdx  = par.Results.SaveAction;
saveVer  = par.Results.SaveVersion;
if isempty(saveVer)
    saveVer = '-v7';
end

% set environmental settings.
dflts
resdir = fullfile(dfltSet.DATARES_DIR, 'ds');
if ~exist(resdir, 'dir')
    mkdir(resdir)
end
warning('off', 'backtrace')
% suffix is a major identifier for data set.
suffixOrig = inputdlg('Set the suffix of resdata:', 'Suffix settings', 1, {''});
tasks(cellfun(@isempty, tasks)) = [];
if ~isempty(tasks)
    if length(tasks) == 1
        tasks = tasks{:};
        suffix = strcat(suffixOrig, tasks);
    else
        suffix = strcat(suffixOrig, matlab.lang.makeValidName(char(datetime)));
    end
else
    suffix = suffixOrig;
end
fprintf('Will use suffix ''%s'' to store data.\n', suffix{:})
svRawFileName  = fullfile(resdir, ['RawData', suffix{:}]);
svProcFileName = fullfile(resdir, ['ProcData', suffix{:}]);
svResFileName  = fullfile(resdir, ['CCDRes', suffix{:}]);
ldRawFileName  = fullfile(resdir, ['RawData', suffixOrig{:}]);
ldProcFileName = fullfile(resdir, ['ProcData', suffixOrig{:}]);

if s < 2 % s = 1 only
    [rawdataFileName, rawdataFilePath] = uigetfile('*.xlsx', ...
        'Select the file containing the raw data', ...
        ['DATA_RawData\splitted', suffixOrig{:}, '.xlsx']);
    rawdataFullPath = fullfile(rawdataFilePath, rawdataFileName);
    dataExtract = Preproc(rawdataFullPath, ...
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
    [indStruct, mrgStruct, statStruct, metavars] = Merges(resdata); %#ok<ASGLU>
    fprintf('Now saving results data (mutiple variables) as file %s...\n', svResFileName)
    save(svResFileName, 'indStruct', 'mrgStruct', 'statStruct', 'metavars', saveVer)
    fprintf('Saving done.\n')
else % s >= 4
    error('UDF:INPUTPARERR', 'Start number larger than 3 is not supported now.\n')
end
warning('on', 'backtrace')
