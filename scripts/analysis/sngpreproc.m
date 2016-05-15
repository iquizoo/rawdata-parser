function [splitRes, status] = sngpreproc(conditions, para)
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
%Extract useful information form parameters.
para = para{:};
if ~isempty(para) && ~isempty(para.Delimiters{:})
    %Split the conditions into recons, get the settings of each condition.
    %Delimiters.
    delimiters = para.Delimiters{:};
    %ConditionInformation contains information of condition splitting.
    conditionInformation = para.ConditionInformation{:};
    if ~isempty(conditionInformation) % Split conditions.
        condInfo = strsplit(conditionInformation, '|');
        %Names for all conditions.
        conditionsNames = strsplit(condInfo{1});
        %Condition precedences for all conditions.
        conditionsPre = strsplit(condInfo{2});
        ncond = length(conditionsNames);
        % recons contains the strings of all conditions extracted from
        %conditions
        recons = cell(1, ncond);
        for icond = 1:ncond
            curRecon = regexp(conditions{:}, ...
                ['(?<=', conditionsPre{icond}, '\().*?(?=\))'], 'match', 'once');
            recons{icond} = curRecon;
        end
    else
        conditionsNames = {'RECORD'};
        %By default, use the original conditions string.
        recons = conditions;
    end
    %Rearrange parameters condition-wise.
    ncond = length(conditionsNames); %We have completed the condition splitting task.
    %Splitting variable names and extract information of conditions.
    [VariablesNames, charVars] = varNamesSplit(para, ncond);
    for icond = 1:ncond
        curRecon = recons(icond);
        curAltVariablesNames = VariablesNames{icond};
        curAltCharVars = charVars{icond};
        curAltVariablesNamesSplit = cellfun(@strsplit, curAltVariablesNames, 'UniformOutput', false);
        nCurAltVars = cellfun(@length, curAltVariablesNamesSplit);
        %Get the appropriate variable names of the different template.
        curRec = cellfun(@strsplit, ...
            curRecon, repmat({delimiters(1)}, size(curRecon)), ...
            'UniformOutput', false);
        curTrialRec = cellfun(@strsplit, ...
            curRec{:}, repmat({delimiters(2)}, size(curRec{1})), ...
            'UniformOutput', false);
        token = para.TemplateToken{:};
        switch token
            %language task, , Go/No-Go, cpt, divided attention working memory.
            case {'LT', 'GNG', 'CPT1', 'DA', 'WM'}
                lenTrial = cellfun(@length, curTrialRec);
                % Trial length of 1 denotes artificial data, esp. one ',' at the end.
                lenTrial(lenTrial == 1) = [];
                lenTrial = unique(lenTrial);
                [~, altChoice] = ismember(lenTrial, nCurAltVars);
                if length(lenTrial) > 1 || (~isempty(altChoice) && altChoice == 0)
                    altChoice = length(nCurAltVars);
                    recons(icond) = recon(curTrialRec, token, nCurAltVars(altChoice), delimiters);
                elseif isempty(lenTrial)
                    altChoice = 1; %Use the first by default.
                end
            case 'F' %Flanker.
                curTrialRec = str2double(cat(1, curTrialRec{:}));
                chkcol = curTrialRec(:, 1);
                chkcol(isnan(chkcol)) = [];
                if all(ismember(chkcol, 1:4)) %The first column is Stimuli category.
                    altChoice = 1;
                else
                    altChoice = 2;
                end
            case 'RTB' %Bread toasting (SRT)
                curTrialRec = str2double(cat(1, curTrialRec{:}));
                chkcol = curTrialRec(:, 2);
                chkcol(isnan(chkcol)) = [];
                if all(ismember(chkcol, 0:1)) %The second column is ACC.
                    altChoice = 2;
                else
                    altChoice = 1;
                end
            otherwise
                altChoice = 1; %In common conditions, there is only one condition.
        end
        VariablesNames(icond) = curAltVariablesNames(altChoice);
        charVars(icond) = curAltCharVars(altChoice);
    end
    VariablesNames = cellfun(@strsplit, VariablesNames, 'UniformOutput', false);
    nVars = cellfun(@length, VariablesNames, 'UniformOutput', false);
    allLocs = cellfun(@colon, num2cell(ones(size(nVars))), nVars, 'UniformOutput', false);
    trans = cellfun(@not, ...
        cellfun(@ismember, allLocs, charVars, 'UniformOutput', false), ...
        'UniformOutput', false);
    %Routine split.
    reconsTrialApart = cellfun(@strsplit, ...
        recons, repmat({delimiters(1)}, size(recons)),...
        'UniformOutput', false);
    reconsTrialApart = cell2table(reconsTrialApart, 'VariableNames', conditionsNames);
    for icond = 1:ncond
        curCondTrials = reconsTrialApart.(conditionsNames{icond});
        if ~all(cellfun(@isempty, curCondTrials))
            curCondTrialsSplit = cellfun(@(x) strsplit(x, delimiters(2)), ...
                curCondTrials, 'UniformOutput', false);
            curCondTrialsSplitLen = cellfun(@length, curCondTrialsSplit);
            %If the length of the split-out string is not equal to the number
            %of output variable names.
            curCondNVars = nVars{icond};
            curCondTrialsSplit(curCondTrialsSplitLen ~= curCondNVars) = {num2cell(nan(1, curCondNVars))};
            if all(curCondTrialsSplitLen ~= curCondNVars)
                warning('UDF:SNGPREPROC:NOFORMATDATA', ...
                    'Recorded data not correctly formatted. Please check!\n');
                status = -1;
            end
            curCondTrialsSplit = cat(1, curCondTrialsSplit{:});
            curCondTrialsSplit(:, trans{icond}) = num2cell(str2double(curCondTrialsSplit(:, trans{icond})));
            %Here cell type is used, because the RECORD have multiple rows.
            reconsTrialApart.(conditionsNames{icond}) = ...
                {cell2table(curCondTrialsSplit, 'VariableNames', VariablesNames{icond})};
        else
            warning('UDF:SNGPREPROC:MODE1ABNORMAL', ...
                'No data for condition of %s.\n', conditionsNames{icond});
            status = -1;
            reconsTrialApart.(conditionsNames{icond}) = {cell2table(cell(0, nVars{icond}), ...
                'VariableNames', VariablesNames{icond})};
        end
    end
