function wrapper(varargin)
%WRAPPER shows a method to a batch job of processing of data.

%   By Zhang, Liang. E-mail:psychelzh@gmail.com

% parse input arguments
par = inputParser;
addOptional(par, 's', 0, @isnumeric);
% full file name of the exported raw data (.json/.xlsx)
addParameter(par, 'Source', '', @ischar)
% the project name is used to identify datasets, if the name of the raw
% dataset is okay, there is no need to specify it.
addParameter(par, 'ProjectName', '', @ischar) % required when s > 1
addParameter(par, 'Continue', true, @(x) islogical(x) | isnumeric(x))
addParameter(par, 'TaskNames', '', @(x) ischar(x) | iscellstr(x) | isstring(x) | isnumeric(x))
addParameter(par, 'DisplayInfo', 'text', @ischar)
addParameter(par, 'DebugEntry', [], @isnumeric)
addParameter(par, 'Method', 'full', @ischar)
% SaveAction should be specified as 'internal' (default), 'external' or
% 'both'. When 'Continue' is false, 'both' is forcefully used.
addParameter(par, 'SaveAction', 'internal', @ischar)
addParameter(par, 'SaveVersion', 'auto', @ischar)
parse(par, varargin{:});
s        = par.Results.s;
src      = par.Results.Source;
prjname  = par.Results.ProjectName;
cntn     = par.Results.Continue;
tasks    = par.Results.TaskNames;
prompt   = lower(par.Results.DisplayInfo);
dbentry  = par.Results.DebugEntry;
method   = par.Results.Method;
saveIdx  = par.Results.SaveAction;
saveVer  = par.Results.SaveVersion;
saveVerAuto = strcmp(saveVer, 'auto');
if ~ismember(saveIdx, {'internal', 'external', 'both'})
    warning('UDF:WRAPPER:WrongSaveAction', ...
        ['Only ''internal'', ''external'' and ''both'' are supported save actions. ' ...
        'Will continue by using ''internal'' option.'])
    saveIdx = 'internal';
end
% load default settings
iosettings = jsondecode(fileread('config\paramio.json'));
% path to raw data
rawdir = fullfile(iosettings.raw.base, iosettings.raw.exported);
% path to data stored as matlab binary files
targetdir = fullfile(iosettings.results.base, iosettings.results.target);
if ~exist(targetdir, 'dir'), mkdir(targetdir); end
% debug result files
debugdir = fullfile(iosettings.results.base, iosettings.results.debug);
if ~exist(debugdir, 'dir'), mkdir(debugdir); end
% when debugging, results will be stored to another folder
if ~all(ismissing(tasks)) || ~isempty(dbentry)
    debug = true;
    targetdir = fullfile(debugdir, char(datetime));
else
    debug = false;
end
% path to data stored as human readable excel spreadsheat files
humandir = fullfile(iosettings.results.base, iosettings.results.readable);
if ~exist(humandir, 'dir'), mkdir(humandir); end
if s < 1 % s == 0 only
    % raw data need to be parsed, source should be specified
    if isempty(src)
        % ask for input type
        src_type = questdlg('What type of source?', 'Input checking', 'File', 'Folder', 'Cancel', 'File');
        switch src_type
            case 'File'
                [fnames, pathname] = uigetfile({ ...
                    '*.xlsx;*.json', 'Excel/JSON Data (*.xlsx, *.json)'; ...
                    '*.json', 'JSON Data Files (*.json)'; ...
                    '*.xlsx', 'Excel Data Files (*.xlsx)'; ...
                    }, ...
                    'Please select the file containing source data.', rawdir, ...
                    'MultiSelect', 'on');
                if isnumeric(fnames)
                    error('UDF:READRAW:DATASOURCEMISSING', 'No data files selected.')
                end
                src = fullfile(pathname, fnames);
            case 'Folder'
                src = uigetdir(rawdir, 'Please select the folder of source data.');
                if isnumeric(src)
                    error('UDF:READRAW:DATASOURCEMISSING', 'No data path selected.')
                end
            case 'Cancel'
                fprintf('User canceled. Returning.\n')
                return
        end
    end
end
% try to use source folder/file name (if specified) as project name
if isempty(prjname) && ~isempty(src)
    [~, prjname_candidate] = fileparts(src);
    % check if it is a valid variable name
    if ~isvarname(prjname_candidate)
        namechk = questdlg(...
            ['Auto-extracted name is not a valid variabel name. '...
            'What do you think?'], ... % message
            'Name checking', ... % name
            'Use it anyway', ... % option 1
            'Make it valid and use it', ... % option 2
            'Cancel', ... % option 3
            'Cancel'); % default option
        switch namechk
            case 'Make it valid and use it'
                prjname_candidate = matlab.lang.makeValidName(prjname_candidate);
            case 'Cancel'
                prjname_candidate = '';
        end
    end
    prjname = prjname_candidate;
end
% check if the folder exists
if ~isempty(prjname)
    if exist(fullfile(targetdir, prjname), 'dir')
        warning('UDF:WRAPPER:OverwriteTargetFolder', ...
            'The specified project name ''%s'' existed, will overwrite it', ...
            prjname);
    end
else
    prjname = inputdlg('Input project name to identify your data:', 'Project name input');
    if isempty(prjname)
        error('UDF:WRAPPER:MissPrjName', ...
            'Fatal error! You must specify a valid name for your data.')
    end
    prjname = prjname{:};
end
% specify the folder to store processed data
internal_dest = fullfile(targetdir, prjname);
if ~exist(internal_dest, 'dir'), mkdir(internal_dest); end
external_dest = fullfile(humandir, prjname);
if ~exist(external_dest, 'dir'), mkdir(external_dest); end
% start by checking the starting point
if s >= 4
    error('UDF:INPUTPARERR', 'Start number larger than 3 is not supported now.\n')
