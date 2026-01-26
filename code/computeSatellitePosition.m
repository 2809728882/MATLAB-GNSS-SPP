function [X, Y, Z, SatelliteID] = computeSatellitePosition(obstime, GPS_Table)
%{
% GPS_Table = readtable('GPS.xlsx');

% 输入GPS时间（示例值：t = te + 3600）
t = GPS_Table.te(1) + 3600; 

% 计算卫星位置
[X, Y, Z] = computeSatellitePosition(t, GPS_Table);
fprintf('卫星坐标：X=%.3f m, Y=%.3f m, Z=%.3f m\n', X, Y, Z);
%}

% 输入参数：
%   t：GPS时间（秒）
%   GPS_Table：读取的星历表格数据（包含标题行）
% 输出参数：
%   X, Y, Z：卫星在ECEF坐标系中的坐标（米）

% [week, sow] = datetime2gpst(t);
% t = sow;
SatelliteID = GPS_Table.SatelliteID;
% 定义常量
miu = 3.986005e14;       % 地心引力常数（m³/s²）
we = 7.2921151467e-5;   % 地球自转角速度（rad/s）

% 从表格中提取星历参数（假设列名与广播星历参数一致）
sqrtA = GPS_Table.sqrtA;       % 轨道半长轴平方根
e = GPS_Table.Eccentricity;               % 偏心率 %%-------
M0 = GPS_Table.M0;             % 参考时刻的平近点角（rad）
i0 = GPS_Table.i0;             % 初始轨道倾角（rad）
Omega0 = GPS_Table.OMEGA0;     % 升交点赤经（rad）
w = GPS_Table.omega;               % 近地点角距（rad）%%-------
delta_n = GPS_Table.Delta_n;   % 平运动差（rad/s）
te = GPS_Table.Toe;             % 星历参考时刻（s）
Cuc = GPS_Table.Cuc;           % 升交点角距余弦修正项
Cus = GPS_Table.Cus;           % 升交点角距正弦修正项
Crc = GPS_Table.Crc;           % 轨道半径余弦修正项
Crs = GPS_Table.Crs;           % 轨道半径正弦修正项

% 计算归化时间差

[gps_obsweek, gps_obssec] = ctime2gps(obstime);
reftime = obstime;
[gps_refweek, gps_refseconds] = ctime2gps(reftime);

delta_t = a3(1)+a3(2).*(gps_obssec-gps_refseconds)+a3(3).*(gps_obssec-gps_refseconds).^2;
t = gps_refseconds - delta_t;
tk = t - te;

% 计算轨道半长轴a和平均角速度n
a = sqrtA.^2;                   % 长半轴（m）
n0 = sqrt(miu ./ a.^3);          % 理论平均角速度（rad/s）
n = n0 + delta_n;              % 校正后的平均角速度


% 迭代计算偏近点角E

Mk = M0 + n .* tk;
Ek = Mk;
Ek_old = Ek;
tol = 1e-10;                     % 初始迭代值
for iter = 1:100
    Ek = Mk + e * sin(Ek);
    if abs(Ek - Ek_old) < tol
        break;
    end
    Ek_old = Ek;
end


% 计算轨道参数(向量化)
vk = atan2(sqrt(1 - e.^2) .* sin(Ek), cos(Ek) - e); % butong
phi = vk + w;

delta_uk = Cuc .* cos(2*phi) + Cus .* sin(2*phi);
delta_rk = Crc .* cos(2*phi) + Crs .* sin(2*phi);
delta_ik = zeros(numSats,1);  % 假设倾角无摄动

uk = phi + delta_uk;
rk = a .* (1 - e .* cos(Ek)) + delta_rk;
ik = i0 + delta_ik;

% 计算ECEF坐标(向量化)
Omegak = Omega0 - we .* tk;
x_orb = rk .* cos(uk);
y_orb = rk .* sin(uk);

X = x_orb .* cos(Omegak) - y_orb .* cos(ik) .* sin(Omegak);
Y = x_orb .* sin(Omegak) + y_orb .* cos(ik) .* cos(Omegak);
Z = y_orb .* sin(ik);
end


function [gps_week, sow] = datetime2gpst(dt)
% DATETIME2GPST 将MATLAB datetime转换为GPS时间
% 输入参数:
%   dt - MATLAB datetime对象
% 输出参数:
%   gps_week - GPS周数
%   sow - 周内秒(秒)
%
% 示例:
%   dt = datetime('2025-05-16 12:00:00');
%   [week, sow] = datetime2gpst(dt);

% GPS时间起点(1980-01-06 00:00:00 UTC)
gps_start = datetime(1980,1,6,0,0,0);

% 确保输入是datetime对象
if ~isdatetime(dt)
    error('输入必须是datetime对象');
end

% 计算时间差(考虑时区)
% dt.TimeZone = 'UTC'; % 确保使用UTC时间
delta = dt - gps_start;
delta_seconds = seconds(delta);

% 计算GPS周和周内秒
gps_week = floor(delta_seconds/(7*86400));
sow = mod(delta_seconds, 7*86400);
end


function [gps_week, gps_seconds] = ctime2gps(target_time )
% 将日期时间转换为GPS周数和秒数
% 输入参数：时间向量 [年, 月, 日, 时, 分, 秒]
% 输出参数：GPS周数，GPS秒数

gps_epoch = datetime(1980,1,6,0,0,0);
% target_time = datetime(time_vec(1), time_vec(2), time_vec(3), ...
%                       time_vec(4), time_vec(5), time_vec(6));

duration = target_time - gps_epoch;
total_seconds = seconds(duration);

gps_week = floor(total_seconds / (604800));
gps_seconds = mod(total_seconds, 604800);
end



