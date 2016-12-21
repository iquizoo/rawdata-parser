function wrapper(varargin)

par = inputParser;
addOptional(par, 's', 1, @isnumeric);
parNames   = {            'Continue'          };
parDflts   = {               true             };
parValFuns = {@(x) islogical(x) | isnumeric(x)};
cellfun(@(x, y, z) addParameter(par, x, y, z), parNames, parDflts, parValFuns);
parse(par, varargin{:});
s    = par.Results.s;
cntn = par.Results.Continue;

% set environmental settings.
dflts
resdir = fullfile(dfltSet.DATARES_DIR, 'ds');
if ~exist(resdir, 'dir')
    mkdir(resdir)
end
warning('off', 'backtrace')
% suffix is a major identifier for data set.
suffix     = inputdlg('Set the suffix of resdata:', 'Suffix settings', 1, {''});
rawdataFN  = fullfile(resdir, ['RawData', suffix{:}]);
procdataFN = fullfile(resdir, ['ProcData', suffix{:}]);
ccdresFN   = fullfile(resdir, ['CCDRes', suffix{:}]);

if s < 2 % s = 1 only
    [rawdataFileName, rawdataFilePath] = uigetfile('*.xlsx', ...
        'Select the file containing the raw data', ...
        ['DATA_RawData\splitted', suffix{:}, '.xlsx']);
    rawdataFullPath = fullfile(rawdataFilePath, rawdataFileName);
    dataExtract = Preproc(rawdataFullPath, 'DisplayInfo', 'text');
    fprintf('Now saving raw data (dataExtract) as file %s...\n', rawdataFN)
    save(rawdataFN, 'dataExtract')
    fprintf('Saving done.\n')
    if ~cntn
        return
    end
elseif s < 3 % s = 2 only
    fprintf('Now reading raw data (dataExtract) from file %s...\n', rawdataFN)
    load(rawdataFN, 'dataExtract')
    fprintf('Reading done.\n')
end
if s < 3 % s = 1, 2
    resdata = Proc(dataExtract, 'DisplayInfo', 'text', 'RemoveAbnormal', true);
    fprintf('Now saving processed data (resdata) as file %s...\n', procdataFN)
    save(procdataFN, 'resdata')
    fprintf('Saving done.\n')
    if ~cntn
        return
    end
elseif s < 4 % s = 3 only
    fprintf('Now reading processed data (resdata) from file %s...\n', procdataFN)
    load(procdataFN, 'resdata')
    fprintf('Reading done.\n')
end
if s < 4 % s = 1, 2, 3
    [mrgdata, scores, indices, taskstat, metavars] = Merges(resdata); %#ok<ASGLU>
    fprintf('Now saving results data (mutiple variables) as file %s...\n', ccdresFN)
    save(ccdresFN, 'mrgdata', 'scores', 'indices', 'taskstat', 'metavars')
    fprintf('Saving done.\n')
else % s >= 4
    error('UDF:INPUTPARERR', 'Start number larger than 3 is not supported now.\n')
end
