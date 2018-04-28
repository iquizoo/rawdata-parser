function ReadRaw(varargin)
%READRAWXLS transforms the excel files in `src` to `dest`.

% start stopwatch.
tic

% parse input arguments
par = inputParser;
addParameter(par, 'Source', '', @ischar)
addParameter(par, 'Destination', '', @ischar)
addParameter(par, 'DisplayInfo', 'text', @ischar)
addParameter(par, 'NumSamples', 0, @isnumeric)
parse(par, varargin{:})
src = par.Results.Source;
dest = par.Results.Destination;
prompt = lower(par.Results.DisplayInfo);
nspl = par.Results.NumSamples;

% add helper functions folder
HELPERFUNPATH = 'scripts';
addpath(HELPERFUNPATH);

% metavars options
METAVAR_OPTS = {'Taskname|taskName', 'excerciseId', 'userId', 'name', 'gender|sex', 'school', 'grade', 'cls', 'birthDay', 'createDate|createTime'};
METAVAR_NAMES = {'taskName', 'excerciseId', 'userId', 'name', 'sex', 'school', 'grade', 'cls', 'birthDay', 'createTime'};
METAVAR_TYPES = {'string', 'double', 'double', 'string', 'categorical', 'string', 'string', 'string', 'datetime', 'datetime'};
KEY_TASKID_VAR = 'excerciseId';

% check source and destination input
if isempty(src)
    % ask for input type
    choice = questdlg('What type of source?', 'Input checking', 'File', 'Folder', 'Cancel', 'File');
    switch choice
        case 'File'
            [fnames, pathname] = uigetfile({ ...
                '*.xlsx;*.json', 'Excel/JSON Data (*.xlsx, *.json)'; ...
                '*.json', 'JSON Data Files (*.json)'; ...
                '*.xlsx', 'Excel Data Files (*.xlsx)'; ...
                }, ...
                'Please select the file containing source data.', 'DATA_RawData', 'MultiSelect', 'on');
            if isnumeric(fnames)
                error('UDF:READRAW:DATASOURCEMISSING', 'No data files selected.')
            end
            src = fullfile(pathname, fnames);
        case 'Folder'
            src = uigetdir('DATA_RawData', 'Please select the folder of source data.');
            if isnumeric(src)
                error('UDF:READRAW:DATASOURCEMISSING', 'No data path selected.')
            end
        case 'Cancel'
            fprintf('User canceled. Returning.\n')
            rmpath(HELPERFUNPATH)
            return
    end
end
if isempty(dest)
    dest = uigetdir('DATA_RawData', 'Please select the folder of destination data.');
    if isnumeric(dest)
        error('UDF:READRAW:DATADESTMISSING', 'No data destination selected.')
    end
end

% get all the data file names
if ~iscell(src) && isfolder(src)
    files = dir(src);
    filefullnames = regexp(fullfile({files.folder}, {files.name}), ...
        '.+\.(xlsx|json)$', 'once', 'match');
    filefullnames(ismissing(filefullnames)) = [];
else
    filefullnames = cellstr(src);
end

