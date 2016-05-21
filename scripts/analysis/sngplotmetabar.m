function [h, hname] = sngplotmetabar(metadata)
%SNGPLOTMETABAR bar plot for metadata.


%Get all the grades and school names.
grades = cellstr(unique(metadata.grade));
schools = cellstr(unique(metadata.school, 'stable'));
ngrades = length(grades);
nschools = length(schools);
%Set the plot data.
plotdata = nan(ngrades, nschools);
for ischool = 1:nschools
    plotdata(:, ischool) = countcats(metadata.grade(metadata.school == schools{ischool}));
end
%Open an invisible figure.
h = figure;
h.Visible = 'off';
hname = 'Bar plot to show metadata';
bar3(plotdata);
title('Summary of data collection from each school and each grade');
hax = gca;
hax.FontName = 'Microsoft YaHei UI Light';
hax.FontSize = 12;
hax.XTick = 1:length(schools);
hax.YTick = 1:length(grades);
hax.XTickLabel = schools;
hax.YTickLabel = grades;
hax.XLabel.String = 'School';
hax.YLabel.String = 'Grade';
hax.ZLabel.String = 'Count';
