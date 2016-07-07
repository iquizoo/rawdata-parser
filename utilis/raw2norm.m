function y = raw2norm(x, nanrm)
%RAW2NORM tansforms raw score to normalized score and scale them.
%   Y = RAW2NORM(X) use the scale 100 mean and 15 deviation without
%   attention to NaNs.

%Check input arguments.
if nargin < 2
    nanrm = false;
end
if nanrm
    meanfun = @nanmean;
    stdfun  = @nanstd;
else
    meanfun = @mean;
    stdfun  = @std;
end
%Normalization.
ynorm = (x - meanfun(x)) / stdfun(x);
y     = ynorm * 15 + 100;
