tasks = {'SRT', 'DRT', 'CRT'};%, 'SRTBread', 'SRTWatch'};
allvars = mrgdata.Properties.VariableNames;
RTvars = ~cellfun(@isempty, regexp(allvars, ...
    strjoin(strcat(tasks, '_'), '|'), 'once'));
% rmVars = {'SRT_ACC', 'SRT_VRT', ...
%     'DRT_Rate_Overall', 'DRT_RT_Overall'};
% RTvars = RTvars & ~ismember(allvars, rmVars);
data = mrgdata{:, RTvars};
[r, p] = corr(data, 'rows', 'pairwise');
ticksLabel = strrep(allvars(RTvars), '_', ' ');
nticks = length(ticksLabel);
h = figure;
imagesc(r)
colorbar
hax = gca;
hax.XAxisLocation = 'top';
hax.XTick = 1:nticks;
hax.YTick = 1:nticks;
hax.XTickLabel = ticksLabel;
hax.YTickLabel = ticksLabel;
hax.XTickLabelRotation = 45;
[x, y] = meshgrid(1:nticks, 1:nticks);
texts = arrayfun(@(x) sprintf('%.2f', x), r(:), 'UniformOutput', false);
texts(p(:) < 0.05) = strcat(texts(p(:) < 0.05), '*');
textscolors = repmat([0, 0, 0], size(texts));
textscolors(p(:) < 0.05, :) = repmat([1, 0, 0], size(find(p(:) < 0.05)));
hstrings = text(x(:), y(:), texts, 'HorizontalAlignment','center');
set(hstrings, {'Color'}, num2cell(textscolors, 2))
h.PaperUnits    = 'centimeters';
h.PaperSize     = [40, 36];
normalpappos    = [0.1, 0.1, 0.8, 0.8];
h.PaperPosition = repmat(h.PaperSize, 1, 2) .* normalpappos;
saveas(h, 'correlationMap.tif')