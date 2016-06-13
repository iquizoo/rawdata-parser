function score = sngscoreLang(TotalTime, TotalScore)
%

%TotalTime
Timescore = (90 - TotalTime / 1000) * (TotalTime / 1000 > 90) * 30;
%Correction
ACCscore = TotalScore * (TotalScore > 0) * 50;
score = Timescore + ACCscore + 1000;
