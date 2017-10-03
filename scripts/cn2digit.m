function [num, status, msg] = cn2digit(cn)

% transformation is presumed to be successful by default
status = 0;
% digit character mapping
digitCNs = {...
    '©–'; 'Ò»'; '¶þ'; 'Èý'; 'ËÄ'; 'Îå'; 'Áù'; 'Æß'; '°Ë'; '¾Å'; ...
    'Áã'; 'Ò¼'; '·¡'; 'Èþ'; 'ËÁ'; 'Îé'; 'Â½'; 'Æâ'; '°Æ'; '¾Á'; ...
    };
digitArabic = repmat((0:9)', 2, 1);
digitMap = containers.Map(digitCNs, digitArabic);

% unit character mapping
unitCNs = {'Ê®'; '°Ù'; 'Ç§'; 'Ê°'; '°Û'; 'Çª'; 'Íò'; 'ÒÚ';};
unitArabic = [repmat(10 .^ [1, 2, 3]', 2, 1); 10000; 100000000];
unitMap = containers.Map(unitCNs, unitArabic);

% invalid character appears
if ~all(ismember(cn, strjoin([digitCNs; unitCNs])))
    msg = 'The Chinese numeric string has one or more invalid character.';
    status = -1;
    num = NaN;
    return
end

% preallocations and settings
nchar = length(cn);
num = 0;

% last character is digit or not
lastIsDigit = false;
% last character is unit or not
lastIsUnit = false;

% last digit character is zero or not
lastIsZeroDigit = false;
% the last unit character is a modifier unit or not
lastIsModUnit = false;

% current modifier unit, will be multiplied by the current unit
curModUnit = 1;
% current unit
curUnit = 1;

% denote whether the Chinese string is correctly written or not
writtenErr = false;

% reverse Chinese charater string to make the tranform easier
cnRev = cn(nchar:-1:1);

% begin transforming
for ichar = 1:nchar
    curChar = cnRev(ichar);

    % unit character
    if ismember(curChar, unitCNs)
        % one of two contiguous unit characters must be a modifer
        if lastIsUnit && ~lastIsModUnit
            writtenErr = true;
            msg = 'One of two contiguous unit characters must be a modifer.';
            break
        end
        % update current unit info
        lastUnit = curUnit;
        curUnit = unitMap(curChar);

        % when modifier unit appears
        if curUnit == 10000 || curUnit == 100000000
            % update modifier unit
            lastModUnit = curModUnit;
            curModUnit = curUnit;
            lastIsModUnit = true;
            curUnit = 1;
            % modifier unit cannot be the first (ichar == nchar) character;
            if ichar == nchar
                writtenErr = true;
                msg = 'Modifier unit cannot be the first character.';
            end
            % when the modifier unit is not the last (ichar == 1)
            % character, there would be a unit check (see below)
            if ichar ~= 1 && ~lastIsZeroDigit && ...
                    (curUnit * curModUnit) / (lastUnit * lastModUnit) ~= 10
                writtenErr = true;
                msg = 'Two contiguous units are not 10 times difference.';
                break
            end
        else
            % UNIT CHECK: when two contiguous units are not differed by ten
            % times, and last unit is not a modifier unit, one digit
            % character denoting 0 should be placed
            if ~lastIsZeroDigit && ~lastIsModUnit && curUnit / lastUnit ~= 10
                writtenErr = true;
                msg = 'Two contiguous units are not 10 times difference.';
                break
            end
            lastIsModUnit = false;
        end
        % a leading unit encountered, add its value immediately
        if ichar == nchar
            num = num + curUnit * curModUnit;
        end
        % update last character info
        lastIsDigit = false;
        lastIsUnit = true;
    else % digit character
        % update current unit info
        curDigit = digitMap(curChar);
        % digit character denotes 0 appears
        if curDigit == 0
            lastIsZeroDigit = true;
            % zero cannot appears before a unit character
            if lastIsUnit
                writtenErr = true;
                msg = 'Zero cannot appears before a unit character.';
                break
            end
            if ichar == 1
                writtenErr = true;
                msg = 'Zero cnnot appears at the last.';
            end
        else
            lastIsZeroDigit = false;
            % if two digit characters are next to each, one must denote 0
            if lastIsDigit
                writtenErr = true;
                msg = 'Two non-zero digit characters cannot be contiguous.';
                break
            end
        end
        % update num value
        num = num + curDigit * curUnit * curModUnit;
        % update last character info
        lastIsDigit = true;
        lastIsUnit = false;
    end
end

% throw an exception when not correctly written
if writtenErr
    status = -2;
    num = NaN;
end
