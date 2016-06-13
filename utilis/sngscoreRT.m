function score = sngscoreRT(MRT, ACC, maxRT, weightRT, weightACC)
%

%
RTscore = (weightRT - MRT) * (MRT >= 100 && MRT <= maxRT);
%
ACCscore = weightACC * ACC;
%
score = RTscore + ACCscore;
