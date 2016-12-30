function [idx, ci] = outlier(x, outliermode)
%OUTLIER gets the index of outliers.
%
%   [IDX, CI] = OUTLIER(X, mode) calculates the index of the outliers in
%   the vector X, and uses two types of modes:
%       'mild'  means the whisker is 1.5 * IQR.
%       '
%
%   Reference:
%   http://www.itl.nist.gov/div898/handbook/prc/section1/prc16.htm

if nargin <= 1
    outliermode = 'mild';
end
%Get the first quartile and the third quartile.
Q = quantile(x, [0.25, 0.75]);
%Interquantile range.
IQR = Q(2) - Q(1);
%For mild outliers, w = 1.5; for extreme outliers, w = 3.
switch outliermode
    case 'mild'
        w = 1.5;
    case 'extreme'
        w = 3;
end
LF = Q(1) - w * IQR;
UF = Q(2) + w * IQR;
ci = [LF, UF];
idx = x > UF | x < LF;
