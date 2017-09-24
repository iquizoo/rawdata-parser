function h = plotcorr(r, varargin)
%PLOTCORR plot an image of correlation coefficient, with p's.
%   PLOTCORR(r) input r is the correlation matrix, without any significance
%   information.
%
%   PLOTCORR(r, p) input p is the corresponding p-values of r, and the
%   significance level would plot as '***', '**', '*', '#', and significant
%   results will be denoted as red.
%
%   PLOTCORR(r, ..., Name, Value) adds options for plot. Options including:
%       'VarNames', which denotes all of the variable names for each row of
%       the correlation matrix.
%       'XAxisLocation', which informs the location of x-axis, default as
%       'bottom'.
%       'XTickLabelRotation', which informs whether to rotate the
%       x-ticklabels or not.
%       'FullMatrix', which informs whether to plot the full correlation
%       matrix or not, default as true. When set false, only half of the
%       matrix is plotted, according the XAxisLocation.
%
%   h = PLOTCORR(r, ...) returns a graphical handle.
%
%   See also imagesc.

%By Zhang, Liang. 07/07/2016. E-mail: psychelzh@gmail.com

%Parse input variables.
par = inputParser;
parNames   = {       'VarNames',         'XAxisLocation', 'XTickLabelRotation',          'FullMatrix'       };
parDflts   = {            '',               'bottom',            0,                          true           };
parValFuns = {@(x)ischar(x) | iscellstr(x),  @ischar,        @isnumeric,    @(x) islogical(x) | isnumeric(x)};
addOptional(par, 'p', nan(size(r)), @isnumeric);
cellfun(@(x, y, z) addParameter(par, x, y, z), parNames, parDflts, parValFuns);
parse(par, varargin{:});
%Get the corresponding parameters.
p        = par.Results.p;
names    = par.Results.VarNames;
xaxisloc  = par.Results.XAxisLocation;
xlabelrot = par.Results.XTickLabelRotation;
fullmat  = par.Results.FullMatrix;
%Get the variables number.
nvars = size(r, 1);
%Set the parameters according full plot or not.
if ~fullmat
    if strcmp(xaxisloc, 'top')
        matSelFun   = @triu;
        yaxisloc    = 'right';
        colorbarLoc = 'westoutside';
    else
        matSelFun   = @tril;
        yaxisloc    = 'left';
        colorbarLoc = 'eastoutside';
    end
else
    matSelFun   = @(x) x;
    yaxisloc    = 'left';
    colorbarLoc = 'eastoutside';
end
%Change matrix r and p according to input arguments.
rSel = matSelFun(true(size(r)));
rTrans = nan(size(r));
rTrans(rSel) = r(rSel);
pTrans = ones(size(r));
pTrans(rSel) = p(rSel);
%Open a figure and plot the image. Set those r's of NaN as transparent.
himage = figure;
imagesc(rTrans, 'AlphaData', ~isnan(rTrans))
colorbar(colorbarLoc)
%Set the ticklabel of the image.
hax = gca;
hax.XAxisLocation = xaxisloc;
hax.YAxisLocation = yaxisloc;
if ~isempty(names)
    hax.XTick = 1:nvars;
    hax.YTick = 1:nvars;
    hax.XTickLabel = names;
    hax.YTickLabel = names;
    hax.XTickLabelRotation = xlabelrot;
end
%Set the correlation efficient and significant level.
[x, y] = meshgrid(1:nvars, 1:nvars);
texts = arrayfun(@(x) sprintf('%.2f', x), rTrans(:), 'UniformOutput', false);
texts = strrep(texts, 'NaN', '');
textscolors = repmat([0, 0, 0], size(texts));
sigsign = discretize(pTrans, [0, 0.001, 0.01, 0.05, 0.1, 1], ...
    'categorical', {'***', '**', '*', '#', 'ns'});
sigsign = categorical(sigsign, 'Ordinal', true);
repsign = sigsign(:) <= '#';
if any(repsign)
    texts(repsign) = strcat(texts(repsign), '^{', ...
        cellfun(@char, num2cell(sigsign(repsign)), 'UniformOutput', false), '}');
    textscolors(pTrans(:) < 0.05, :) = repmat([1, 0, 0], size(find(pTrans(:) < 0.05)));
end
hstrings = text(x(:), y(:), texts, 'HorizontalAlignment','center');
set(hstrings, {'Color'}, num2cell(textscolors, 2))
if nargout > 0
    h = himage;
end
