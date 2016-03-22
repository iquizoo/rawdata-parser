function res = smmemory(qrecord, cate)
%Data analysis for memory task, the names of which are
%1. '语义记忆(semantic memory)' (cate = 1)
%2. '符号记忆(symbolic memory)' (cate = 1)
%3. '图片记忆(picture memory)' (cate = 2)
%4. '言语记忆(language memory)' (cate = 1)
%5. '联系记忆(Association Learning)' (cate = 3)

%By Zhang Liang, E-mail:psychelzh@gmail.com, 01/18/2016.

if iscell(qrecord)
    qrecord = qrecord{1};
end

%Information:
%.REP:repetition, only 1 and 2.
%.ACC
%.RT

%REP 1:
rep1trial = qrecord(qrecord.REP == 1, :);
CNUM_R1 = sum(rep1trial.ACC);
RT_R1 = mean(rep1trial.RT(rep1trial.ACC == 1));
%REP 2:
rep2trial = qrecord(qrecord.REP == 2, :);
CNUM_R2 = sum(rep2trial.ACC);
RT_R2 = mean(rep2trial.RT(rep2trial.ACC == 1));

RT = mean(qrecord.RT);

switch cate
    case 1
        score = 1000 + CNUM_R1 * 50 + CNUM_R2 * 35 - RT;
    case 2
        score = 1000 + CNUM_R1 * 60 + CNUM_R2 * 40 - RT;
    case 3
        score = 1000 + CNUM_R1 * 150 + CNUM_R2 * 100 - RT;
end
res = table(CNUM_R1, RT_R1, CNUM_R2, RT_R2, RT, score);
