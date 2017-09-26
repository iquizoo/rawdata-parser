function res = sngprocMemrep(RECORD)
%SNGPROCSMEMREP Does some basic data transformation to semantic memory task.
%
%   Basically, the supported tasks are as follows:
%     AssocMemory SemanticMemory
%   The output table contains 9 variables.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

% set RT of incorrect trials as nan
RECORD.RT(RECORD.ACC ~= 1) = nan;
% set ACC of non-response trials as nan
RECORD.ACC(~ismember(RECORD.ACC, [0, 1])) = nan;
% define response variable names
respVars = {'ACC', 'RT'};
% overall ACC and mean RT
ACC = nanmean(RECORD.ACC);
RT = nanmean(RECORD.RT);
angACC = asin(sqrt(ACC));
% check repetition times
repCodes = 1:2;
repNames = {'R1', 'R2'};
repMap = containers.Map(repCodes, repNames);
RECORD.REP = values(repMap, num2cell(RECORD.REP));

% summary ACC and RT for each repetition
repSummaries = unstack(RECORD(:, [respVars, {'REP'}]), respVars, 'REP', ...
    'AggregationFunction', @nanmean);
% check if the results for each repetition exist or not
sumVarNames = repSummaries.Properties.VariableNames;
chkSumVars = strcat(repelem(respVars, length(repNames)), '_', repmat(repNames, 1, length(respVars)));
for chkvar = chkSumVars
    if ~ismember(chkvar, sumVarNames)
        repSummaries.(chkvar{:}) = nan;
    end
end

% store all the results
res = [table(ACC, RT, angACC), repSummaries];
