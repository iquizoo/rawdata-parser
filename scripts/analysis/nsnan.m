function res = nsnan(TaskIDName, splitRes)
%NSNAN Does some basic data transformation to all noise/signal-noise tasks.
%
%   Basically, the supported tasks are as follows:
%     1. Symbol
%     2. Orthograph
%     3. Tone
%     4. Pinyin
%     5. Lexic
%     6. Semantic
%   The output table contains 8 variables, called Count_hit, Count_FA,
%   Count_miss, Count_CR, RT_hit, RT_FA, RT_miss, RT_CR

%By Zhang, Liang. 04/13/2016. E-mail:psychelzh@gmail.com

%chkVar is used to check outliers.
chkVar = {};
%coupleVars are formatted out variables.
varPref = {'Rate', 'RT'};
varSuff = {'Overall', 'hit', 'FA'};
delimiter = '_';
coupleVars = strcat(repmat(varPref, 1, length(varSuff)), delimiter, repelem(varSuff, 1, length(varPref)));
%further required variables.
singletonVars = {'dprime', 'c'};
%Out variables names are composed by three part.
outvars = [chkVar, coupleVars, singletonVars];
if ~istable(splitRes{:}) || isempty(splitRes{:})
    res = {array2table(nan(1, length(outvars)), ...
        'VariableNames', outvars)};
    return
