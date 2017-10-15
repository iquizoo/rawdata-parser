function [v, a, Ter] = EZdif(PC, MRT, SRT, s)
%EZDIF Calculates parameters of EZ-diffusion model.
%   [V,A,TER] = EZdif(PC,MRT,VRT) receives 3 inputs, respectively:
%       PC - the proportion of correct, i.e., rate of accuracy;
%       MRT - mean of correct reaction time (unit: sec);
%       SRT - standard deviation of correct reaction time (unit: sec).
%   And its outputs:
%       V - the drifting rate, a fixed property of the condition or the
%           participant;
%       A - the boundary separation, which is said to be under the control
%           of the participant ;
%       TER - the nondecision time.(Wagenmakers, 2007)
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
if SRT == 0
    v = nan;
    a = nan;
    Ter = nan;
    return
end

%When pc is 0, 0.5, or 1, there needs some modification of Pc.
PC(PC == 0) = 0.01;
PC(PC == 1) = 0.99;
PC(PC == 0.5) = 0.51; % This is a little arbitrary.

%Calculate logit of Pc.
y = log(PC ./ (1 - PC));

%Calculate v.
v = sign(PC - 0.5) .* s .* ((y .* (PC .^ 2 .* y - PC .* y + PC - 0.5)) ./ SRT) .^ (1 / 4);

%Calculate a.
a = s^2 .* y ./ v;

%Calculate Ter.
Ter = MRT - (2 * PC - 1) .* a ./ (2 * v);