% rate of progress display initialization
switch prompt
    case 'waitbar'
        hwb = waitbar(0, 'Begin processing the tasks specified by users...Please wait...', ...
            'Name', 'Preprocess raw data of CCDPro',...
            'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
        setappdata(hwb, 'canceling', 0)
    case 'text'
        except  = false;
        dispinfo = '';
end

% total file numbers
nfiles = length(filefullnames);
% variables for progressing statistics
nprocessed = 0;
fprintf('The total number of raw data files is %d.\n', nfiles);

% excel files part
% preallocate
extracted = table;
% record the time elapsed when preparation is done
preparationTime = toc;
% process file by file
for ifile = 1:nfiles
    initialVars = who;
    curFileFullname = filefullnames{ifile};
    [~, curFilename, curFiletype] = fileparts(curFileFullname);

    % update prompt information.
    completePercent = nprocessed / nfiles;
    if nprocessed == 0
        msgSuff = 'Please wait...';
    else
        elapsedTime = toc - preparationTime;
        eta = seconds2human(elapsedTime * (1 - completePercent) / completePercent, 'full');
        msgSuff = strcat('TimeRem:', eta);
    end
    switch prompt
        case 'waitbar'
            % Check for Cancel button press.
            if getappdata(hwb, 'canceling')
                fprintf('User canceled...\n');
                break
            end
            %Update message in the waitbar.
            msg = sprintf('File: %s. %s', curFilename, msgSuff);
            waitbar(completePercent, hwb, msg);
        case 'text'
            if ~except
                fprintf(repmat('\b', 1, length(dispinfo)));
            end
            dispinfo = sprintf('Now processing %s (total: %d) file: %s. %s\n', ...
                num2ord(nprocessed + 1), nfiles, ...
                curFilename, msgSuff);
            fprintf(dispinfo);
            except = false;
    end
    nprocessed = nprocessed + 1;

    % data reading
    switch curFiletype
        case '.xlsx'
            if nspl <= 0
                % 2 ^ 20 is the maximal number of rows.
                nspl = nspl + 2 ^ 20 - 1;
            end
            % set read options
            readRange = ['1:', num2str(nspl + 1)];
            opts = detectImportOptions(curFileFullname, 'Range', readRange);
            % extract data from file
            [curFileExtract, status] = sngreadxls(curFileFullname, opts);
        case '.json'
            % extract data from file
            [curFileExtract, status] = sngreadjson(curFileFullname);
            % extract selected samples
            nusers = height(curFileExtract);
            if nspl <= 0
                nspl = nspl + nusers;
            end
            curFileExtract = curFileExtract(1:(min(nspl, nusers)), :);
    end

    % check reading status
    if any(status == -1)
        except = true;
        warning('UDF:READRAWXLS:DATAMISSING', 'Data of some users (total: %d) lost in file %s.', ...
            sum(status == -1), curFileFullname);
    end
    % checking metadata type
    curFileVarNamesRaw = curFileExtract.Properties.VariableNames;
    for imetavar = 1:length(METAVAR_OPTS)
        curMetavarOpts = split(METAVAR_OPTS{imetavar}, '|');
        curMetavarNameReal = intersect(curMetavarOpts, curFileVarNamesRaw);
        % get the legal name and check its type
        curMetavarNameLegal = METAVAR_NAMES{imetavar};
        curMetavarClass = METAVAR_TYPES{imetavar};
        % do things condition on the metadata existence
        if ~isempty(curMetavarNameReal)
            % change meta varname to the legal one
            curFileExtract.Properties.VariableNames{curMetavarNameReal{:}} = curMetavarNameLegal;
            curMetadataOrig = curFileExtract.(curMetavarNameLegal);
            curMetadataTrans = curMetadataOrig;
            if ~isa(curMetadataOrig, curMetavarClass)
                % convert non-character to character for cell type
                if iscell(curMetadataOrig)
                    noncharLoc = ~cellfun(@ischar, curMetadataOrig);
                    curMetadataOrig(noncharLoc) = ...
                        cellfun(@num2str, curMetadataOrig(noncharLoc), ...
                        'UniformOutput', false);
                end
                switch curMetavarClass
                    case 'double'
                        curMetadataTrans = str2double(curMetadataOrig);
                    case 'string'
                        curMetadataTrans = string(curMetadataOrig);
                    case 'categorical'
                        curMetadataTrans = categorical(curMetadataOrig);
                    case 'datetime'
                        if isnumeric(curMetadataOrig)
                            % not very good implementation
                            curMetadataOrig = repmat({''}, size(curMetadataOrig));
                        end
                        curMetadataTrans = datetime(curMetadataOrig);
                end
            end
        else
            % if meta data does not exist, store a default missing value
            nEntries = height(curFileExtract);
            switch curMetavarClass
                case 'double'
                    curMetadataTrans = NaN(nEntries, 1);
                case 'string'
                    curMetadataTrans =strings(nEntries, 1);
                case 'categorical'
                    curMetadataTrans = categorical(repmat({''}, nEntries, 1));
                case 'datetime'
                    curMetadataTrans = NaT(nEntries, 1);
            end
        end
        % store the transformed data
        curFileExtract.(curMetavarNameLegal) = curMetadataTrans;
    end
    % vertical catenation
    extracted = hetervcat(extracted, curFileExtract);
    clearvars('-except', initialVars{:})
end

% save merged extracted results and write to csv files
if ~isempty(extracted)
    % remove entries with NaN task ID
    extracted(isnan(extracted.(KEY_TASKID_VAR)), :) = [];
    % save as a .mat file
    save(fullfile(dest, 'raw'), 'extracted')
    % write data to .csv files
    taskIDs = unique(extracted.(KEY_TASKID_VAR));
    % write data for each task as .csv files and use default encoding
    for itask = 1:length(taskIDs)
        taskID = taskIDs(itask);
        taskExtracted = extracted(ismember(extracted.(KEY_TASKID_VAR), taskID), :);
        writetable(taskExtracted, fullfile(dest, [num2str(taskID), '.csv']), 'QuoteStrings', true)
    end
end
rmpath(HELPERFUNPATH)
