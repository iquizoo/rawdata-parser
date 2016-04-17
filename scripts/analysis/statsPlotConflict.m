function statsPlotConflict(tbl)
%STATSPLOTCONFLICT Plots basic graphs of report.
%

%By Zhang, Liang. 04/16/2016. E-mai:psychelzh@gmail.com

VarsOfBasicInformation = {'userId', 'gender', 'school', 'grade'};
tblVars = tbl.Properties.VariableNames;
VarsOfTaskData = tblVars(~ismember(tblVars, VarsOfBasicInformation));
if isempty(VarsOfTaskData)
    warning('No data found!')
    return
end
TaskIDName = regexp(VarsOfTaskData{1}, '^\w+?(?=_)', 'match', 'once');
switch TaskIDName
    case {...
            'Flanker',...
            'Stroop1',...
            'Stroop2',...
            }
        varSuff = {'_Overall', '_CongEffect'};
    case 'TaskSwitching'
        varSuff = {'_Overall', '_SwitchCost'};
end
repVarSuff = repmat(varSuff, 2, 1);
chkVarSuff = repVarSuff(:)';
varPref = {'RT', 'ACC'};
chkVars = strcat(repmat(varPref, 1, length(varSuff)), chkVarSuff);
chkTblVarsLoc = false(size(tblVars));
for ivar = 1:length(chkVars)
    chkTblVarsLoc = chkTblVarsLoc | ...
        ~cellfun(@isempty, regexp(tblVars, ['(?<=_)', chkVars{ivar}, '$'], 'once'));
end
chkData = tbl{:, chkTblVarsLoc};
chkTblVars = tblVars(chkTblVarsLoc);
tbl(all(isnan(chkData), 2), :) = [];
chkData(all(isnan(chkData), 2), :) = [];
tbl.grade = removecats(tbl.grade);
grades = cellstr(unique(tbl.grade));
labels = strcat({'Grade '}, grades);
for ichk = 1:length(chkTblVars)
    figure
    boxplot(chkData(:, ichk), tbl.grade, 'Labels', labels, 'Whisker', 3);
    [taskIDName, desp] = regexp(chkTblVars{ichk}, '^\w+?(?=_)', 'match', 'split', 'once');
    title(['Box plot of', strrep(desp{2}, '_', ' '), ' in task ', taskIDName, ' through all grades'])
    bpylabel = regexp(chkTblVars{ichk}, strjoin(varPref, '|'), 'match', 'once');
    if strcmp(bpylabel, 'MRT') || strcmp(bpylabel, 'RT')
        bpylabel = [bpylabel, '(ms)'];
    end
    ylabel(bpylabel)
    hax = gca;
    hax.FontName = 'Gill Sans MT';
    hax.FontSize = 12;
end
for ivsuff = 1:length(varSuff)
    figure
    curSuffVarNames = chkTblVars(~cellfun(@isempty, strfind(chkTblVars, varSuff{ivsuff})));
    axisPos = {'left', 'right'};
    title(['Error bar (SEM) plot of ', strrep(varSuff{ivsuff}, '_', ' '), ' in task ', taskIDName]);
    for ivar = 1:length(varPref)
        yyaxis(axisPos{ivar})
        errorbar(grpstats(tbl.(curSuffVarNames{ivar}), tbl.grade), ...
            grpstats(tbl.(curSuffVarNames{ivar}), tbl.grade, 'sem'))
        ebylabel = regexp(curSuffVarNames{ivar}, strjoin(varPref, '|'), 'match', 'once');
        if strcmp(ebylabel, 'MRT') || strcmp(ebylabel, 'RT')
            ebylabel = [ebylabel, '(ms)'];
        end
        ylabel(ebylabel)
        hax = gca;
        hax.YGrid = 'on';
        hax.GridLineStyle = '-';
        hax.XTick = 1:length(labels);
        hax.XTickLabel = labels;
        hax.FontName = 'Gill Sans MT';
        hax.FontSize = 12;
        hold on
    end
end
