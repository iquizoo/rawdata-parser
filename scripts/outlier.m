function [idx, ci] = outlier(x, varargin)
%OUTLIER Gets the index of outlier and confidence interval.
%
%   Reference:
%   1. http://www.itl.nist.gov/div898/handbook/prc/section1/prc16.htm
%   2. http://condor.depaul.edu/dallbrit/extra/resources/ReactionTimeData-2017-4-4.html

par = inputParser;
addParameter(par, 'Method', 'iqr', @(x) validateattributes(x, {'char', 'string'}, {'nonempty'}));
% lower and upper boundary for cutoff
addParameter(par, 'Boundary', [-inf, inf], @(x) validateattributes(x, {'numeric'}, {'numel', 2}));
% the standard deviation limitation
addParameter(par, 'SDLimit', 2, @isnumeric);
% percent number
addParameter(par, 'Number', 2, @isnumeric);
% interquantile range based whisker coefficient
addParameter(par, 'Coefficient', 1.5, @isnumeric);
parse(par, varargin{:})
method = lower(convertStringsToChars(par.Results.Method));
cutoffs = par.Results.Boundary;
sdlimits = par.Results.SDLimit;
percent = par.Results.Number;
coef = par.Results.Coefficient;
if ~ismember(method, {'cutoff', 'sd', 'percent', 'iqr'})
    error('UDF:OUTLIER:UNKOWNMETHOD', 'Not supported method.')
end

% get confidence interval according to method
switch method
    case 'cutoff'
        ci = reshape(cutoffs, 1, 2);
    case 'sd'
        mn = nanmean(x);
        sd = nanstd(x);
        ci = [mn - sdlimits * sd, mn + sdlimits * sd];
    case 'percent'
        ci = quantile(x, [percent / 200, 1 - percent / 200]);
    case 'iqr'
        % get the first quantile and the third quantile.
        Q = quantile(x, [0.25, 0.75]);
        % interquantile range.
        IQR = Q(2) - Q(1);
        ci = [Q(1) - coef * IQR, Q(2) + coef * IQR];
end
idx = x < ci(1) | x > ci(2);
