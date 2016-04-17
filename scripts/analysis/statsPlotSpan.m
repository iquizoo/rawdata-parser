function statsPlotSpan(tbl)
%STATSPLOTSPAN Plots basic graphs of report.
%

%By Zhang, Liang. 04/16/2016. E-mai:psychelzh@gmail.com

chkVars = {...
    'ML', 'MS'};
tblVars = tbl.Properties.VariableNames;
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
    bpylabel = regexp(chkTblVars{ichk}, strjoin(chkVars, '|'), 'match', 'once');
    if strcmp(bpylabel, 'MRT')
        bpylabel = [bpylabel, '(ms)'];
    end
    ylabel(bpylabel)
    hax = gca;
    hax.FontName = 'Gill Sans MT';
    hax.FontSize = 12;
end
figure
axisPos = {'left', 'right'};
title(['Error bar (SEM) plot in task ', taskIDName]);
for ivar = 1:2
    yyaxis(axisPos{ivar})
    errorbar(grpstats(tbl.(chkTblVars{ivar}), tbl.grade), ...
        grpstats(tbl.(chkTblVars{ivar}), tbl.grade, 'sem'))
    ebylabel = regexp(chkTblVars{ivar}, strjoin(chkVars, '|'), 'match', 'once');
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
