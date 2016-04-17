%方向达人
flankerData = readtable('Merge_方向达人.xlsx', 'Sheet', 'AllData');
flankerData.school = categorical(flankerData.school);
flankerData.grade = categorical(flankerData.grade);
%% Remove data from schools of no interest, and bad results.
schools = categories(flankerData.school);
SchOI = {'劳卫小学';'北房中学';'新开路东总布小学';'棠中外语学校附属小学';'棠湖中学外语实验学校';'玉带山小学';'石楼中学';'重庆市劳卫小学'};
flankerData.school = removecats(flankerData.school, schools(~ismember(schools, SchOI))); 
flankerData(isundefined(flankerData.school), :) = [];
flankerData(isundefined(flankerData.grade), :) = [];
flankerDataOriginStats = grpstats(flankerData, {'school', 'grade'}, 'numel', 'DataVars', 'userId');
flankerData(isnan(flankerData.RT), :) = [];
%Delete this strange sample of data.
flankerData(flankerData.school == '棠中外语学校附属小学' & flankerData.grade == '2', :) = [];
flankerDataClearStats = grpstats(flankerData, {'school', 'grade'}, 'numel', 'DataVars', 'userId');
%% For outlier analysis, coined from http://www.itl.nist.gov/div898/handbook/prc/section1/prc16.htm
flankerOutlier = grpstats(flankerData, 'grade', {@(x)coutlier(x, 'mild'), @(x)coutlier(x, 'extreme')}, ...
    'DataVars', {'ACC', 'RT'}, ...
    'VarNames', {'grade', 'GroupCount', 'MildOutlierCount_ACC', 'ExtremeOutlierCount_ACC', ...
    'MildOutlierCount_RT', 'ExtremeOutlierCount_RT'});
figdir = ['Figures', filesep, 'flanker'];
if ~exist(figdir, 'dir')
    mkdir(figdir)
end
for i = 1:7
    labels{i} = ['Grade ', num2str(i)];
end
varsPlot = {'ACC', 'mild', 1.5; ...
    'ACC', 'extreme', 3; ...
    'RT', 'mild', 1.5; 
    'RT', 'extreme', 3};
for iVar = 1:size(varsPlot, 1)
    figure
    boxplot(flankerData.(varsPlot{iVar, 1}), flankerData.grade, 'Labels', labels, 'Whisker', varsPlot{iVar, 3})
    title(['Flanker task boxplot with ', varsPlot{iVar, 2}, ' outliers'])
    if strcmp(varsPlot{iVar, 1}, 'RT')
        label = [varsPlot{iVar, 1}, '(ms)'];
    else
        label = varsPlot{iVar, 1};
    end
    ylabel(label)
    hax = gca;
    hax.FontName = 'Gill Sans MT';
    hax.FontSize = 12;
    saveas(gcf, [figdir, filesep, 'Flanker ', varsPlot{iVar, 2}, ' outliers ', varsPlot{iVar, 1}, '.jpg']);
    close(gcf);
end
%% Remove extreme outlier, according to ACC.
% [~, extOutIdx] = splitapply(@(x) coutlier(x, 'extreme'), flanker.ACC, findgroups(flanker.grade));
nflankerData = flankerData;
grades = categories(nflankerData.grade);
for igrade = 1:length(grades)
    curgradeidx = nflankerData.grade == grades{igrade};
    [~, outlieridx] = coutlier(nflankerData.ACC(curgradeidx), 'extreme');
    rmidx = curgradeidx;
    rmidx(rmidx == 1) = outlieridx;
    nflankerData.ACC(rmidx) = nan;
    nflankerData.RT(rmidx) = nan;
    histVars = {'ACC', 'RT'};
    for iVar = 1:length(histVars)
        curgradedata = nflankerData.(histVars{iVar})(nflankerData.grade == grades{igrade});
        histogram(curgradedata)
        title(['Histogram of ', histVars{iVar}, ' of flanker task: GRADE ', num2str(igrade)])
        if strcmp(histVars{iVar}, 'RT')
            label = [histVars{iVar}, '(ms)'];
        else
            label = histVars{iVar};
        end
        xlabel(label)
        ylabel('Frequency')
        hax = gca;
        hax.FontName = 'Gill Sans MT';
        hax.FontSize = 12;
        saveas(gcf, [figdir, filesep, 'Histogram of flanker ', histVars{iVar}, ' GRADE ', num2str(igrade), '.jpg']);
        close(gcf);
    end
end

%% Congruency effect.
%Remove outliers.
nflankerData(isnan(nflankerData.RT), :) = [];
%Test of accuracy difference between two conditions.
[~, pVal] = splitapply(@ttest, ...
    nflankerData.ACC_Cong, nflankerData.ACC_Incong, ...
    findgroups(nflankerData.grade));
% boxplot([nflankerData.ACC_Cong(nflankerData.grade == '2'), ...
%     nflankerData.ACC_Incong(nflankerData.grade == '2')], ...
%     'notch', 'on')

% boxplot(nflankerData.ACC_ConfEffect, nflankerData.grade, 'Labels', labels, 'notch', 'on')
[pACC, tblACC, statsACC] = anova1(nflankerData.ACC_ConfEffect, nflankerData.grade, 'off');
cACC = multcompare(statsACC);
% mdlACC = fitlm(nflankerData, 'PredictorVars', 'grade', 'ResponseVar', 'ACC_ConfEffect');
% tblACC = anova(mdlACC);

% boxplot(nflankerData.RT_ConfEffect, nflankerData.grade, 'Labels', labels, 'notch', 'on')
[pRT, tblRT, statsRT] = anova1(nflankerData.RT_ConfEffect, nflankerData.grade, 'off');
cRT = multcompare(statsRT);
% mdlRT = fitlm(nflankerData, 'PredictorVars', 'grade', 'ResponseVar', 'RT_ConfEffect');
% tblRT = anova(mdlRT);

nflankerstats = grpstats(nflankerData, 'grade', {'mean', 'std', 'sem'}, ...
    'DataVars', nflankerData.Properties.VariableNames(7:end));
varsErrorBar = {'ACC', 'RT'};
for ierrbar = 1:length(varsErrorBar)
    bar(nflankerstats.(['mean_', varsErrorBar{ierrbar}, '_ConfEffect']))
    hax = gca;
    hax.YGrid = 'on';
    hax.GridLineStyle = '-';
    hax.XTickLabel = labels;
    hax.FontName = 'Gill Sans MT';
    hax.FontSize = 12;
    ylabel([varsErrorBar{ierrbar}, ' conguency effect']);
    title('Error bar (SEM) plot of congruency effect');
    hold on
    errorbar(nflankerstats.(['mean_', varsErrorBar{ierrbar}, '_ConfEffect']), ...
        nflankerstats.(['sem_', varsErrorBar{ierrbar}, '_ConfEffect']), ...
        'LineStyle', 'none')
    saveas(gcf, [figdir, filesep, 'Congruency effect ', varsErrorBar{ierrbar}, '.jpg']);
    close(gcf);
end

% flankerstats = grpstats(flanker, {'school', 'grade'}, {'numel', 'std', 'mean', 'sem'}, ...
%     'DataVars', flanker.Properties.VariableNames(7:end));
