function ReadRawXls(varargin)
%READRAWXLS transforms the excel files in `src` to `dest`.

% start stopwatch.
tic

% parse input arguments
par = inputParser;
addParameter(par, 'Source', '', @ischar)
addParameter(par, 'Destination', '', @ischar)
addParameter(par, 'DisplayInfo', 'text', @ischar)
parse(par, varargin{:})
src = par.Results.Source;
dest = par.Results.Destination;
prompt = lower(par.Results.DisplayInfo);

% add helper functions folder
helperFunPath = 'scripts';
addpath(helperFunPath);

% metavars options
METAVARSOPTS = {'Taskname', 'excerciseId', 'userId', 'name', 'gender|sex', 'school', 'grade', 'cls', 'birthDay', 'createDate|createTime'};
METAVARNAMES = {'Taskname', 'excerciseId', 'userId', 'name', 'sex', 'school', 'grade', 'cls', 'birthDay', 'createTime'};
METAVARCLSES = {'cell', 'double', 'double', 'cell', 'cell', 'cell', 'cell', 'cell', 'datetime', 'datetime'};

% check source and destination input
if isempty(src)
    % ask for input type
    choice = questdlg('What type of source?', 'Input checking', 'File', 'Folder', 'Cancel', 'File');
    switch choice
        case 'File'
            [fnames, pathname] = uigetfile('.xlsx', 'Please select the file containing source data.', 'DATA_RawData', 'MultiSelect', 'on');
            src = fullfile(pathname, fnames);
        case 'Folder'
            src = uigetdir('DATA_RawData', 'Please select the folder of source data.');
        case 'Cancel'
            fprintf('User canceled. Returning.\n')
            rmpath(helperFunPath)
            return
    end
end
if isempty(dest)
    dest = uigetdir('DATA_RawData', 'Please select the folder of destination data.');
end

% get all the xlsx file names
if ~iscell(src) && isfolder(src)
    files = dir(fullfile(src, '*.xlsx'));
    filefullnames = fullfile({files.folder}, {files.name});
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
% variables for progressing statistics
nfiles = length(filefullnames);
nprocessed = 0;

% preallocate
extracted = table;

% record the time elapsed when preparation is done
prepartionTime = toc;

% process file by file
for ifile = 1:nfiles
    initialVars = who;
    curFileFullname = filefullnames{ifile};
    [~, curFilename] = fileparts(curFileFullname);

    % update prompt information.
    completePercent = nprocessed / nfiles;
    if nprocessed == 0
        msgSuff = 'Please wait...';
    else
        elapsedTime = toc - prepartionTime;
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
    
    % extract data from file
    [curFileExtract, status] = sngreadxls(curFileFullname);
    if any(status == -1)
        except = true;
        warning('UDF:READRAWXLS:DATAMISSING', 'Data of some users lost in file %s.', curFileFullname);
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
% remove those with NaN `excerciseId`
extracted(isnan(extracted.excerciseId), :) = [];
% write data to text files
taskIDs = unique(extracted.excerciseId);
for itask = 1:length(taskIDs)
    taskID = taskIDs(itask);
    taskExtracted = extracted(ismember(extracted.excerciseId, taskID), :);
    writetable(taskExtracted, fullfile(dest, [num2str(taskID), '.csv']), ...
        'QuoteStrings', true, 'Delimiter', '\t', 'Encoding', 'UTF-8')
end
rmpath(helperFunPath)
