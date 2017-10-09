function [stats, labels] = SAT(RT, ACC, lisas_weight)

[sum_stats, sum_labels] = behavstats(RT, ACC);
sum_tbl = array2table(sum_stats, 'VariableNames', sum_labels);
if nargin < 3
    lisas_weight = sum_tbl.SRT / sum_tbl.SPE;
end

% inverse efficiency score (IES) (Townsend & Ashby, 1978)
IES = sum_tbl.MRT / (1 - sum_tbl.PE);
% FIX ME! rate of correct score (RCS) (Woltz&Was, 2006)
RCS = nansum(ACC == 1) / nansum(RT / 1000);
% FIX ME! bin score (Hughes, Linck, Bowles, Koeth,&Bunting, 2014)
BS = NaN;
% linear integrated speed-accuracy score (LISAS) (Vandierendonck, 2016)
LISAS = sum_tbl.MRT + lisas_weight * sum_tbl.PE;

stats = [sum_stats, lisas_weight, IES, RCS, BS, LISAS];
labels = [sum_labels, {'lisas_weight', 'IES', 'RCS', 'BS', 'LISAS'}];
