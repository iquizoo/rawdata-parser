function [trialRec, status] = sngpreproc(datastr, para)
%SNGPREPROC Preprocessing the data of one single subject.
%   [SPLITRES, STATUS] = SNGPREPROC(CONDITIONS, PARA) does the splitting jobs
%   to conditions according to the parameters specified in para. The two
%   input arguments are both cell type, containing a string in the former,
%   and a table in the latter. Splitting result is stored in splitRes, and
%   status is used to denote whether an exception happens or not.

%By Zhang, Liang. 04/07/2016, E-mail:psychelzh@gmail.com
%Beta version, 05/01/2016.

%Basic logic:
%          ##############################
%          #     Original string        #
%          #             |              #
%          #             V              #
%          #     Split conditions       #
%          #             |              #
%          #             V              #
%          #  Parameters determination  #
%          #             |              #
%          #             V              #
%          #       Splitting string     #
%          #             |              #
%          #             V              #
%          #       Forming a table      #
%          ##############################

status = 0;
% it is invalid when no parameter settings or input data is not a string
if isempty(para) || ~ischar(datastr)
    status = -1;
    trialRec = {table};
    return
end
% delimiters of trials (1st) and variables (2nd)
delims = para.Delimiters{:};
% some task have mutiple conditions with '[cond1](...)[cond2](...)' format
conditions = strsplit(para.Conditions{:});
ncond = length(conditions);
if ncond > 1
    recs = cellfun(...
        @(cond) regexp(datastr, ['(?<=', cond, '\().*?(?=\))'], 'match', 'once'), ...
        conditions, 'UniformOutput', false);
else
    recs = cellstr(datastr);
end
% split out the recorded data to the uncategorized results
trialRecUncat = strsplits(recs, delims);
% get the variable names and chartype var locations for each condition
[varNames, varChars] = varNamesSplit(para, ncond);
% found out the real variable names for each condition
for icond = 1:ncond
    curVarOpts  = varNames{icond};
    curCharOpts = varChars{icond};
    if length(curVarOpts) == 1
        altChoice = 1;
    else
        nCurVarOpts = cellfun(@length, curVarOpts);
        curCondRec = trialRecUncat{icond};
        token = para.TemplateToken{:};
        switch token
            case 'F' %Flanker.
                curCondRec = str2double(cat(1, curCondRec{:}));
                chkcol = curCondRec(:, 1);
                chkcol(isnan(chkcol)) = [];
                % if the 1st column is SCat(1:4), choose the 1st template
                if all(ismember(chkcol, 1:4))
                    altChoice = 1;
                else
                    altChoice = 2;
                end
            case 'RTB' %Bread toasting (SRT)
                altChoice = 1;
                curCondRec = str2double(cat(1, curCondRec{:}));
                if ~isnan(curCondRec)
                    chkcol  = curCondRec(:, 2);
                    chkcol(isnan(chkcol)) = [];
                    % if the 2nd column is ACC(0,1), choose the 2nd template
                    if all(ismember(chkcol, 0:1))
                        altChoice = 2;
                    end
                end
            otherwise
                lenTrial = cellfun(@length, curCondRec);
                if length(lenTrial) == 1 && lenTrial == 1
                    % only one unsplitted string
                    altChoice = 1;
                else
                    % Trial length of 1 denotes artificial data, esp. one ',' at the end.
                    lenTrial(lenTrial == 1) = [];
                    lenTrial = unique(lenTrial);
                    [~, altChoice] = ismember(lenTrial, nCurVarOpts);
                    if length(lenTrial) > 1 || (~isempty(altChoice) && altChoice == 0)
                        altChoice     = length(nCurVarOpts);
                        recs(icond) = recon(curCondRec, token, nCurVarOpts(altChoice), delims);
                    end
                end
        end
    end
    varNames(icond) = curVarOpts(altChoice);
    varChars(icond) = curCharOpts(altChoice);
end
nVars = cellfun(@length, varNames, 'UniformOutput', false);
varDbls = cellfun(@(nvar, vch) ~ismember(1:nvar, vch), nVars, varChars, ...
    'UniformOutput', false);
