function out = readOSBrinex2(fp,headinfo)
%{ 
FUNCTION : READ RIENX 2.0 DATA BODY
IFPUT:
    fp : file path name
    headinfo : rinex fiel head information
OUTPUT:
    FOUR SYSTEM TABLE DATA 

%}

% 读取文件
fpID = fopen(fp);
if fpID == -1
    msg = [fp ' 此文件读取失败，请检查文件名是否正确，或者检查路径是否正确。'];
    msgbox(msg)
end

% 初始化数据个数
ig = 1; % 计算GPS数据的个数的初始值
ie = 1;
ir = 1;
ic = 1;

% 初始化输出的表
% GPS
colNames =[{'Time', 'SatNO'}, headinfo.type_G];        % 已知表头
colTypes = [{'datetime', 'double'}, repmat({'double'},1,length(headinfo.type_G))]; % 对应列的数据类型
GPS = table(...
    'Size', [0, numel(colNames)],...
    'VariableTypes', colTypes,...
    'VariableNames', colNames);

% BDS
colNames =[{'Time', 'SatNO'}, headinfo.type_C];        % 已知表头
colTypes = [{'datetime', 'double'}, repmat({'double'},1,length(headinfo.type_C))]; % 对应列的数据类型
BDS = table(...
    'Size', [0, numel(colNames)],...
    'VariableTypes', colTypes,...
    'VariableNames', colNames);

% GLONASS
colNames =[{'Time', 'SatNO'}, headinfo.type_R];        % 已知表头
colTypes = [{'datetime', 'double'}, repmat({'double'},1,length(headinfo.type_R))]; % 对应列的数据类型
GLONASS = table(...
    'Size', [0, numel(colNames)],...
    'VariableTypes', colTypes,...
    'VariableNames', colNames);

% Galileo
colNames =[{'Time', 'SatNO'}, headinfo.type_E];        % 已知表头
colTypes = [{'datetime', 'double'}, repmat({'double'},1,length(headinfo.type_E))]; % 对应列的数据类型
Galileo = table(...
    'Size', [0, numel(colNames)],...
    'VariableTypes', colTypes,...
    'VariableNames', colNames);

%% readbodydata
while 1

    line = fgetl(fpID);

    % 1 设置退出条件
    if  line == -1
        break;
    end

    % 2 发现了> 就读取时间
    if contains(line,'>')
        % 按空格分割字符串
        parts = strsplit(line);

        % 提取年月日时分秒
        year = str2double(parts{2});
        month = str2double(parts{3});
        day = str2double(parts{4});
        hour = str2double(parts{5});
        minute = str2double(parts{6});
        seconds = str2double(parts{7});

        % 提取最后一个数字（观测值个数）
        obs_count = str2double(parts{end-1});

        % 创建datetime对象
        dt = datetime(year, month, day, hour, minute, seconds);

        for i = 1:obs_count
            line = fgetl(fpID);
            satSys = line(1);
            satNO = str2double(line(2:3));

            switch satSys
                case 'G'

                    num_G = headinfo.num_G;
                    line2 = line(4:end);
                    rowWidth = 16 ; %rinex 3.0 的宽度是16,最后两位是标识符号
                    rowdata = readlinedatas(line2,num_G ,rowWidth);
                    GPS( ig,:) = [{dt},{ satNO},  num2cell(rowdata)];
                    ig = ig +1;
                    clear rowdata;

                case 'E'
                    num_E = headinfo.num_E;
                    line2 = line(4:end);
                    rowWidth = 16 ; %rinex 3.0 的宽度是16,最后两位是标识符号
                    rowdata = readlinedatas(line2,num_E ,rowWidth);
                    Galileo( ie,:) = [{dt},{ satNO},  num2cell(rowdata)];
                    ie = ie +1;
                    clear rowdata;

                case 'C'
                    num_C = headinfo.num_C;
                    line2 = line(4:end);
                    rowWidth = 16 ; %rinex 3.0 的宽度是16,最后两位是标识符号
                    rowdata = readlinedatas(line2,num_C ,rowWidth);
                    BDS( ic,:) = [{dt},{satNO},  num2cell(rowdata)];

                    ic = ic +1;
                    clear rowdata;

                case 'R'
                    num_R = headinfo.num_R;
                    line2 = line(4:end);
                    rowWidth = 16 ; %rinex 3.0 的宽度是16,最后两位是标识符号
                    rowdata = readlinedatas(line2,num_R ,rowWidth);
                    GLONASS( ig,:) = [{dt},{ satNO},  num2cell(rowdata)];
                    ir = ir +1;
                    clear rowdata;

            end% switch satSys
        end % i = 1:obs_count
    end % if  contains(line,'>')



end % while 1


out.GPS = GPS;
out.BDS = BDS;
out.GLONASS = GLONASS;
out.Galileo = Galileo;

%% SUBFUNCTION ----------------------------------------------------
function rowData = readlinedatas(line,numsat,rowWidth)
% 读取行文件中的数据
rowData = nan(1, numsat);  % 初始化16列NaN
for j = 1:numsat
    startPos = (j-1)*rowWidth + 1;  % 每列16字符,最后2个字符是LL1和信号强度，有的有有的没有
    endPos = j*rowWidth;
    if length(line) >= startPos
        substr = line(startPos:min(endPos, length(line)));
        substr = substr(1:rowWidth-2);
        substr =  strtrim (substr);
        if ~isempty(substr)
            rowData(j) = str2double(substr);
        end
    end
end

