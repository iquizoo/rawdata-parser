function [stats, labels] = sngprocBART(NHit, Feedback)
%SNGPROCBART Does some basic data transformation to BART task.
%
%   Basically, the supported tasks are as follows:
%     BART
%   The output table contains 1 variables, called MNHit.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

MNHit = mean(NHit(Feedback == 0));
stats = MNHit;
labels = {'MNHit'};
