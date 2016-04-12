function res = span(qrecord, cate)
%Data analysis for span tasks, the names of which are 
%1. '顺背数(Digit Span)' (cate =1), 
%2. '倒背数(Digit Span(R))' (cate = 2), and 
%3. '位置记忆(Spatial Span)' (cate = 3).

%By Zhang Liang, E-mail:psychelzh@gmail.com, 01/16/2016.

if iscell(qrecord)
    qrecord = qrecord{1};
end

%Information:
%Four variables: TIME, ACC, Stimuli_Series, Resp_Series.
%Get the length of stimuli series of each trial.
trllen = cellfun(@length, qrecord.Stimuli_Series);
%Get the accuracy information of each trial.
acc = qrecord.ACC;
%Get the maximal correct length and accuracy.
maxlen = max(trllen(acc == 1));
if ~isempty(maxlen)
    maxacc = mean(acc(trllen == maxlen));
    %The second maximal correct length, i.e., maxlen - 1.
    secmaxlen = maxlen - 1;
    secmaxacc = mean(acc(trllen == secmaxlen));
    %Calculate score.
    x = maxlen;
    y = maxacc;
    z = secmaxacc;
    score = (x - 1 + y + z * 0.5) * (300 + 100 * cate) + 1000;
else
    maxlen = 0;
    maxacc = 0;
    secmaxlen = 0;
    secmaxacc = 0;
    score = 0;
end
res = table(maxlen, maxacc, secmaxlen, secmaxacc, score);
