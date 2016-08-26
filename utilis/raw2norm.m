function y = raw2norm(x, varargin)
%RAW2NORM tansforms raw score to normalized score and scale them.
%   Y = RAW2NORM(X) use the scale 100 mean and 15 deviation without
%   attention to NaNs.

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
