function res = sngstatsNSN(RECORD, outvars, stimmap)
%SNGSTATSNSN Does some basic data transformation to all noise/signal-noise tasks.
%
%   Basically, the supported tasks are as follows:
%     Symbol
%     Orthograph
%     Tone
%     Pinyin
%     Lexic
%     Semantic
%     DRT
%     CPT1
%     GNGLure
%     GNGFruit
%   The output table contains 8 variables, called Rate_Overall, RT_Overall,
%   Rate_hit, Rate_FA, RT_hit, RT_FA, dprime, c.

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

res = table;
%Use this variable to detect abnormal data.
exception = false;
if ~istable(splitRes{:}) || isempty(splitRes{:})
    exception = true;
else
    RECORD = splitRes{:}.RECORD{:};
    %Modify SCat.
    if ~isempty(stimmap)
        if ~iscell(RECORD.STIM)
            RECORD.STIM = num2cell(RECORD.STIM);
        end
        if all(isKey(stimmap, RECORD.STIM))
            RECORD.SCat = cell2mat(values(stimmap, RECORD.STIM));
        else %In this case, some of stimuli are not right, and delete all the instances.
            RECORD(:, :) = [];
        end
    else
        %Find out the no-go stimulus.
        if ~iscell(RECORD.STIM)
            RECORD.STIM = num2cell(RECORD.STIM);
        end
        allSTIM = unique(RECORD.STIM(~isnan(RECORD.ACC)));
        firstTrial = RECORD(1, :);
        firstIsGo = firstTrial.ACC == 1 && firstTrial.RT < 3000;
        firstTrialInfo = strcmp(allSTIM, firstTrial.STIM);
        %Here is an interesting way to find out no-go stimulus.
        NGSTIM = allSTIM(xor(firstTrialInfo, firstIsGo));
        RECORD.SCat = ~ismember(RECORD.STIM, NGSTIM);
    end
    %Remove NaN trials.
    RECORD(isnan(RECORD.RT), :) = [];
    %Before removing RTs, record the time used if required.
    if ismember('TotalTime', outvars)
        res.TotalTime = sum(RECORD.RT);
    end
    %Cutoff RTs: for too fast trials and too slow trials. Do not remove
    %trials without response, because some trials of GNG task is designed
    %to suppress a response for subjects.
    RECORD((RECORD.RT < 100 & RECORD.RT ~= 0) | RECORD.RT > 2500, :) = [];
    if isempty(RECORD)
        exception = true;
    else
        %record the number of correct trials if required.
        if ismember('NAccTrl', outvars)
            res.NAccTrl = sum(RECORD.ACC);
        end
        %ACCuracy and MRT.
        res.Rate_Overall = mean(RECORD.ACC); %Rate is used in consideration of consistency.
        res.RT_Overall = mean(RECORD.RT(RECORD.ACC == 1));
        %Ratio of hit and false alarm.
        res.Rate_hit = mean(RECORD.ACC(RECORD.SCat == 1));
        res.Rate_FA = mean(~RECORD.ACC(RECORD.SCat == 0));
        %Mean RT computation.
        res.RT_hit = mean(RECORD.RT(RECORD.SCat == 1 & RECORD.ACC == 1));
        res.RT_FA = mean(RECORD.RT(RECORD.SCat == 0 & RECORD.ACC == 0));
        %d' and c.
        [res.dprime, res.c] = sngdetect(res.Rate_hit, res.Rate_FA);
    end
end
if exception
    for ivar = 1:length(outvars)
        res.(outvars{ivar}) = nan;
    end
end
