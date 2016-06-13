function score = sngscoreConflict(RT, ACC, RT_Conflict, ACC_Conflict, maxRT)
%SNGSCORECONFLICT scores those with three parts of information.
%
%   Flanker, Stroop1, Stroop2, 

%Part I: RT score.
RTscore = (3000 - RT) * (RT >= 100 && RT <= maxRT);
%Part II: ACC score.
ACCscore = 2000 * ACC;
%Part III: Congruency Effect/Switch Cost Score.
Conflictscore = 2000 - 5 * RT_Conflict * (RT_Conflict > 0) + 500 * ACC_Conflict * (ACC_Conflict > 0);
%Result score.
score = RTscore + ACCscore + Conflictscore;
