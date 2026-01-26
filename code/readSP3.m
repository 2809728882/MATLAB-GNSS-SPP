function [pos, vel, satIDs] = readSP3(fp)

%% 1 fgetl 读取每行 找到所有*的行
%% 2 找到所有P字母的行
if nargin < 1
    fp = 'E:\SPP0528xs\SPP0523xs\data\SP3\igs20464.sp3';
end
fpID = fopen(fp);
if fpID == -1
    msg = [fp ' 此文件读取失败，请检查文件名是否正确，或者检查路径是否正确。'];
    msgbox(msg)
    pos = [];
    vel = [];
    satIDs = [];
    return;
end

i = 1; m = 1; k = 1;
xyz = zeros(24*60*60/15,3);
dt = zeros(24*60*60/15,6);
IP = zeros(24*60*60/15,1);
IT = zeros(24*60*60/15,1);
satIDs = cell(24*60*60/15,1);

while 1
    line = fgetl(fpID);
    % 1 设置退出条件
    if  line == -1
        break;
    end
    if startsWith(line,'P')
        % 解析卫星位置数据
        parts = textscan(line(2:end), '%s %f %f %f %f %f %f %f %f %f %f %f %f %f');
        satIDs{m} = parts{1}{1};
        xyz(m,:) = [parts{2:4}];
        IP(m) = i;
        m = m+1;
    end
    if startsWith(line,'*')
        % 解析时间数据
        parts = textscan(line(2:end), '%f %f %f %f %f %f');
        dt(k,:) = cell2mat(parts);
        IT(k) = i;
        k = k+1;
    end
    i = i+1;
end

fclose(fpID);

% 计算速度（使用中心差分）
vel = zeros(size(xyz));
for i = 2:size(xyz,1)-1
    vel(i,:) = (xyz(i+1,:) - xyz(i-1,:)) / (2 * 15); % 假设时间间隔为15秒
end

% 整理输出
pos = xyz(1:m-1,:);
vel = vel(1:m-1,:);
satIDs = satIDs(1:m-1);

end

%% 利用readmatrix readtable readcell 读取指定行的数据

