function h = plotcorr(r, varargin)
%PLOTCORR plot an image of correlation coefficient, with p's.
%   H = PLOTCORR(R) input R is the correlation matrix, without any 

%Parse input variables.
par = inputParser;
ParNames   = {'VarNames', 'XAxisLocation', 'XTickLabelRotation'};
ParDflts   = {   '',          '',                0             };
ParValFuns = {@(x)ischar(x) | iscellstr(x),       @ischar,         @isnumeric       };
addRequired(par, 'r', @isnumeric);
addOptional(par, 'p', nan(size(r)), @isnumeric);
cellfun(@(x, y, z) addParameter(par, x, y, z), ParNames, ParDflts, ParValFuns);
parse(par, r, varargin{:});
%Get the variables number.
nvars = size(r, 1);
%Open a figure and plot the image. Set those r's of NaN as transparent.
himage = figure;
imagesc(r, 'AlphaData', ~isnan(r))
colorbar
%Set the ticklabel of the image.
hax = gca;
if ~isempty(par.Results.XAxisLocation)
    hax.XAxisLocation = par.Results.XAxisLocation;
end
names = par.Results.VarNames;
if ~isempty(names)
    hax.XTick = 1:nvars;
    hax.YTick = 1:nvars;
    hax.XTickLabel = names;
    hax.YTickLabel = names;
    hax.XTickLabelRotation = par.Results.XTickLabelRotation;
end
%Set the correlation efficient and significant level.
[x, y] = meshgrid(1:nvars, 1:nvars);
texts = arrayfun(@(x) sprintf('%.2f', x), r(:), 'UniformOutput', false);
texts = strrep(texts, 'NaN', '');
textscolors = repmat([0, 0, 0], size(texts));
p = par.Results.p;
sigsign = discretize(p, [0, 0.001, 0.01, 0.05, 0.1, 1], ...
    'categorical', {'***', '**', '*', '#', 'ns'});
sigsign = categorical(sigsign, 'Ordinal', true);
repsign = sigsign(:) <= '#';
if any(repsign)
    texts(repsign) = strcat(texts(repsign), '^{', ...
        cellfun(@char, num2cell(sigsign(repsign)), 'UniformOutput', false), '}');
    textscolors(p(:) < 0.05, :) = repmat([1, 0, 0], size(find(p(:) < 0.05)));
end
hstrings = text(x(:), y(:), texts, 'HorizontalAlignment','center');
set(hstrings, {'Color'}, num2cell(textscolors, 2))
if nargout == 1
    h = himage;
end
