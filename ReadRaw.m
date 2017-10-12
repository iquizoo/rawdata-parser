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
METAVARSOPTS = {'Taskname', 'excerciseId', 'userId', 'name', 'gender|sex', 'school', 'grade', 'cls', 'birthDay', 'createDate|createTime'};
METAVARNAMES = {'Taskname', 'excerciseId', 'userId', 'name', 'sex', 'school', 'grade', 'cls', 'birthDay', 'createTime'};
METAVARCLSES = {'cell', 'double', 'double', 'cell', 'cell', 'cell', 'cell', 'cell', 'datetime', 'datetime'};
TASKKEYVARNAME = 'excerciseId';

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
    
    if any(status == -1)
        except = true;
        warning('UDF:READRAWXLS:DATAMISSING', 'Data of some users (total: %d) lost in file %s.', ...
            sum(status == -1), curFileFullname);
    end
    % checking metadata type
    curFileVarNamesRaw = curFileExtract.Properties.VariableNames;
    for imetavar = 1:length(METAVARSOPTS)
        curMetavarOpts = split(METAVARSOPTS{imetavar}, '|');
        curMetavarNameReal = intersect(curMetavarOpts, curFileVarNamesRaw);
        % get the legal name and check its type
        curMetavarNameLegal = METAVARNAMES{imetavar};
        curMetavarClass = METAVARCLSES{imetavar};
        % do things condition on the metadata existence
        if ~isempty(curMetavarNameReal)
            % change meta varname to the legal one
            curFileExtract.Properties.VariableNames{curMetavarNameReal{:}} = curMetavarNameLegal;
            curMetadataOrig = curFileExtract.(curMetavarNameLegal);
            curMetadataTrans = curMetadataOrig;
            if ~isa(curMetadataOrig, curMetavarClass)
                switch curMetavarClass
                    case 'cell'
                        curMetadataTrans = num2cell(curMetadataOrig);
                    case 'double'
                        curMetadataTrans = str2double(curMetadataOrig);
                    case 'datetime'
                        if isnumeric(curMetadataOrig)
                            % not very good implementation
                            curMetadataOrig = repmat({''}, size(curMetadataOrig));
                        end
                        curMetadataTrans = datetime(curMetadataOrig);
                end
            end
        else
            % if meta data does not exist, create an empty one
            nEntries = height(curFileExtract);
            switch curMetavarClass
                case 'cell'
                    curMetadataTrans = repmat({''}, nEntries, 1);
                case 'double'
                    curMetadataTrans = NaN(nEntries, 1);
                case 'datetime'
                    curMetadataTrans = NaT(nEntries, 1);
            end
        end
        % store the transformed data
        curFileExtract.(curMetavarNameLegal) = curMetadataTrans;
    end
    % vertical catenation
    extracted = [extracted; curFileExtract]; %#ok<AGROW>
    clearvars('-except', initialVars{:})
end

% remove entries with NaN task ID
extracted(isnan(extracted.(TASKKEYVARNAME)), :) = [];
% write data to .csv files
taskIDs = unique(extracted.(TASKKEYVARNAME));
for itask = 1:length(taskIDs)
    taskID = taskIDs(itask);
    taskExtracted = extracted(ismember(extracted.(TASKKEYVARNAME), taskID), :);
    writetable(taskExtracted, fullfile(dest, [num2str(taskID), '.csv']), ...
        'QuoteStrings', true, 'Encoding', 'UTF-8')
end
rmpath(HELPERFUNPATH)