else
    warning('off', 'backtrace')
    if s < 1 % s = 0 only
        extracted = ReadRaw('Source', src);
        % save as .mat for precision
        if strcmp(saveIdx, 'internal') || strcmp(saveIdx, 'both') || ~cntn
            fprintf('Now saving raw data (extracted) as file ''%s.mat''...\n', ...
                iosettings.results.savename{1})
            if saveVerAuto
                svVarInfo = whos(iosettings.results.savevar{1});
                if sum([svVarInfo.bytes]) < 2 ^ 31
                    saveVer = '-v7';
                else
                    saveVer = '-v7.3';
                end
                fprintf('Auto save version detected, will use save version: %s.\n', saveVer)
            end
            save(fullfile(internal_dest, iosettings.results.savename{1}), ...
                iosettings.results.savevar{1}, saveVer)
            fprintf('Saving done.\n')
        end
        % save as .xlsx for communication (only when not in debugging mode)
        if ~debug
            if strcmp(saveIdx, 'external') || strcmp(saveIdx, 'both') || ~cntn
                fprintf('Now saving raw data as Excel files to %s...\n', humandir)
                % TODO
                fprintf('Saving done.\n')
            end
        end
        if ~cntn
            warning('on', 'backtrace')
            return
        end
    elseif s < 2 % s = 1 only
        raw_filename = fullfile(internal_dest, iosettings.results.savename{1});
        fprintf('Now reading raw data (data) from file ''%s.mat''...\n', raw_filename)
        load(raw_filename, iosettings.results.savevar{1})
        fprintf('Reading done.\n')
    end
    if s < 2 % s = 0, 1
        data = Preproc(extracted, ...
            'TaskNames', tasks, ...
            'DisplayInfo', prompt, ...
            'DebugEntry', dbentry);
        % save as .mat for precision
        if strcmp(saveIdx, 'internal') || strcmp(saveIdx, 'both') || ~cntn
            fprintf('Now saving parsed data (dataExtract) as file ''%s.mat''...\n', ...
                iosettings.results.savename{2})
            if saveVerAuto
                svVarInfo = whos(iosettings.results.savevar{2});
                if sum([svVarInfo.bytes]) < 2 ^ 31
                    saveVer = '-v7';
                else
                    saveVer = '-v7.3';
                end
                fprintf('Auto save version detected, will use save version: %s.\n', saveVer)
            end
            save(fullfile(internal_dest, iosettings.results.savename{2}), ...
                iosettings.results.savevar{2}, saveVer)
            fprintf('Saving done.\n')
        end
        % save as .xlsx for communication
        if strcmp(saveIdx, 'external') || strcmp(saveIdx, 'both') || ~cntn
            fprintf('Now saving raw data as Excel files to %s...\n', humandir)
            ntasks = height(data);
            for itask = 1:ntasks
                taskID = data.TaskID(itask);
                taskIDName = data.TaskIDName{itask};
                svRawShtName = sprintf('%s_%d', taskIDName, taskID);
                taskData = data.Data{itask};
                taskMeta = data.Meta{itask};
                if ~isempty(taskData)
                    writetable(taskData, ...
                        fullfile(external_dest, 'raw_data.xlsx'), ...
                        'Sheet', svRawShtName);
                    writetable(taskMeta, ...
                        fullfile(external_dest, 'meta_data.xlsx'), ...
                        'Sheet', svRawShtName);
                end
            end
            fprintf('Saving done.\n')
        end
        if ~cntn
            warning('on', 'backtrace')
            return
        end
    elseif s < 3 % s = 2 only
        parsed_filename = fullfile(internal_dest, iosettings.results.savename{2});
        fprintf('Now reading parsed data (data) from file ''%s.mat''...\n', parsed_filename)
        load(parsed_filename, iosettings.results.savevar{2})
        fprintf('Reading done.\n')
    end
    if s < 3 % s = 1, 2
        if s == 1 && ~isempty(dbentry), dbentry = 1; end
        res = Proc(data, ...
            'TaskNames', tasks, ....
            'DisplayInfo', prompt, ...
            'Method', method, ...
            'DebugEntry', dbentry);
        % save as .mat for precision
        if strcmp(saveIdx, 'internal') || strcmp(saveIdx, 'both') || ~cntn
            fprintf('Now saving processed data (resdata) as file ''%s.mat''...\n', ...
                iosettings.results.savename{3})
            if saveVerAuto
                svVarInfo = whos(iosettings.results.savevar{3});
                if sum([svVarInfo.bytes]) < 2 ^ 31
                    saveVer = '-v7';
                else
                    saveVer = '-v7.3';
                end
                fprintf('Auto save version detected, will use save version: %s.\n', saveVer)
            end
            save(fullfile(internal_dest, iosettings.results.savename{3}), ...
                iosettings.results.savevar{3}, saveVer)
            fprintf('Saving done.\n')
        end
        % save as .xlsx for communication
        if strcmp(saveIdx, 'external') || strcmp(saveIdx, 'both') || ~cntn
            fprintf('Now saving processed data as Excel files to %s...\n', humandir)
            ntasks = height(res);
            for itask = 1:ntasks
                taskID = res.TaskID(itask);
                taskIDName = res.TaskIDName{itask};
                svResShtName = sprintf('%s_%d', taskIDName, taskID);
                if ~isempty(res.Results{itask})
                    taskMerge = outerjoin(res.Meta{itask}, res.Results{itask}, 'MergeKeys', true);
                    writetable(taskMerge, ...
                        fullfile(external_dest, 'res_data.xlsx'), ...
                        'Sheet', svResShtName)
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
