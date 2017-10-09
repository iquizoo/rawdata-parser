function clean = rmoutlier(raw, varargin)
% 
% Default: a 2-step protocol

par = inputParser;
% all the implemented methods in order
addParameter(par, 'Method', {'cutoff', 'iqr'}, @(x) ischar(x) | iscellstr(x) | isstring(x));
addParameter(par, 'Boundary', [100, inf], @(x) validateattributes(x, {'numeric'}, {'numel', 2}));
addParameter(par, 'SDLimit', 2, @isnumeric);
addParameter(par, 'Number', 2, @isnumeric);
addParameter(par, 'Coefficient', 1.5, @isnumeric);
parse(par, varargin{:});
methods = lower(cellstr(par.Results.Method));
cutoffs = par.Results.Boundary;
sdlimits = par.Results.SDLimit;
percent = par.Results.Number;
coef = par.Results.Coefficient;

% step by step to detect outliers according to method
for method = methods
    % compose input arguments
    paras = [{'Method'}, method, ...
        {'Boundary', cutoffs, 'SDLimit', sdlimits, ...
        'Number', percent, 'Coefficient', coef}];
    raw(outlier(raw, paras{:})) = NaN;
end

clean = raw;
end