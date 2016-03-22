function res = gncpt(qrecord, cate)
%Data analysis for Go-Nogo and CPT task, the names of which are
%1. '水果忍者(Go-Nogo)' (cate = 1)
%2. '捉虫(CPT)' (cate = 2)
%3. '抵制诱惑(Go-Nogo)' (cate = 1)

%By Zhang Liang, E-mail:psychelzh@gmail.com, 01/18/2016.

if iscell(qrecord)
    qrecord = qrecord{1};
end

%For target (fruit or pest).
targettrial = qrecord(qrecord.STIM_CAT ~= 0, :);
RTtarget = nanmean(targettrial.RT(targettrial.ACC == 1));
ACCtarget = nanmean(targettrial.ACC);
%For nontarget (bomb or beneficial insect).
ntargettrial = qrecord(qrecord.STIM_CAT == 0, :);
corntarget = sum(ntargettrial.ACC);
incorntarget = sum(1 - ntargettrial.ACC);
ACCntarget = mean(ntargettrial.ACC);

score = 1000 + (5500 + 500 * cate - RTtarget) * (ACCtarget + 0.1) - incorntarget * (400 - 100 * cate);
res = table(RTtarget, ACCtarget, corntarget, incorntarget, ACCntarget, score);
