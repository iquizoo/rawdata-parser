function UpdateDataStore(tasks, varargin)
%UPDATEDATASTORE updates data according to the configuration excel file.
%

%By Zhang, Liang. 2016/08/17. E-mail: psychelzh@gmail.com.

% Note: although datastore is stated, but the datastore is not really in
% use because of technique immature and lack of time. And the configuration
% file used is in excel format because of convenience.

% Parse input arguments.
par = inputParser;
addOptional(par, 'dsout', '', @ischar);
addOptional(par, 'dsraw', '', @ischar);
addParameter(par, 'MetaVars', {'userId', 'gender', 'school', 'grade', 'cls'}, @iscellstr);
parse(par, varargin{:});
dsout = par.Results.dsout;
dsraw = par.Results.dsraw;
metavars = par.Results.MetaVars;
if isempty(tasks)
    fprintf('Nothings to do at all. Returning...\n')
    return
end
if isempty(dsout)
    [dsoutfn, dsoutpath] = uigetfile('*.mat', ...
        'Select the file containing the data needing updating', 'E:\git\CCDPro\DATA_RES\ds\CCDRes.mat');
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
[thismrgdata, thisscores, thisindices, thistaskstat] = Merges(resdata, true);
mrgdata = update(mrgdata, thismrgdata, metavars); %#ok<*NASGU,*NODEF>
scores = update(scores, thisscores, metavars);
indices = update(indices, thisindices, metavars);
taskstat = update(taskstat, thistaskstat, metavars);
save(dsout, 'mrgdata', 'scores', 'indices', 'taskstat')
end

function mrg = update(tbl1, tbl2, metavars)
%MERGE tries to merge two tables and updating variables.

vars1 = tbl1.Properties.VariableNames;
vars2 = tbl2.Properties.VariableNames;
% Get metadata from two tables.
meta1 = tbl1(:, ismember(vars1, metavars));
meta2 = tbl2(:, ismember(vars2, metavars));
% Ordinal variable needs to be set nominal before merge.
[meta1, ordvars1] = unordinal(meta1);
[meta2, ordvars2] = unordinal(meta2);
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
for ivar = 1:length(ordvars)
    tbl.(ordvars{ivar}) = categorical(tbl.(ordvars{ivar}));
end
end
