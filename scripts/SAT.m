function [stats, labels] = SAT(RT, ACC, varargin)

par = inputParser;
addOptional(par, 'LisasWeight', NaN, @isnumeric)
parse(par, varargin{:});
lisas_weight = par.Results.LisasWeight;

% record trial information
NTrial = length(RT);
NResp = sum(ACC ~= -1);
% set ACC of NaN RT as NaN
ACC(isnan(RT)) = NaN;
NInclude = sum(~isnan(ACC));
PE = 1 - nanmean(ACC);
SPE = nanstd(ACC);
MRT = mean(RT(ACC == 1));
SRT = std(RT(ACC == 1));
if isnan(lisas_weight)
    lisas_weight = SRT / SPE;
end

% inverse efficiency score (IES) (Townsend & Ashby, 1978)
IES = MRT / (1 - PE);
% FIX ME! rate of correct score (RCS) (Woltz&Was, 2006)
RCS = nansum(ACC == 1) / nansum(RT / 1000);
% FIX ME! bin score (Hughes, Linck, Bowles, Koeth,&Bunting, 2014)
BS = NaN;
% linear integrated speed-accuracy score (LISAS) (Vandierendonck, 2016)
LISAS = MRT + lisas_weight * PE;

stats = [NTrial, NResp, NInclude, PE, SPE, MRT, SRT, lisas_weight, IES, RCS, BS, LISAS];
labels = {'NTrial', 'NResp', 'NInclude', 'PE', 'SPE', 'MRT', 'SRT', 'lisas_weight', 'IES', 'RCS', 'BS', 'LISAS'};
end
