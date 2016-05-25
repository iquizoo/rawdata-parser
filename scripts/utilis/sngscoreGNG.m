function score = sngscoreGNG(RT_hit, Rate_hit, Count_FA)
%

%Part I:
RTscore = (3000 - RT_hit) * (RT_hit >= 100 && RT_hit <= 3000);
%Part II:
ACCscore = 2000 * Rate_hit;
%Part III:
FAscore = 300 * Count_FA;

score = RTscore + ACCscore - FAscore;
