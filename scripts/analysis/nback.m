function res = nback(splitRes)
%SRT Does some basic data transformation to simple reactiontime tasks.
%
%   Basically, the supported tasks are as follows:
%     Êý×ÖÄ§·¨Ê¦, task id: 41-42
%     
%   The output table contains 2 variables, called ACC, RT.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

outvars = {...
    'ACC', 'RT'};
if ~istable(splitRes{:})
    res = array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars);
    return
end
RECORD = splitRes{:}.RECORD{:};
%Remove trials that no response is needed.
RECORD(RECORD.CResp == -1, :) = [];
%Cutoff RTs: for too fast trials.
RECORD(RECORD.RT < 100, :) = [];

ACC = mean(RECORD.ACC);
RT = mean(RECORD.RT);
res = table(ACC, RT);