else
    warning('UDF:SNGPREPROC:NOPARASETTINGS', ...
        'No parameters specification found.\n')
    status = -2;
    reconsTrialApart = table;
end
splitRes = {reconsTrialApart};
end

function [VariablesNames, charVars] = varNamesSplit(curTaskPara, ncond)
%Get the settings of each condition, n denotes number of conditions.

% Variable names of conditions.
VariablesNames = strsplit(curTaskPara.VariablesNames{:}, '|');
if length(VariablesNames) < ncond
    VariablesNames = repmat(VariablesNames, 1, ncond);
end
% Variable char locs of conditions.
VariablesChar = strsplit(curTaskPara.VariablesChar{:}, '|');
if length(VariablesChar) < ncond
    VariablesChar = repmat(VariablesChar, 1, ncond);
end
%Condition names
VariablesNames = cellfun(@(x) strsplit(x, '\'), ...
    VariablesNames, 'UniformOutput', false);
%Variable char locs.
VariablesChar = cellfun(@(x) strsplit(x, '\'), ...
    VariablesChar, 'UniformOutput', false);
charVars = cell(size(VariablesChar));
for icond = 1:ncond
    curCondVariablesChar = VariablesChar{icond};
    tpCurVariablesChar = cellfun(@transpose, curCondVariablesChar, 'UniformOutput', false);
    ctpCurVariablesChar = cellfun(@num2cell, tpCurVariablesChar, 'UniformOutput', false);
    charVars{icond} = cellfun(@str2double, ctpCurVariablesChar, 'UniformOutput', false);
end
%In case the lazy mode, in which one instance is presented for multiple
%conditions or variable candidates.
lenVarNames = cellfun(@length, VariablesNames);
lenCharVars = cellfun(@length, charVars);
nCandsCond = max(lenVarNames, lenCharVars);
VariablesNames(lenVarNames == 1) = cellfun(@repmat, ...
    VariablesNames(lenVarNames == 1), num2cell(ones(size(VariablesNames(lenVarNames == 1)))), ...
    num2cell(nCandsCond(lenVarNames == 1)), 'UniformOutput', false);
charVars(lenCharVars == 1) = cellfun(@repmat, ...
    charVars(lenCharVars == 1), num2cell(ones(size(charVars(lenCharVars == 1)))), ...
    num2cell(nCandsCond(lenCharVars == 1)), 'UniformOutput', false);
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
end
recons = {strjoin(trialRecons, delimiters(1))};
end
