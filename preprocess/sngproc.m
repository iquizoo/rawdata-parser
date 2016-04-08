function [splitRes, status] = sngproc(conditions, curTaskPara)
%SNGPROC Preprocessing the data of one single subject.

%By Zhang, Liang. 04/07/2016, E-mail:psychelzh@gmail.com

%Extract useful information form parameters.
curTaskPara = curTaskPara{:};
if isempty(curTaskPara)
    warning('UDF:SNGPROC:PARANOTFOUND', ...
        'No parameters specification is found,\n')
    splitRes = {table};
    status = -2;
    return
end
%Delimiters.
delimiters = curTaskPara.Delimiters{1};
%Output table variables names.
VariablesNames = strsplit(curTaskPara.VariablesNames{:});
nvars = length(VariablesNames);
%Output that need to be transformed into numeric data.
charVars = str2double(num2cell(num2str(curTaskPara.VariablesChar)'));
trans = ~ismember(1:nvars, charVars);
if ~isempty(conditions{:})    
    %Split the conditions.
    % Determine when there exists two seperate conditions.
    if curTaskPara.SplitMode == 1
        conditions = strsplit(conditions{:}, delimiters(1));
        delimiters = delimiters(2:end);
        conditionsNames = strsplit(curTaskPara.AddInfo{1});
        if length(conditions) ~= length(conditionsNames)
            warning('UDF:SNGPROC:MODE1ABNORMAL', ...
                'More partition condition than expected, will return empty result. Please check the data.\n')
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
    else
        conditionsNames = {'RECORD'};
    end
    % Routine split.
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
