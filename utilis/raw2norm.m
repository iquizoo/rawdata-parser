function y = raw2norm(x, varargin)
%RAW2NORM tansforms raw score to normalized score and scale them.
%   Y = RAW2NORM(X) use the scale 100 mean and 15 deviation, removing NaN's
%   by default.
%
%   Y = RAW2NORM(X, mean, sd) explicitly tells the program the mean and
%   standard deviation for the data X.
%
%   Y = RAW2NORM(X, ..., Name, Value) does the scaling works according to
%   the specified parameters using the following Name, Value pairs:
%               Center - specifies the scaling center for the
%                        normalization, defalut: 100.
%                Scale - specifies the scaling size for the normalization,
%                        default: 15.
%       MissingRemoval - tells the program to remove missing values or not.
%                        Default: true.
%              Missing - explicitly tells the program the missing value of
%                        the data. Default: NaN.

% Author: Zhang, Liang.
% Date: August 2016.
% E-mail: psychelzh@gmail.com

% Parse input arguments.
par = inputParser;
addOptional(par, 'Mean', [], @isnumeric);
addOptional(par, 'Deviation', [], @isnumeric);
parNames   = { 'Center',  'Scale',              'MissingRemoval',      'Missing'  };
parDflts   = {    100,       15,                      true,               nan     };
parValFuns = {@isnumeric, @isnumeric, @(x) islogical(x) | isnumeric(x), @isnumeric};
cellfun(@(x, y, z) addParameter(par, x, y, z), parNames, parDflts, parValFuns);
parse(par, varargin{:});
mn   = par.Results.Mean;
dev  = par.Results.Deviation;
ctr  = par.Results.Center;
scl  = par.Results.Scale;
rm   = par.Results.MissingRemoval;
miss = par.Results.Missing;
%For a quick return.
if ~isempty(mn) && ~isempty(dev)
    %Normalization.
    ynorm = (x - mn) / dev;
    y     = ynorm * scl + ctr;
else
    if ~isempty(mn) || ~isempty(dev)
        warning('CCDPRO:RAW2NORM', 'Missing input or redundant input arguments found.')
        y = nan;
        return
    end
    if ~rm
        %Normalization.
        ynorm = (x - mean(x)) / std(x);
        y     = ynorm * scl + ctr;
    else
        x(arrayfun(@(elem) isequaln(elem, miss), x)) = nan;
        %Normalization.
        ynorm = (x - nanmean(x)) / nanstd(x);
        y     = ynorm * scl + ctr;
    end
end
