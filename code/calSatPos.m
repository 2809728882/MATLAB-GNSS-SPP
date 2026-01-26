function [eph] = calSatPos(nav)

% 1 获取GPS广播星历数据
nav = nav{1,1};
gpsNav = nav.GPS; %数据
tgps = gpsNav.Time;% 时间
t_u= unique(tgps);

% 预分配内存
eph.satPos=[];
eph.satVel=[];
eph.satID=[];


% 循环计算每个时间的轨道位置
for i =1:numel(t_u)
    satIdx = ismember(tgps, t_u(i));
    gpsNav2 = gpsNav(satIdx,:);
     % [eph(i).satPos,eph(i).satVel,eph(i).satID] = computeSatellitePosition(t_u(i), gpsNav2);
    [eph(i).satPos,eph(i).satVel,eph(i).satID] = gnssconstellation(t_u(i),gpsNav2);
    eph(i).t = t_u(i);

end


