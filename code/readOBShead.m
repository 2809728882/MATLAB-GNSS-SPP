function headinfo = readOBShead(filepathName)
% 本函数读取观测值数据的头文件部分内容

% filepath = 'C:\Users\Administrator\Desktop\SPP\data\obs';
% filename = 'cpt0870.19o';
% filepathName = [filepath '\' filename];

fpID = fopen(filepathName);
if fpID == -1
    msg = [filename ' 此文件读取失败，请检查文件名是否正确，或者检查路径是否正确。'];
    msgbox(msg)
end
%%
% 初始化需要存储的数据
ver = NaN;
stationAPPR = [NaN,NaN,NaN];
firstObsTime = [NaN,NaN,NaN,NaN,NaN,NaN];
lastObsTime = [NaN,NaN,NaN,NaN,NaN,NaN];
num_lines = 1;
num_G = NaN;
num_R = NaN;
num_E = NaN;
num_C = NaN;
type_G = {NaN};
type_R = {NaN};
type_E = {NaN};
type_C = {NaN};


while 1
    line = fgetl(fpID);
    % 1 读取rinex 版本
    if contains(line,'RINEX VERSION')
        ver = floor(str2double(line(1:12)));

    end

    % 2 读取测站初始坐标
    if contains(line,'APPROX POSITION')
        stationAPPR = sscanf(strtrim(line(1:50)),'%f');
    end

    % 3 读取第一个观测值的时间
    if contains(line,'TIME OF FIRST OBS')
        firstObsTime = sscanf(strtrim(line(1:40)),'%f')';
    end

    % 4 读取最后一个观测值时间
    if contains(line,'TIME OF LAST OBS')
        lastObsTime = sscanf(strtrim(line(1:40)),'%f')';
    end


    % 6 读取观测值的个数以及Type
    if contains(line,'SYS / # / OBS TYPES')

        switch line(1)
            case 'G'
                num_G  = str2double(line(4:6));
                type_G = regexp(strtrim(line(7:59)), '\S+', 'match');
                while numel(type_G)<num_G
                    line = fgetl(fpID);
                    type_temp = regexp(strtrim(line(7:59)), '\S+', 'match');
                    type_G = [type_G,type_temp];
                end

            case 'R'
                num_R  = str2double(line(4:6));
                type_R = regexp(strtrim(line(7:59)), '\S+', 'match');
                while numel(type_R)<num_R
                    line = fgetl(fpID);
                    type_temp = regexp(strtrim(line(7:59)), '\S+', 'match');
                    type_R = [type_R,type_temp];
                end

            case 'C'
                num_C  = str2double(line(4:6));
                type_C = regexp(strtrim(line(7:59)), '\S+', 'match');
                while numel(type_C)<num_C
                    line = fgetl(fpID);
                    type_temp = regexp(strtrim(line(7:59)), '\S+', 'match');
                    type_C = [type_C,type_temp];
                end

            case 'E'
                num_E  = str2double(line(4:6));
                type_E = regexp(strtrim(line(7:59)), '\S+', 'match');
                while numel(type_E)<num_E
                    line = fgetl(fpID);
                    type_temp = regexp(strtrim(line(7:59)), '\S+', 'match');
                    type_E = [type_E,type_temp];
                end

        end
    end

    % 7 顾及rinex2.11 版本 TYPES OF OBSERV
    if contains(line,'TYPES OF OBSERV')
        num_G  = str2double(line(4:6));
        type_G = regexp(strtrim(line(7:59)), '\S+', 'match');
       
        num_R = num_G;
        num_E = num_G;
        num_C = num_G;
        
        type_R = type_G;
        type_E = type_G;
        type_C = type_G;

    end


    % 判断是否位于文件尾部
    if contains(line,'END OF HEADER')
        break
    end

    % 5 判断它头文件一共有多少行
    num_lines = num_lines+1;
end

fclose(fpID);

headinfo.ver = ver;
headinfo.stationAPPR =stationAPPR;
headinfo.firstObsTime = firstObsTime;
headinfo.lastObsTime =lastObsTime;
headinfo.num_lines =num_lines;
headinfo.num_G = num_G;
headinfo.num_R = num_R;
headinfo.num_E = num_E;
headinfo.num_C = num_C;
headinfo.type_C = type_C;
headinfo.type_G = type_G;
headinfo.type_R = type_R;
headinfo.type_E = type_E;



