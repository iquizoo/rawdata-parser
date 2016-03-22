function res = attention(qrecordl, qrecordr, cate)
%Data analysis for devided attention task, the names of which are
%1. '分配注意初级' (cate = 1),
%2. '分配注意中级' (cate = 2).

%By Zhang Liang, E-mail:psychelzh@gmail.com, 01/19/2016.

if iscell(qrecordl)
    qrecordl = qrecordl{1};
end
if iscell(qrecordr)
    qrecordr = qrecordr{1};
end

%Left trials.
ACCl = mean(qrecordl.ACC);
RTl = mean(qrecordl.RT(qrecordl.ACC == 1));
%Right trials.
ACCr = mean(qrecordr.ACC);
RTr = mean(qrecordr.RT(qrecordr.ACC == 1));
score = 1000 + (3000 + 500 * cate - RTl) * (ACCl + 0.1) + (3000 + 500 * cate - RTr) * (ACCr + 0.1);
res = table(ACCl, RTl, ACCr, RTr, score);
