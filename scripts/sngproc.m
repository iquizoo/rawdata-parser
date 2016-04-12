function [splitRes, status] = sngproc(conditions, curTaskPara)
%SNGPROC Preprocessing the data of one single subject.

%By Zhang, Liang. 04/07/2016, E-mail:psychelzh@gmail.com

%Extract useful information form parameters.
curTaskPara = curTaskPara{:};
if isempty(curTaskPara) || isnan(curTaskPara.SplitMode)
    warning('UDF:SNGPROC:PARANOTFOUND', ...
        'No parameters specification is found,\n')
    splitRes = {table};
    status = -2;
    return
end
%Delimiters.
delimiters = curTaskPara.Delimiters{1};
%Output table variables names.
if curTaskPara.SplitMode ~= 3
    VariablesNames = strsplit(curTaskPara.VariablesNames{:});
    nvars = length(VariablesNames);
    %Output that need to be transformed into numeric data.
    charVars = str2double(num2cell(num2str(curTaskPara.VariablesChar)'));
    trans = ~ismember(1:nvars, charVars);
end
if ~isempty(conditions{:})
    %% Split the conditions.
    % Determine when there exists several seperate conditions.
    if curTaskPara.SplitMode == 1
        conditions = strsplit(conditions{:}, delimiters(1));
        delimiters = delimiters(2:end);
        conditionsNames = strsplit(curTaskPara.AddInfo{:});
        if length(conditions) ~= length(conditionsNames)
            warning('UDF:SNGPROC:MODE1ABNORMAL', ...
                'More partition condition than expected, will return empty result. Please check the data.\n')
            nc = length(conditionsNames);
            conditions = table;
            %When split mode is not 3, the variable names of output is
            %well-defined.
            if curTaskPara.SplitMode ~= 3
                for ic = 1:nc
                    curStrOut = cell(1, nvars);
                    conditions.(conditionsNames{ic}) = {cell2table(curStrOut, 'VariableNames', VariablesNames)};
                end
            end
            splitRes = {conditions};
            status = -1;
            return
        end
    else
        conditionsNames = {'RECORD'};
    end
    %% Determine the outpit variable names for those tasks of split mode 3.
    if curTaskPara.SplitMode == 3
        %First, get the two alternatives of the variable names and string
        %formatted variables.
        % Alternative 1.
        alt1VariablesNames = strsplit(curTaskPara.VariablesNames{:});
        alt1nvars = length(alt1VariablesNames);
        alt1charVars = str2double(num2cell(num2str(curTaskPara.VariablesChar)'));
        alt1trans = ~ismember(1:alt1nvars, alt1charVars);
        % Alternative 2.
        altInfo = strsplit(curTaskPara.AddInfo{:}, '|');
        alt2VariablesNames = strsplit(altInfo{2});
        alt2nvars = length(alt2VariablesNames);
        alt2charVars = str2double(num2cell(altInfo{1}'));
        alt2trans = ~ismember(1:alt2nvars, alt2charVars);
        %This is a tricky thing here.
        switch curTaskPara.TemplateIdentity
            case {1, 12}
                splOutStr = strsplit(conditions{1}, delimiters(1));
                splOutStrUnit = strsplit(splOutStr{1}, delimiters(2));
                nOutStrUnit = length(splOutStrUnit);
                if nOutStrUnit == alt1nvars
                    VariablesNames = alt1VariablesNames;
                    nvars = alt1nvars;
                    trans = alt1trans;
                elseif nOutStrUnit == alt2nvars
                    VariablesNames = alt2VariablesNames;
                    nvars = alt2nvars;
                    trans = alt2trans;
                else
                    warning('UDF:SNGPROC:NOSUITTEMPLATE', ...
                        'No suitable template found. Please check the data!\n')
                    splitRes = {table};
                    status = -1;
                    return
                end
            case 17
                splOutStr = strsplit(conditions{1}, delimiters(1));
                splOutStrUnit = strsplit(splOutStr{1}, delimiters(2));
                firstnum = str2double(splOutStrUnit{1});
                if ismember(firstnum, 1:4)
                    VariablesNames = alt1VariablesNames;
                    nvars = alt1nvars;
                    trans = alt1trans;
                else
                    VariablesNames = alt2VariablesNames;
                    nvars = alt2nvars;
                    trans = alt2trans;
                end
        end
    end
    %% Routine split.
    conditions = cell2table(conditions, 'VariableNames', conditionsNames);
    ncond = length(conditionsNames);
    for icond = 1:ncond
        curCondStr = conditions.(conditionsNames{icond});
        curCondStr = strsplit(curCondStr{:}, delimiters(1));
        nsubcond = length(curCondStr);        
        curStrOut = cell(nsubcond, nvars);
        for isubcond = 1:nsubcond
            %Split into desired variables.
            tmpOut = strsplit(curCondStr{isubcond}, delimiters(2));
            if all(cellfun(@isempty, tmpOut))
                curStrOut(isubcond, :) = [];
                continue
            end
            if length(tmpOut) ~= nvars
                warning('UDF:SNGPROC:VARNUMMISMATCH', ...
                    'Variable Names number mismatch the data. Please check the data!\n')
                nc = length(conditionsNames);
                conditions = table;
                for ic = 1:nc
                    curStrOut = cell(1, nvars);
                    curStrOut(trans) = {nan};
                    curStrOut(~trans) = {''};
                    conditions.(conditionsNames{ic}) = {cell2table(curStrOut, 'VariableNames', VariablesNames)};
                end
                splitRes = {conditions};
                status = -1;
                return
            end
            %Transforming numeric variables.
            tmpOut(trans) = ...
                cellfun(@str2double, tmpOut(trans), 'UniformOutput', false);
            curStrOut(isubcond, :) = tmpOut;
        end
        % Restructure the data.
        conditions.(conditionsNames{icond}) = {cell2table(curStrOut, 'VariableNames', VariablesNames)};
    end
end
splitRes = {conditions};
status = 0;
