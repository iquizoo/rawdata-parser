function [splitRes, status] = sngproc(conditions, curTaskPara)
%SNGPROC Preprocessing the data of one single subject.
%   [SPLITRES, STATUS] = SNGPROC(CONDITIONS, CURTASKPARA) does the
%   splitting jobs to conditions according to the parameters specified in
%   curtaskpara. The two input arguments are both cell type, containing a
%   string in the former, and a table in the latter. Splitting result is
%   stored in splitRes, and status is used to denote whether an exception
%   happens or not.

%By Zhang, Liang. 04/07/2016, E-mail:psychelzh@gmail.com

%Basic logic:
%          ############################################
%          #  Original string
%          ####################
%                     

status = 0;
%Extract useful information form parameters.
curTaskPara = curTaskPara{:};
if ~isempty(curTaskPara) && ~isnan(curTaskPara.SplitMode)
    %% Split the conditions into recons, get the settings of each condition.
    %Delimiters.
    delimiters = curTaskPara.Delimiters{:};
    % Determine when there exists several seperate conditions.
    switch curTaskPara.SplitMode
        case 1 % See the notation in the Excel file: tasksetting.xlsx
            splitInfo = strsplit(curTaskPara.AddInfo{:}, '|');
            conditionsNames = strsplit(splitInfo{1});
            conditionsPre = strsplit(splitInfo{2});
            ncond = length(conditionsNames);
            % recons contains the strings of all conditions extracted from conditions.
            recons = cell(1, ncond);
            for icond = 1:ncond
                curRecon = regexp(conditions{:}, ...
                    ['(?<=', conditionsPre{icond}, '\().*?(?=\))'], 'match', 'once');
                recons{icond} = curRecon;
            end
            [VariablesNames, charVars] = varNamesSplit(curTaskPara, ncond);
        case 3 % See the notation in the Excel file: tasksetting.xlsx
            conditionsNames = {'RECORD'};
            % recons contains the strings of all conditions extracted from conditions.
            recons = conditions;
            [AltVariablesNames, charAltVars] = varNamesSplit(curTaskPara);
            AltVariablesNamesSplit = cellfun(@strsplit, AltVariablesNames, 'UniformOutput', false);
            nAltVars = cellfun(@length, AltVariablesNamesSplit);
            %Get the appropriate variable names of the different template.
            spRec = cellfun(@strsplit, ...
                recons, repmat({delimiters(1)}, size(recons)), ...
                'UniformOutput', false);
            spTrialRec = cellfun(@strsplit, ...
                spRec{:}, repmat({delimiters(2)}, size(spRec{1})), ...
                'UniformOutput', false);
            switch curTaskPara.TemplateToken{:}
                case {'LT', 'GNG'} %language task, working memory, Go/No-Go
                    nspTrial = cellfun(@length, spTrialRec);
                    altChoice = find(ismember(nAltVars, nspTrial));
                case 'WM'
                    nspTrial = cellfun(@length, spTrialRec);
                    % Trial length of 1 denotes artificial data, esp. one
                    % ',' at the end.
                    nspTrial(nspTrial == 1) = [];
                    nspTrial = unique(nspTrial);
                    if length(nspTrial) > 1
                        altChoice = 3;
                        trialRecons = cell(size(spTrialRec));
                        for itrl = 1:length(spTrialRec)
                            curTrialRec = spTrialRec{itrl};
                            curTrialRecRecons = cell(1, nAltVars(altChoice));
                            curTrialRecRecons([1:2, end]) = curTrialRec([1:2, end]);
                            SSeries = str2double(curTrialRec(3:end - 1));
                            SSeries = dec2hex(SSeries)';
                            curTrialRecRecons{3} = SSeries;
                            trialRecons{itrl} = strjoin(curTrialRecRecons, delimiters(2));
                        end
                        recons = {strjoin(trialRecons, delimiters(1))};
                    else
                        altChoice = find(ismember(nAltVars(1:2), nspTrial));
                    end
                case 'F' %Flanker.
                    spTrialRec = str2double(cat(1, spTrialRec{:}));
                    chkcol = spTrialRec(:, 1);
                    chkcol(isnan(chkcol)) = [];
                    if all(ismember(chkcol, 1:4)) %The first column is Stimuli category.
                        altChoice = 1;
                    else
                        altChoice = 2;
                    end
                case 'RTB' %Bread toasting (SRT)
                    spTrialRec = str2double(cat(1, spTrialRec{:}));
                    chkcol = spTrialRec(:, 2);
                    chkcol(isnan(chkcol)) = [];
                    if all(ismember(chkcol, 0:1)) %The second column is ACC.
                        altChoice = 2;
                    else
                        altChoice = 1;
                    end
            end
            VariablesNames = AltVariablesNames(altChoice);
            charVars = charAltVars(altChoice);
        otherwise
            conditionsNames = {'RECORD'};
            recons = conditions;
            [VariablesNames, charVars] = varNamesSplit(curTaskPara, 1);
    end
    VariablesNames = cellfun(@strsplit, VariablesNames, 'UniformOutput', false);
    nVars = cellfun(@length, VariablesNames, 'UniformOutput', false);
    allLocs = cellfun(@colon, num2cell(ones(size(nVars))), nVars, 'UniformOutput', false);
    trans = cellfun(@not, ...
        cellfun(@ismember, allLocs, charVars, 'UniformOutput', false), ...
        'UniformOutput', false);

    %% Routine split.
    reconsTrialApart = cellfun(@strsplit, ...
        recons, repmat({delimiters(1)}, size(recons)),...
        'UniformOutput', false);
    reconsTrialApart = cell2table(reconsTrialApart, 'VariableNames', conditionsNames);
    ncond = length(conditionsNames);
    for icond = 1:ncond
        curCondTrials = reconsTrialApart.(conditionsNames{icond});
        if ~all(cellfun(@isempty, curCondTrials))
            curCondTrialsSplit = cellfun(@strsplit, ...
                curCondTrials, repmat({delimiters(2)}, size(curCondTrials)),...
                'UniformOutput', false);
            curCondTrialsSplitLen = cellfun(@length, curCondTrialsSplit);
            %If the length of the split-out string is not equal to the number
            %of output variable names.
            curCondNVars = nVars{icond};
            curCondTrialsSplit(curCondTrialsSplitLen ~= curCondNVars) = {num2cell(nan(1, curCondNVars))};
            if all(curCondTrialsSplitLen ~= curCondNVars)
                warning('UDF:SNGPROC:NOFORMATDATA', ...
                    'Recorded data not correctly formatted. Please check!\n');
                status = -1;
            end
            curCondTrialsSplit = cat(1, curCondTrialsSplit{:});
            curCondTrialsSplit(:, trans{icond}) = num2cell(str2double(curCondTrialsSplit(:, trans{icond})));
            reconsTrialApart.(conditionsNames{icond}) = ...
                {cell2table(curCondTrialsSplit, 'VariableNames', VariablesNames{icond})};
        else
            warning('UDF:SNGPROC:MODE1ABNORMAL', ...
                'No data for condition of %s.\n', conditionsNames{icond});
            status = -1;
            reconsTrialApart.(conditionsNames{icond}) = ...
                [];
        end
    end
else
    warning('UDF:SNGPROC:NOPARASETTINGS', ...
        'No parameters specification found.\n')
    status = -2;
    reconsTrialApart = table;
end
splitRes = {reconsTrialApart};
end

function [VariablesNames, charVars] = varNamesSplit(curTaskPara, n)
%Get the settings of each condition, n denotes number of conditions.

% Variable names.
VariablesNames = strsplit(curTaskPara.VariablesNames{:}, '|');
% Variable char locs.
VariablesChar = strsplit(curTaskPara.VariablesChar{:}, '|');
tpVariablesChar = cellfun(@transpose, VariablesChar, 'UniformOutput', false);
ctpVariablesChar = cellfun(@num2cell, tpVariablesChar, 'UniformOutput', false);
charVars = cellfun(@str2double, ctpVariablesChar, 'UniformOutput', false);
if curTaskPara.SplitMode == 3
    n = max(length(VariablesNames), length(charVars));
end
if length(VariablesNames) < n
    VariablesNames = repmat(VariablesNames, 1, n);
end
if length(charVars) < n
    charVars = repmat(charVars, 1, n);
end
end
