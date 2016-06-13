function [v, a, Ter] = EZdif(Pc, MRT, VRT, s)
%EZDIF Calculates parameters of EZ-diffusion model.
%   [V,A,TER] = EZdif(PC,MRT,VRT) receives 3 inputs, respectively: Pc is
%   the proportion of correct, i.e., rate of accuracy; MRT(unit: sec) is
%   mean reaction time of correct responses; VRT(unit: sec) is variance of
%   reactio time of correct responses. And its outputs, V is the drifting
%   rate, which is said as a fixed property of the condition or the
%   participant; A is the boundary separation, which is said to be under
%   the control of the participant (Wagenmakers, 2007); and TER is the
%   nondecision time.
%
%   [V,A,TER] = EZdif(...,s) receives the fourth inputs S as the scaling
%   parameter, which is just an arbitrary value.
%
%   Reference:
%   Wagenmakers, E.-J., van der Maas, H. J. L., & Grasman, R. P. P.
%   P.(2007). An EZ-diffusion model for response time and accuracy.
%   Psychonomic Bulletin & Review, 14, 3-22.

%By Zhang, Liang. 04/05/2016. E-mail: psychelzh@gmail.com

%Set default s as 0.1.
if nargin == 3
    s = 0.1;
end

%In case of VRT equals to 0, the data must be singular, and return NaNs to
%result.
if VRT == 0
    v = nan;
    a = nan;
    Ter = nan;
    return
end

%When pc is 0, 0.5, or 1, there needs some modification of Pc.
Pc(Pc == 0) = 0.01;
Pc(Pc == 1) = 0.99;
Pc(Pc == 0.5) = 0.51; % This is a little arbitrary.

%Calculate logit of Pc.
y = log(Pc ./ (1 - Pc));

%Calculate v.
v = sign(Pc - 0.5) .* s .* ((y .* (Pc .^ 2 .* y - Pc .* y + Pc - 0.5)) ./ VRT) .^ (1 / 4);

%Calculate a.
a = s^2 .* y ./ v;

%Calculate Ter.
Ter = MRT - (2 * Pc - 1) .* a ./ (2 * v);