% set variable names to categorize data
trialRec = table;
for icond = 1:ncond
    curCondName = conditions{icond};
    curCondVarNames = varNames{icond};
    curCondVarDbls = varDbls{icond};
    curCondTrials = trialRecUncat{icond};
    % remove empty recording trials (esp. possible for the last)
    curCondTrials(cellfun(@(c) all(cellfun(@isempty, c)), curCondTrials)) = [];
    if ~isempty(curCondTrials)
        % #split out strings and #variables should be equal
        curCondNVars          = nVars{icond};
        curCondTrialsSplitLen = cellfun(@length, curCondTrials);
        curCondTrials(curCondTrialsSplitLen ~= curCondNVars) = {num2cell(nan(1, curCondNVars))};
        if all(curCondTrialsSplitLen ~= curCondNVars)
            status = -3;
        end
        curCondTrials = cat(1, curCondTrials{:});
        curCondTrials(:, curCondVarDbls) = num2cell(str2double(curCondTrials(:, curCondVarDbls)));
        curCondTrials(:, ~curCondVarDbls) = num2cell(string(curCondTrials(:, ~curCondVarDbls)));
    else
        status = -2;
        curCondTrials = cell(0, nVars{icond});
    end
    % remove missing trials
    curCondTrials(all(cellfun(@ismissing, curCondTrials), 2), :) = [];
    % if condition name is not empty add them to the data
    if ~isempty(curCondName)
        curCondTrials = [repmat({string(curCondName)}, size(curCondTrials, 1), 1), curCondTrials]; %#ok<AGROW>
        curCondVarNames = [{'Condition'}, curCondVarNames]; %#ok<AGROW>
    end
    curCondTrials = cell2table(curCondTrials, 'VariableNames', curCondVarNames);
    trialRec = hetervcat(trialRec, curCondTrials);
end
trialRec = {trialRec};
end

function [varNames, varChars] = varNamesSplit(curTaskPara, ncond)
%Get the settings of each condition, n denotes number of conditions.

% delimiters settings
cond_delim = '|';
opt_delim = '/';
varname_delim = ' ';
% Variable names of conditions.
VariablesNames = strsplit(curTaskPara.VariablesNames{:}, cond_delim);
if length(VariablesNames) < ncond
    VariablesNames = repmat(VariablesNames, 1, ncond);
end
% Variable char locs of conditions.
VariablesChar = strsplit(curTaskPara.VariablesChar{:}, cond_delim);
if length(VariablesChar) < ncond
    VariablesChar = repmat(VariablesChar, 1, ncond);
end
% parse out all possible variable names
varNames = strsplits(VariablesNames, [opt_delim, varname_delim]);
% parse out all possible chartype variable locations
varChars = cellfun( ...
    @(c) cellfun(@str2num, c, 'UniformOutput', false), ...
    cellfun(@(x) strsplit(x, opt_delim), VariablesChar, 'UniformOutput', false), ...
    'UniformOutput', false);
%In case the lazy mode, in which one instance is presented for multiple
%conditions or variable candidates.
lenVarNames = cellfun(@length, varNames);
lenCharVars = cellfun(@length, varChars);
nCandsCond  = max(lenVarNames, lenCharVars);
varNames(lenVarNames == 1) = cellfun(@repelem, ...
    varNames(lenVarNames == 1), num2cell(nCandsCond(lenVarNames == 1)), ...
    'UniformOutput', false);
varChars(lenCharVars == 1) = cellfun(@repelem, ...
    varChars(lenCharVars == 1), num2cell(nCandsCond(lenCharVars == 1)), ...
    'UniformOutput', false);
end

function recons = recon(trialRec, token, nvars, delimiters)
%Reconstruction the string in conditions to extract important information
%and accommodate for the formatting.

switch token
    case 'WM' %Some of the fields need converting to hex numbers.
        trialRecons = cell(size(trialRec));
        for itrl = 1:length(trialRec)
            curTrialRec = trialRec{itrl};
            curTrialRecRecons = cell(1, nvars);
            curTrialRecRecons([1:2, end]) = curTrialRec([1:2, end]);
            SSeries = str2double(curTrialRec(3:end - 1));
            SSeries = dec2hex(SSeries)';
            curTrialRecRecons{3} = SSeries;
            trialRecons{itrl} = strjoin(curTrialRecRecons, delimiters(2));
        end
    case 'CPT1' %Some of the fields need discarding.
        trialRecons = cellfun(@(x) x([1:4, end]), trialRec, 'UniformOutput', false);
        trialRecons = cellfun(@(x) strjoin(x, delimiters(2)), ...
            trialRecons, 'UniformOutput', false);
    otherwise %Special issues: in this case the raw data are not correctly recorded.
        trialRecons = {''};
end
recons = {strjoin(trialRecons, delimiters(1))};
end

function splitted = strsplits(orig, delims)
% combines two step string split
splitted = cellfun( ...
    ... % to split using the second delimiter
    @(c) cellfun(@(s) strsplit(s, delims(2)), c, 'UniformOutput', false), ...
    ... % to split using the first delimiter
    cellfun(@(s) strsplit(s, delims(1)), orig, 'UniformOutput', false), ...
    'UniformOutput', false);
end