end
RECORD = splitRes{:}.RECORD{:};
%Cutoff RTs: for too fast trials.
RECORD(RECORD.RT < 100 & RECORD.RT > 0, :) = [];
%Remove NaN trials.
RECORD(isnan(RECORD.ACC), :) = [];
%Modify SCat.
langTask = {'Symbol', 'Orthograph', 'Tone', 'Pinyin', 'Lexic', 'Semantic'};
GNGTask = {'DRT', 'GNGLure', 'GNGFruit'};
switch TaskIDName{:}
    case langTask
        switch TaskIDName{:}
            case 'Symbol'
                CResp = cell2table(...
                    [repmat({'⊙', 0; '〒', 0; '♀', 0; '※', 0; '¤', 0}, 5, 1); ...
                    repmat({'§', 1}, 25, 1)], ...
                    'VariableNames', {'STIM', 'SCat'});
            case 'Orthograph'
                %When STIM <= 25, SCat -> 1.
                CResp = cell2table(...
                    [cellfun(@num2str, num2cell((1:50)'), 'UniformOutput', false), ...
                    num2cell([ones(25, 1); zeros(25, 1)])], ...
                    'VariableNames', {'STIM', 'SCat'});
            case 'Tone'
                CResp = cell2table(...
                    {'各',1;'力',1;'四',1;'爱',1;'众',1;'次',1;'泪',1;'办',1;'块',1;...
                    '互',1;'过',1;'代',1;'去',1;'认',1;'弄',1;'入',1;'动',1;'燕',1;'妙',1;...
                    '校',1;'立',1;'变',1;'放',1;'再',1;'到',1;'多',0;'家',0;'巴',0;'他',0;...
                    '光',0;'春',0;'吃',0;'语',0;'灰',0;'反',0;'迷',0;'活',0;'习',0;'牙',0;...
                    '洋',0;'打',0;'平',0;'门',0;'节',0;'祖',0;'杆',0;'早',0;'总',0;'品',0;'百',0;}, ...
                    'VariableNames', {'STIM', 'SCat'});
            case 'Pinyin'
                CResp = cell2table(...
                    {'āuh',0;'méin',0;'bàg',0;'lù',1;'rànɡ',1;'dluī',0;'xìnɡ',1;...
                    'cónɡ',1;'huà',1;'hsū',0;'ɡuānɡ',1;'wāin',0;'yè',1;'bǐg',0;'hóu',1;...
                    'uǎn',0;'biǐ',0;'xìnɡ',1;'zhēn',1;'jāin',0;'tiān',1;'qiū',1;'liǎm',0;...
                    'máio',0;'jiān',1;'siān',0;'māo',1;'fiàn',0;'niág',0;'jīnq',0;'wài',1;...
                    'xǔng',0;'tián',1;'nàl',0;'xiiē',0;'wū',1;'shēnɡ',1;'pāi',1;'boì',0;...
                    'dòu',1;'dòn',0;'poǎ',0;'iàn',0;'chī',1;'biān',1;'lám',0;'zhèɡ',0;...
                    'yǔ',1;'xuě',1;'shǎo',1}, ...
                    'VariableNames', {'STIM', 'SCat'});
            case 'Lexic'
                CResp = cell2table(...
                    {'草地',1;'跳高',1;'菜园',1;'这些',1;'走过',1;'跑步',1;'出来',1;...
                    '远近',1;'晚上',1;'绿色',1;'电视',1;'作业',1;'田野',1;'读书',1;'身体',1;...
                    '漂亮',1;'同学',1;'长城',1;'豆角',1;'外面',1;'回答',1;'现在',1;'景色',1;...
                    '妈妈',1;'竹子',1;'何花',0;'里想',0;'平论',0;'马蚁',0;'心闻',0;'站士',0;...
                    '拉圾',0;'石快',0;'亭止',0;'纺问',0;'安净',0;'诚功',0;'风争',0;'蓝子',0;...
                    '交傲',0;'树跟',0;'罗卜',0;'足求',0;'事晴',0;'西呱',0;'你门',0;'可昔',0;...
                    '海阳',0;'旦是',0;'店脑',0;}, ...
                    'VariableNames', {'STIM', 'SCat'});
            case 'Semantic'
                CResp = cell2table(...
                    {'公鸡',1;'燕子',1;'青蛙',1;'水牛',1;'老鼠',1;'山羊',1;'黑狗',1;...
                    '熊猫',1;'黄牛',1;'松鼠',1;'野鸭',1;'老虎',1;'兔子',1;'大象',1;'猴子',1;...
                    '狮子',1;'乌龟',1;'乌鸦',1;'蝌蚪',1;'黑熊',1;'孔雀',1;'大雁',1;'海鸥',1;...
                    '蜘蛛',1;'壁虎',1;'房屋',0;'花朵',0;'白云',0;'马车',0;'飞机',0;'高山',0;...
                    '故乡',0;'茶几',0;'明月',0;'尘土',0;'竹排',0;'鸟岛',0;'皮球',0;'商场',0;...
                    '土地',0;'跑步',0;'早晨',0;'胡子',0;'木鱼',0;'毛巾',0;'贺卡',0;'雨伞',0;...
                    '沙发',0;'尾巴',0;'雪人',0;}, ...
                    'VariableNames', {'STIM', 'SCat'});
        end
        [~, locSTIM] = ismember(RECORD.STIM, CResp.STIM);
        if any(locSTIM == 0)
            warning('Certain stimluli not defined in correct answer table. Quiting.\n');
            res = {array2table(nan(1, 8), ...
                'VariableNames', outvars)};
            return
        end
        %SCat: 1. Denote to respond with 'yes', 2. Denote to repond with 'no'.
        RECORD.SCat = CResp.SCat(locSTIM);
    case GNGTask
        switch TaskIDName{:}
            case 'DRT'
                %Find out the no-go stimulus.
                if ~iscell(RECORD.STIM)
                    RECORD.STIM = num2cell(RECORD.STIM);
                end
                allSTIM = unique(RECORD.STIM(~isnan(RECORD.ACC)));
                firstTrial = RECORD(1, :);
                firstIsGo = firstTrial.ACC == 1 && firstTrial.RT < 3000;
                if firstIsGo
                    NGSTIM = allSTIM(~ismember(allSTIM, firstTrial.STIM));
                else
                    NGSTIM = firstTrial.STIM;
                end
            case {'GNGLure', 'GNGFruit'}
                switch TaskIDName{:}
                    case 'GNGLure'
                        %0-3, 10-11 -> NoGo
                        NGSTIM = [0:3, 10:11];
                    case 'GNGFruit'
                        %0 -> NoGo
                        NGSTIM = 0;
                end
                %ACC variable is not correctly recorded, rectify it here.
                %If the RT is 2000(for GNGLure) or 0 (for GNGFruit), we
                %interpret it as no response.
                RECORD.ACC(ismember(RECORD.STIM, NGSTIM)) = ...
                    RECORD.RT(ismember(RECORD.STIM, NGSTIM)) == 2000 | ...
                    RECORD.RT(ismember(RECORD.STIM, NGSTIM)) == 0;
        end
        %SCat: 1. Denote 'go' trial, 2. Denote 'no-go' trial.
        RECORD.SCat = ~ismember(RECORD.STIM, NGSTIM);
end
%ACCuracy and MRT.
Rate_Overall = mean(RECORD.ACC); %Rate is used in consideration of consistency.
RT_Overall = mean(RECORD.RT(RECORD.ACC == 1));
%Ratio of hit and false alarm.
Rate_hit = mean(RECORD.ACC(RECORD.SCat == 1));
Rate_FA = mean(~RECORD.ACC(RECORD.SCat == 0));
%Mean RT computation.
RT_hit = nanmean(RECORD.RT(RECORD.SCat == 1 & RECORD.ACC == 1));
RT_FA = nanmean(RECORD.RT(RECORD.SCat == 0 & RECORD.ACC == 0));
%d' and c.
[dprime, c] = sngdetect(Rate_hit, Rate_FA);
res = {table(Rate_Overall, RT_Overall, Rate_hit, Rate_FA, RT_hit, RT_FA, dprime, c)};
