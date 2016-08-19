function y = raw2norm(x, varargin)
%RAW2NORM tansforms raw score to normalized score and scale them.
%   Y = RAW2NORM(X) use the scale 100 mean and 15 deviation without
%   attention to NaNs.

% Parse input arguments.
par = inputParser;
addOptional(par, 'Mean', [], @isnumeric);
addOptional(par, 'Deviation', [], @isnumeric);
parNames   = {          'MissingRemoval',      'Missing'  };
parDflts   = {               false,               nan     };
parValFuns = {@(x) islogical(x) | isnumeric(x), @isnumeric};
cellfun(@(x, y, z) addParameter(par, x, y, z), parNames, parDflts, parValFuns);
parse(par, varargin{:});
mn   = par.Results.Mean;
dev  = par.Results.Deviation;
rm   = par.Results.MissingRemoval;
miss = par.Results.Missing;
%For a quick return.
if ~isempty(mn) && ~isempty(dev)
    %Normalization.
    ynorm = (x - mn) / dev;
    y     = ynorm * 15 + 100;
else
    if ~rm
        %Normalization.
        ynorm = (x - mean(x)) / std(x);
        y     = ynorm * 15 + 100;
    else
        x(arrayfun(@(elem) isequaln(elem, miss), x)) = nan;
        %Normalization.
        ynorm = (x - nanmean(x)) / nanstd(x);
        y     = ynorm * 15 + 100;
    end
end
