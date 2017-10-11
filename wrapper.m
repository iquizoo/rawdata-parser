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
resdir = fullfile(dfltSet.DATARES_DIR, 'ds');
if ~exist(resdir, 'dir'), mkdir(resdir); end

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
if ~all(ismissing(tasks))
    suffix = matlab.lang.makeValidName([rawsuff, '_', char(datetime)]);
else
    suffix = matlab.lang.makeValidName(rawsuff);
end
fprintf('Will use suffix ''%s'' to store data.\n', suffix)
svRawCsvDataPath = fullfile(dfltSet.DATARES_DIR, suffix, 'data');
svRawCsvMetaPath = fullfile(dfltSet.DATARES_DIR, suffix, 'meta');
svResCsvPath = fullfile(dfltSet.DATARES_DIR, suffix, 'res');
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
        data = Preproc(ldRawDataPath, ...
            'TaskNames', tasks, ...
            'DisplayInfo', prompt, ...
            'DebugEntry', dbentry);
        if saveIdx > 2 || ~cntn
            fprintf('Now saving raw data (dataExtract) as file %s...\n', svRawFileName)
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
            % save as .csv for communication
            if ~exist(svRawCsvDataPath, 'dir'), mkdir(svRawCsvDataPath); end
            if ~exist(svRawCsvMetaPath, 'dir'), mkdir(svRawCsvMetaPath); end
            for itask = 1:ntasks
                taskID = data.TaskID(itask);
                taskData = data.Data{itask};
                taskMeta = data.Meta{itask};
                writetable(taskData, fullfile(svRawCsvDataPath, [num2str(taskID), '.csv']), ...
                    'QuoteStrings', true, 'Encoding', 'UTF-8')
                writetable(taskMeta, fullfile(svRawCsvMetaPath, [num2str(taskID), '.csv']), ...
                    'QuoteStrings', true, 'Encoding', 'UTF-8')
            end
            fprintf('Saving done.\n')
        end
        if ~cntn
            warning('on', 'backtrace')
            return
        end
    elseif s < 3 % s = 2 only
        fprintf('Now reading raw data (data) from file %s...\n', ldRawFileName)
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
            fprintf('Now saving processed data (resdata) as file %s...\n', svResFileName)
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
            % save as .csv for communication
            if ~exist(svResCsvPath, 'dir'), mkdir(svResCsvPath); end
            ntasks = height(res);
            for itask = 1:ntasks
                taskID = res.TaskID(itask);
                taskMerge = outerjoin(res.Meta{itask}, res.Results{itask}, 'MergeKeys', true);
                writetable(taskMerge, fullfile(svResCsvPath, [num2str(taskID), '.csv']), ...
                    'QuoteStrings', true, 'Encoding', 'UTF-8')
            end
            fprintf('Saving done.\n')
        end
        if ~cntn
            warning('on', 'backtrace')
            return
        end
%     elseif s < 4 % s = 3 only
%         fprintf('Now reading processed data (resdata) from file %s...\n', ldResFileName)
%         load(ldResFileName, 'resdata')
%         fprintf('Reading done.\n')
%     end
%     if s < 4 % s = 1, 2, 3
%         [indices, results, status, metavars] = Merges(resdata, 'TaskNames', tasks); %#ok<ASGLU>
%         fprintf('Now saving results data (mutiple variables) as file %s...\n', svMrgFileName)
%         mrgVars = {'indices', 'results', 'status', 'metavars'};
%         if saveVerAuto
%             svVarInfo = whos(mrgVars{:});
%             if sum([svVarInfo.bytes]) < 2 ^ 31
%                 saveVer = '-v7';
%             else
%                 saveVer = '-v7.3';
%             end
%             fprintf('Auto save version detected, will use save version: %s.\n', saveVer)
%         end
%         save(svMrgFileName, mrgVars{:}, saveVer)
%         fprintf('Saving done.\n')
    end
end
warning('on', 'backtrace')
