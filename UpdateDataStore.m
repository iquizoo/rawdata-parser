function UpdateDataStore(tasks, varargin)
%UPDATEDATASTORE updates data according to the configuration excel file.
%   UPDATEDATASTORE(tasks) updating the results with the default settings,
%   note a gui will pop out to locate the two data files used in the
%   processing.
%
%   UPDATEDATASTORE(tasks, Name, Value) adds parameters to specify settings
%   of the updating processes.
%          dsout - specify the full file name of data containing all the
%                  results indicators to update.
%          dsraw - specify the full file name of raw data file.
%       MetaVars - specify meta data vars, by default is the common used in
%                  this project.
%
%   Example: In an usual situation, the following command is okay.
%           UpdateDataStore('BART') % specify the tasknames

%By Zhang, Liang. 2016/08/17. E-mail: psychelzh@gmail.com.

% Note: although datastore is stated, but the datastore is not really in
% use because of technique immature and lack of time. And the configuration
% file used is in excel format because of convenience.

% Parse input arguments.
par = inputParser;
parNames   = { 'dsout', 'dsraw',                                'MetaVars'                           };
parDflts   = {  '',       '',    {'userId', 'name', 'gender', 'school', 'grade', 'cls', 'createDate'}};
parValFuns = {@ischar,  @ischar,                     @(x) ischar(x) | iscellstr(x)                   };
cellfun(@(x, y, z) addParameter(par, x, y, z), parNames, parDflts, parValFuns);
parse(par, varargin{:});
dsout = par.Results.dsout;
dsraw = par.Results.dsraw;
metavars = cellstr(par.Results.MetaVars);
if isempty(tasks)
    fprintf('Nothings to do at all. Returning...\n')
    return
end
if isempty(dsout)
    [dsoutfn, dsoutpath] = uigetfile('*.mat', ...
        'Select the file containing the data needing updating', 'DATA_RES\ds\CCDRes.mat');
    dsout = fullfile(dsoutpath, dsoutfn);
end
if isempty(dsraw)
    [dsrawfn, dsrawpath] = uigetfile('*.mat', ...
        'Select the file containing the raw data', 'E:\git\CCDPro\DATA_RES\ds\RawData.mat');
    dsraw = fullfile(dsrawpath, dsrawfn);
end
% Read data.
fprintf('Now loading all the merged data which need updating from: \n%s\n', dsout)
load(dsout) % merged data.
fprintf('Now loading all the raw data from: \n%s\n', dsraw)
load(dsraw) % raw data.
% Modifying data.
resdata = Proc(dataExtract, 'TaskName', tasks);
[thismrgdata, thisscores, thisindices, thistaskstat] = Merges(resdata, 'MetaVars', metavars);
mrgdata = renew(mrgdata, thismrgdata, metavars); %#ok<*NASGU,*NODEF>
scores = renew(scores, thisscores, metavars);
indices = renew(indices, thisindices, metavars);
taskstat = renew(taskstat, thistaskstat, metavars);
save(dsout, 'mrgdata', 'scores', 'indices', 'taskstat')
end

function mrg = renew(tbl1, tbl2, metavars)
%MERGE tries to merge two tables and updating variables.

vars1 = tbl1.Properties.VariableNames;
vars2 = tbl2.Properties.VariableNames;
% Ordinal variable needs to be set nominal before merge.
[tbl1, ordvars1] = unordinal(tbl1);
[tbl2, ordvars2] = unordinal(tbl2);
% Get metadata from two tables.
meta1 = tbl1(:, ismember(vars1, metavars));
meta2 = tbl2(:, ismember(vars2, metavars));
difmeta = setdiff(meta1, meta2);
% Complete tbl2 into a table that is able to be merged with tbl1.
datavars2 = setdiff(vars2, metavars);
suppheight = height(difmeta);
suppdata = [difmeta, ...
    array2table(nan(suppheight, length(datavars2)), 'VariableNames', datavars2)];
tbl2 = [tbl2; suppdata];
% Remove all the updated variables from tbl1.
datavars1 = setdiff(vars1, metavars);
rmvars = intersect(datavars1, datavars2);
tbl1(:, ismember(vars1, rmvars)) = [];
% Complete the joining job.
mrg = innerjoin(tbl1, tbl2);
allvars = mrg.Properties.VariableNames;
% Reordinal the result table.
ordvars = unique([ordvars1, ordvars2]);
for iord = 1:length(ordvars)
    thisord = ordvars{iord};
    if ismember(thisord, allvars)
        mrg.(thisord) = categorical(mrg.(thisord), 'Ordinal', true);
    end
end
end

function [tbl, ordvars] = unordinal(tbl)
% Convert all the ordinal columns into nominal variables.

ordcols = varfun(@(x) iscategorical(x) && isordinal(x), tbl, 'OutputFormat', 'uniform');
ordvars = tbl.Properties.VariableNames(ordcols);
for iord = 1:length(ordvars)
    tbl.(ordvars{iord}) = categorical(tbl.(ordvars{iord}));
end
end
