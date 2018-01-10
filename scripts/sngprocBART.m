function [stats, labels] = sngprocBART(NHit, Feedback)
%SNGPROCBART does some basic data transformation to BART task.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

MNHit = mean(NHit(Feedback == 0));
stats = MNHit;
labels = {'MNHit'};
