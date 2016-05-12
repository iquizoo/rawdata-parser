function sngplotmetabar(metadata)
%SNGPLOTMETABAR bar plot for metadata.

%Get all the grades and school names.
grades = cellstr(unique(metadata.grade));
schools = cellstr(unique(metadata.school));
ngrades = length(grades);
nschools = length(schools);
%Set the plot data.
plotdata = nan(ngrades, nschools);
for ischool = 1:nschools
    plotdata(:, ischool) = countcats(metadata.grade(metadata.school == schools{ischool}));
end
bar(plotdata);
hax = gca;
hax.FontName = 'Microsoft YaHei UI Light';
hax.FontSize = 12;
hax.XTickLabel = grades;
hax.XLabel.String = 'Grade';
hax.YLabel.String = 'Count';
hax.YGrid = 'on';
legend(schools, 'FontSize', 9, 'Location', 'best')
