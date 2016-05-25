function score = sngscoreSpan(ML, MLACC, MLNextACC, weight)
%

score = (ML - 1 + MLACC + 0.5 * MLNextACC) * weight + 1000;
