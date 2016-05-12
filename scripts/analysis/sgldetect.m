function [dprime, c] = sgldetect(HR, FAR)
%SGLDETECT Calculates parameters of signal detection theory.
%   [DPRIME, C] = SNGDETECT(HR, FAR) calculates dprime and bias c in signal
%   detection theory. HR and FAR are respectively the hit rate and false
%   alarm rate.
%
%   Reference: 
%   Stanislaw H and Todorov N (1999) "Calculation of signal
%   detection theory measures" Behavior Research Methods, Instruments, &
%   Computers 31 (1), 137-149

%By Zhang, Liang. 04/22/2016. E-mail: psychelzh@gmail.com

%When either HR or FAR equals to 1 or 0, the output would otherwise result
%in unexpected value.
HR(HR == 1) = 0.99;
HR(HR == 0) = 0.01;
FAR(FAR == 1) = 0.99;
FAR(FAR == 0) = 0.01;
%d' and c.
dprime = norminv(HR) - norminv(FAR);
c = - (norminv(HR) + norminv(FAR)) / 2;
