function res = sngprocMemsep(RECORD)
%SNGPROCMEMSEP Does some basic data transformation to memory task.
%
%   Basically, the supported tasks are as follows:
%     PicMemory WordMemory
%   The output table contains 9 variables.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

% set RT of incorrect trials as nan
RECORD.RT(RECORD.ACC ~= 1) = nan;
% set ACC of non-response trials as nan
RECORD.ACC(~ismember(RECORD.ACC, [0, 1])) = nan;

respVars = {'ACC', 'RT'};

% calculate overall RT and ACC
RT = nanmean(RECORD.RT);
ACC = nanmean(RECORD.ACC);

% stimuli type code map
origCodes = 1:3;
typeNames = {'old', 'lure', 'irrelated'};
condNames = {'rold', 'rnew', 'rnew'};
typeMap = containers.Map(origCodes, typeNames);
condMap = containers.Map(origCodes, condNames);
RECORD.type = values(typeMap, num2cell(RECORD.SCat));
RECORD.cond = values(condMap, num2cell(RECORD.SCat));

% summary ACC and RT for each type
typeSummaries = unstack(RECORD(:, [respVars, {'type'}]), respVars, 'type', ...
    'AggregationFunction', @nanmean);
% check if the results for each type exist or not
typeSumVarNames = typeSummaries.Properties.VariableNames;
chkTypeSumVars = strcat(repelem(respVars, length(typeNames)), '_', repmat(typeNames, 1, length(respVars)));
for chkvar = chkTypeSumVars
    if ~ismember(chkvar, typeSumVarNames)
        typeSummaries.(chkvar{:}) = nan;
    end
end
% get the dprime for two kinds of new stimuli
typeSummaries.dprime_lure = sdt(typeSummaries.ACC_old, 1 - typeSummaries.ACC_lure);
typeSummaries.dprime_irrelated = sdt(typeSummaries.ACC_old, 1 - typeSummaries.ACC_irrelated);

% summary ACC and RT for each cond
condSummaries = unstack(RECORD(:, [respVars, {'cond'}]), respVars, 'cond', ...
    'AggregationFunction', @nanmean);
% check if the results for each cond exist or not
condSumVarNames = condSummaries.Properties.VariableNames;
chkCondSumVars = strcat(repelem(respVars, length(condNames)), '_', repmat(condNames, 1, length(respVars)));
for chkvar = chkCondSumVars
    if ~ismember(chkvar, condSumVarNames)
        condSummaries.(chkvar{:}) = nan;
    end
end
% get the dprime of treating all new as one condition
condSummaries.dprime = sdt(condSummaries.ACC_rold, 1 - condSummaries.ACC_rnew);

% store all the results
res = [table(RT, ACC), condSummaries, typeSummaries];
