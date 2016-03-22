%This script is used to compose a table which has following variables:
%   1. QID: short for QUESTION IDENTIFIER, for each task, encode it into an
%   ID.
%   2. presplit(perhaps obsolete): 'yes' denotes that the records of the
%   question needs splitting before further analysis.
%   3. delimiter: a delimiter to separate information in a block of record. 
%   E.g., in '1:8:9:1:2:1:2:1:716,1:9:8:1:1:2:1:1:1000,...', 
%   '1:9:8:1:1:2:1:1:1000' is a block, and ':' is a delimiter.
%   4. subdelimiter: sometimes, there are two types of delimiters in a
%   block. E.g., in '1:10|9|3|4:12:-1:0:2000,1:6|18|8|17:6:-1:0:2000,...',
%   '|' is the subdelimiter.
%   5. colnum: the number of information pieces in one block of record.
%   6. charcol: mostly, the information pieces in one block are suitable to
%   convert to numbers, but, sometimes, they need to be kept as strings.
%   Charcol denotes columns that are suitable to be kept as strings.
%   7. collabel: in converting the results into a table, we need variable
%   names, which are kept in the variabel collabel.

%By Zhang, Liang. E-mail:psychelzh@gmail.com

N = 19; %Number of questions.
QID      = (1:N)';
presplit = { ...
    'no'; %1
    'no'; %2
    'no'; %3
    'no'; %4
    'no'; %5
    'no'; %6
    'no'; %7
    'no'; %8
    'no'; %9
    'no'; %10
    'no'; %11
    'no'; %12
    'no'; %13
    'no'; %14
    'no'; %15
    'no'; %16
    'no'; %17
    'no'; %18
    'no'; %19
    };
delimiter = [ ...
    ':'; %1
    ':'; %2
    ','; %3
    ':'; %4
    ':'; %5
    ':'; %6
    ':'; %7
    ','; %8
    ':'; %9
    ':'; %10
    ':'; %11
    ':'; %12
    ':'; %13
    ':'; %14
    ':'; %15
    ':'; %16
    ':'; %17
    ':'; %18
    ':'; %19
    ];
subdelimiters = [ ...
    ' '; %1
    '|'; %2
    ' '; %3
    ' '; %4
    ' '; %5
    ' '; %6
    ' '; %7
    ' '; %8
    ' '; %9
    ' '; %10
    ' '; %11
    ' '; %12
    ' '; %13
    ' '; %14
    ' '; %15
    ' '; %16
    ' '; %17
    ' '; %18
    ' '; %19
    ];
colnum = [...
	4; %1
	6; %2
	3; %3
	4; %4
	3; %5
	3; %6
	4; %7
	4; %8
	4; %9
	5; %10
	5; %11
	9; %12
	5; %13
	4; %14
	6; %15
    7; %16
    6; %17
    5; %18
    4; %19
	];
charcol = {...
    0; %1
    [2,3]; %2
    0; %3
    0; %4
    0; %5
    0; %6
    0; %7
    1; %8
    0; %9
    [4,5]; %10
    0; %11
    0; %12
    [4,5]; %13
    [3,4]; %14
    0; %15
    2; %16
    0; %17
    0; %18
    0; %19
    };
collabel = { ...
    {'TASK_CAT','STIM_CAT','ACC','RT'}; %1
    {'REP','FOOD','FACES','RESP','ACC','RT'}; %2
    {'STIM_CAT','RT','ACC'}; %3
    {'STIM','CRESP','ACC','RT'}; %4
    {'RESP','RT','ACC'}; %5
    {'CTIME','RT','ACC'}; %6
    {'STIM_CAT','ACC','RT','RESP'}; %7
    {'STIM_CAT','RT','ACC','RESP'}; %8
    {'RT','ACC','STIM_CAT','RESP'}; %9
    {'Stimuli_Length','ACC','Next_Cond','Stimuli_Series','Resp_Series'}; %10
    {'Stimuli_Number','Stimuli_Color','RESP','ACC','RT'}; %11
    {'RUN','Num_x','Num_y','CRESP','Left_Number','Right_Number','RESP','ACC','RT'}; %12
    {'Stimuli_Length','ACC','Next_Cond','Stimuli_Series','Resp_Series'}; %13
    {'TIME','ACC','Stimuli_Series','Resp_Series'}; %14
    {'STIM_NUM','STIM_COLOR','STIM_INT','RESP','ACC','RT'}; %15
    {'REP', 'STIM', 'STIM_CAT', 'CRESP', 'RESP', 'ACC', 'RT'}; %16
    {'REP', 'STIM', 'CRESP', 'RESP', 'ACC', 'RT'}; %17
    {'REP', 'STIM', 'RESP', 'ACC', 'RT'}; %18
    {'STIM_CAT', 'CRESP', 'ACC', 'RT'}; %19
    };
% initialVars = who;
para = table(QID, presplit, delimiter, subdelimiters, colnum, charcol, collabel);
% clear(initialVars{:}, 'initialVars');
