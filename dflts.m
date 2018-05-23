% Set the project defaults.
% Note: no general purpose is guarantted here, please modify this script
% when error occured.
dfltSet = [];
dfltSet.CCDPRO_BASE_DIR = pwd; %This means you should place this script in the base dir.
dfltSet.DATARAW_DIR     = fullfile(dfltSet.CCDPRO_BASE_DIR, 'DATA_RawData'); %The directory of raw data.
dfltSet.DATARES_DIR     = fullfile(dfltSet.CCDPRO_BASE_DIR, 'DATA_RES'); %The directory to store results.
dfltSet.UTILIS_DIR      = fullfile(dfltSet.CCDPRO_BASE_DIR, 'utilis'); %The directory to store all the utilis functions.
dfltSet.REPORT_DIR      = fullfile(dfltSet.CCDPRO_BASE_DIR, 'Presentations'); % The directory to store reports.
dfltSet.SCRIPTS_DIR     = 'scripts';
dfltSet.EXPORTED_DIR    = 'exported';
dfltSet.PARSED_DIR      = 'parsed';
