%方向达人
CRTData = readtable('Merge_选择速度.xlsx', 'Sheet', 'AllData');
CRTData.school = categorical(CRTData.school);
CRTData.grade = categorical(CRTData.grade);
%% Remove data from schools of no interest, and bad results.
schools = categories(CRTData.school);
SchOI = {'劳卫小学';'北房中学';'新开路东总布小学';'棠中外语学校附属小学';'棠湖中学外语实验学校';'玉带山小学';'石楼中学';'重庆市劳卫小学'};
CRTData.school = removecats(CRTData.school, schools(~ismember(schools, SchOI))); 
CRTData(isundefined(CRTData.school), :) = [];
CRTData(isundefined(CRTData.grade), :) = [];
CRTDataOriginStats = grpstats(CRTData, {'school', 'grade'}, 'numel', 'DataVars', 'userId');
CRTData(isnan(CRTData.MRT), :) = [];
CRTData(CRTData.VRT == 0, :) = [];
%Delete this strange sample of data.
CRTData(CRTData.school == '棠中外语学校附属小学' & CRTData.grade == '2', :) = [];
CRTDataClearStats = grpstats(CRTData, {'school', 'grade'}, 'numel', 'DataVars', 'userId');
%% For outlier analysis, coined from http://www.itl.nist.gov/div898/handbook/prc/section1/prc16.htm
CRTOutlier = grpstats(CRTData, 'grade', {@(x)coutlier(x, 'mild'), @(x)coutlier(x, 'extreme')}, ...
    'DataVars', {'ACC', 'MRT', 'v'}, ...
    'VarNames', {'grade', 'GroupCount', 'MildOutlierCount_ACC', 'ExtremeOutlierCount_ACC', ...
    'MildOutlierCount_MRT', 'ExtremeOutlierCount_MRT', ...
    'MildOutlierCount_v', 'ExtremeOutlierCount_v'});
figdir = ['Figures', filesep, 'CRT'];
if ~exist(figdir, 'dir')
    mkdir(figdir)
end
for i = 1:6
    labels{i} = ['Grade ', num2str(i)];
end
varsPlot = {'ACC', 'mild', 1.5; ...
    'ACC', 'extreme', 3; ...
    'MRT', 'mild', 1.5; 
    'MRT', 'extreme', 3;
    'v', 'mild', 1.5;
    'v', 'mild', 3};
for iVar = 1:size(varsPlot, 1)
    figure
    boxplot(CRTData.(varsPlot{iVar, 1}), CRTData.grade, 'Labels', labels, 'Whisker', varsPlot{iVar, 3})
    title(['CRT task boxplot with ', varsPlot{iVar, 2}, ' outliers'])
    if strcmp(varsPlot{iVar, 1}, 'MRT')
        label = [varsPlot{iVar, 1}, '(ms)'];
    else
        label = varsPlot{iVar, 1};
    end
    ylabel(label)
    hax = gca;
    hax.FontName = 'Gill Sans MT';
    hax.FontSize = 12;
    saveas(gcf, [figdir, filesep, 'CRT ', varsPlot{iVar, 2}, ' outliers ', varsPlot{iVar, 1}, '.jpg']);
    close(gcf);
end
%% Remove extreme outlier, according to ACC.
% [~, extOutIdx] = splitapply(@(x) coutlier(x, 'extreme'), CRT.ACC, findgroups(CRT.grade));
nCRTData = CRTData;
grades = categories(nCRTData.grade);
for igrade = 1:length(grades)
    curgradeidx = nCRTData.grade == grades{igrade};
    [~, outlieridx] = coutlier(nCRTData.ACC(curgradeidx), 'extreme');
    rmidx = curgradeidx;
    rmidx(rmidx == 1) = outlieridx;
    nCRTData.ACC(rmidx) = nan;
    nCRTData.MRT(rmidx) = nan;
    histVars = {'ACC', 'MRT', 'v'};
    for iVar = 1:length(histVars)
        curgradedata = nCRTData.(histVars{iVar})(nCRTData.grade == grades{igrade});
        histogram(curgradedata)
        title(['Histogram of ', histVars{iVar}, ' of CRT task: GRADE ', num2str(igrade)])
        if strcmp(histVars{iVar}, 'MRT')
            label = [histVars{iVar}, '(ms)'];
        else
            label = histVars{iVar};
        end
        xlabel(label)
        ylabel('Frequency')
        hax = gca;
        hax.FontName = 'Gill Sans MT';
        hax.FontSize = 12;
        saveas(gcf, [figdir, filesep, 'Histogram of CRT ', histVars{iVar}, ' GRADE ', num2str(igrade), '.jpg']);
        close(gcf);
    end
end

%% Congruency effect.
%Remove outliers.
nCRTData(isnan(nCRTData.MRT), :) = [];
%Test of accuracy difference between two conditions.
% [~, pVal] = splitapply(@ttest, ...
%     nCRTData.ACC_Cong, nCRTData.ACC_Incong, ...
%     findgroups(nCRTData.grade));
% boxplot([nCRTData.ACC_Cong(nCRTData.grade == '2'), ...
%     nCRTData.ACC_Incong(nCRTData.grade == '2')], ...
%     'notch', 'on')

% boxplot(nCRTData.ACC_ConfEffect, nCRTData.grade, 'Labels', labels, 'notch', 'on')
[pACC, tblACC, statsACC] = anova1(nCRTData.ACC, nCRTData.grade, 'off');
cACC = multcompare(statsACC);
% mdlACC = fitlm(nCRTData, 'PredictorVars', 'grade', 'ResponseVar', 'ACC_ConfEffect');
% tblACC = anova(mdlACC);

% boxplot(nCRTData.MRT_ConfEffect, nCRTData.grade, 'Labels', labels, 'notch', 'on')
[pMRT, tblMRT, statsMRT] = anova1(nCRTData.MRT, nCRTData.grade, 'off');
cMRT = multcompare(statsMRT);
% mdlMRT = fitlm(nCRTData, 'PredictorVars', 'grade', 'ResponseVar', 'MRT_ConfEffect');
% tblMRT = anova(mdlMRT);

[pv, tblv, statsv] = anova1(nCRTData.v, nCRTData.grade, 'off');
cv = multcompare(statsv);

nCRTstats = grpstats(nCRTData, 'grade', {'mean', 'std', 'sem'}, ...
    'DataVars', nCRTData.Properties.VariableNames(7:end));
varsErrorBar = {'ACC', 'MRT', 'v'};
for ierrbar = 1:length(varsErrorBar)
    bar(nCRTstats.(['mean_', varsErrorBar{ierrbar}]))
    hax = gca;
    hax.YGrid = 'on';
    hax.GridLineStyle = '-';
    hax.XTickLabel = labels;
    hax.FontName = 'Gill Sans MT';
    hax.FontSize = 12;
    ylabel(strrep(varsErrorBar{ierrbar}, '_', ' '));
    title('Error bar (SEM) plot of all groups');
    hold on
    errorbar(nCRTstats.(['mean_', varsErrorBar{ierrbar}]), ...
        nCRTstats.(['sem_', varsErrorBar{ierrbar}]), ...
        'LineStyle', 'none')
    saveas(gcf, [figdir, filesep, 'Error bar plot ', varsErrorBar{ierrbar}, '.jpg']);
    close(gcf);
end

% CRTstats = grpstats(CRT, {'school', 'grade'}, {'numel', 'std', 'mean', 'sem'}, ...
%     'DataVars', CRT.Properties.VariableNames(7:end));
