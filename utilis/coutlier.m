function [n, idx] = coutlier(x, outliermode)
%COUTLIER counts the number and gets the index of outliers.
%
%   Reference:
%   http://www.itl.nist.gov/div898/handbook/prc/section1/prc16.htm

%Get the first quartile and the third quartile.
Q = quantile(x, [0.25, 0.75]);
%Interquantile range.
IQ = Q(2) - Q(1);
%For mild outliers, w = 1.5; for extreme outliers, w = 3.
switch outliermode
    case 'mild'
        w = 1.5;
    case 'extreme'
        w = 3;
end
LF = Q(1) - w * IQ;
UF = Q(2) + w * IQ;
idx = x > UF | x < LF;
n = sum(idx);
