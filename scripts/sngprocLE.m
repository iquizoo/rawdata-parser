function [stats, labels] = sngprocLE(STIM, Resp)
%SNGPROCLE does basic analysis work for Number Line Estimation data

% By Zhang, Liang. E-mail: psychelzh@gmail.com

% calculate mean percent absolute error (MPAE)
MPAE = mean(abs(STIM - Resp) / 100);
% calculate R-squared
lm = fitlm(STIM, Resp, 'RobustOpts', 'on');
R2 = lm.Rsquared.Ordinary;
% compose return values
stats = [MPAE, R2];
labels = {'MPAE', 'R2'};
