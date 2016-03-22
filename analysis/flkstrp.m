function res = flkstrp(qrecord, cate)
%Data analysis for flanker and Stroop task, the names of which are
%1. '方向达人(flanker)', (cate = 1)
%2. '颜色达人(Stroop)', (cate = 2)
%3. '思维转换(Shifting)', (cate = 3)

%By Zhang Liang, E-mail:psychelzh@gmail.com, 01/18/2016.

if iscell(qrecord)
    qrecord = qrecord{1};
end

%Information:
%.STIM_CAT:Congruent & Incongruent(刺激类型)
%.ACC:1=Right,0=Wrong(正确与否)
%.RESP:1=Left,2=Right,0=None(被试操作)
%.RT

switch cate
    case 1
        conditions = {'Cong', 'Incong'};
        condcode = {{1, 3}; {2, 4}};
    case 2
        conditions = {'Cong', 'Incong'};
        condcode = {{1}; {0}};
    case 3
        conditions = {'Nonswitch', 'Switch'};
        condcode = {{1}; {2}};
end
condn = length(conditions);
%Get all the conditions data.
for coni = 1:condn
    RTrec = qrecord.RT(ismember(qrecord.STIM_CAT, cell2mat(condcode{coni})));
    ACCrec = qrecord.ACC(ismember(qrecord.STIM_CAT, cell2mat(condcode{coni})));
    RT = mean(RTrec(ACCrec == 1));
    ACC = mean(ACCrec);
    eval(['res.RT_', conditions{coni}, '=RT;']);
    eval(['res.ACC_', conditions{coni}, '=ACC;']);
end
res.RT = mean(qrecord.RT(qrecord.ACC == 1));
res.ACC = mean(qrecord.ACC);
%Calculate the score.
%RT part.
rawScRT = 3000 - res.RT;
if rawScRT > 0
    scoreRT = rawScRT;
else
    scoreRT = 0;
end
%ACC part.
scoreACC = 2000 * res.ACC;
%Conflict effect part
eval(['switchcostRT = res.RT_', conditions{2}, '-res.RT_', conditions{1}, ';']);
eval(['switchcostACC = res.ACC_', conditions{1}, '-res.ACC_', conditions{2}, ';']);
eval(['rawScConflict = 2000 - (switchcostRT * 5 + switchcostACC * 50) * res.ACC_', conditions{2}, ';']);
if rawScConflict > 0
    scoreConflict = rawScConflict;
else
    scoreConflict = 0;
end
score = scoreRT + scoreACC + scoreConflict;
res.score = score;
res = struct2table(res);
