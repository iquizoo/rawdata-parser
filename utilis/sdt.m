function [dprime, c] = sdt(HR, FAR, ntrial)
%SDT Calculates parameters of signal detection theory.
%   [DPRIME, C] = SDT(HR, FAR) calculates dprime and bias c in signal
%   detection theory. HR and FAR are respectively the hit rate and false
%   alarm rate.
%
%   Reference: 
%   Stanislaw H and Todorov N (1999) "Calculation of signal
%   detection theory measures" Behavior Research Methods, Instruments, &
%   Computers 31 (1), 137-149

%By Zhang, Liang. 04/22/2016. E-mail: psychelzh@gmail.com

% check inputs.
if nargin == 2, ntrial = 100; end % set default trial number as 100.

%When either HR or FAR equals to 1 or 0, the output would otherwise result
%in unexpected value.
HR(HR == 1) = 1 - 1 / ntrial;
HR(HR == 0) = 1 / ntrial;
FAR(FAR == 1) = 1 - 1 / ntrial;
FAR(FAR == 0) = 1 / ntrial;
%d' and c.
dprime = norminv(HR) - norminv(FAR);
c = - (norminv(HR) + norminv(FAR)) / 2;
