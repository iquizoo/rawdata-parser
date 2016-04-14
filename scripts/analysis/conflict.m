function res = conflict(Taskname, splitRes)
%FLANKER Does some basic data transformation to conflict-based tasks.
%
%   Basically, the supported tasks are as follows:
%     方向达人, task id: 37
%     颜色达人, task id:38-39
%   The output table contains 8 variables, called RT, ACC, RT_Cong,
%   ACC_Cong, RT_Incong, ACC_Incong, RT_CongEffect, ACC_CongEffect.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

outvars = {...
    'RT', 'ACC', ...
    'RT_Cong', 'ACC_Cong', 'RT_Incong', 'ACC_Incong', ...
    'RT_CongEffect', 'ACC_CongEffect'};
if ~istable(splitRes{:})
    res = array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars);
    return
end
RECORD = splitRes{:}.RECORD{:};
%Cutoff RTs: eliminate trials that are too fast (<100ms)
RECORD(RECORD.RT < 100, :) = [];
%Get all the conditions' coding.
switch Taskname{:}
    case '方向达人'
        congCode = [1, 3];
        incongCode = [2, 4];
    case {...
            '颜色达人初级',...
            '颜色达人中级',...
            }
        congCode = 1;
        incongCode = 0;
end        
%Condition-wise analysis.
%Congruent condition.
RT_Cong = mean(RECORD.RT(ismember(RECORD.SCat, congCode) & RECORD.ACC == 1));
ACC_Cong = mean(RECORD.ACC(ismember(RECORD.SCat, congCode)));
%Incongruent condition.
RT_Incong = mean(RECORD.RT(ismember(RECORD.SCat, incongCode)));
ACC_Incong = mean(RECORD.ACC(ismember(RECORD.SCat, incongCode)));
%Overall RT and ACC.
RT = mean(RECORD.RT(RECORD.ACC == 1));
ACC = mean(RECORD.ACC);
RT_CongEffect = RT_Incong - RT_Cong;
ACC_CongEffect = ACC_Cong - ACC_Incong;
res = table(RT, ACC, RT_Cong, ACC_Cong, RT_Incong, ACC_Incong, RT_CongEffect, ACC_CongEffect);
