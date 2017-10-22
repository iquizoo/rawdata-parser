function [stats, labels] = SAT(RT, ACC, varargin)
% SAT calculates indicators considering speed-accuracy tradeoff

par = inputParser;
par.KeepUnmatched = true;
addOptional(par, 'LisasWeight', [], @isnumeric);
parse(par, varargin{:})
lisas_weight = par.Results.LisasWeight;
% outlier removal protocol is specified as additional arguments
if ismember('LisasWeight', par.UsingDefaults)
    [sum_stats, sum_labels] = behavstats(RT, ACC, varargin{:});
else
    [sum_stats, sum_labels] = behavstats(RT, ACC, varargin{2:end});
end
sum_tbl = array2table(sum_stats, 'VariableNames', sum_labels);
if isempty(lisas_weight)
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
