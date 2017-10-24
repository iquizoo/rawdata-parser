function C = hetervcat(A, B)
% Vertcat heterogeneous tables (with possible different variable names)
%   Note that cell type is not supported.

% check if var names are diff for diff conditions
AVars = A.Properties.VariableNames;
BVars = B.Properties.VariableNames;
% a(ia)/b(ib) will be the missing of the other set
[exVars, iA, iB] = setxor(AVars, BVars, 'stable');
% when A and B are not empty and heterogenous, do something
if ~isempty(AVars) && ~isempty(BVars) && ~isempty(exVars)
    BmissVars = AVars(iA);
    B(:, BmissVars) = ...
        repmat({missing}, height(B), length(BmissVars));
    AmissVars = BVars(iB);
    A(:, AmissVars) = ...
        repmat({missing}, height(A), length(AmissVars));
end
C = vertcat(A, B);
