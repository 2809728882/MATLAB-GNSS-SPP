function recPos = calRecPos(obs,eph)

% 1 导航文件中卫星的时间，以及该时间对应的卫星编号
navt = cell2table({eph(:).t}');
navt = navt.Var1;

% 2 提取接受机的时间，以及对应的卫星编号，提取出接收机的伪距C1C
gpsobs = obs.GPS;
gpsId = gpsobs.SatNO;
gpsC1C = gpsobs.C1C;
gpsIDU = unique(gpsId);
gpst = gpsobs.Time;

% 显示初始数据信息
fprintf('观测数据信息:\n');
fprintf('卫星数量: %d\n', numel(gpsIDU));
fprintf('时间点数量: %d\n', numel(gpst));
fprintf('有效伪距数量: %d\n', sum(~isnan(gpsC1C)));

% 将时间转换为数值（以秒为单位）
if isdatetime(navt)
    navt_num = datenum(navt) * 24 * 3600;  % 转换为秒
else
    navt_num = navt;
end

if isdatetime(gpst)
    gpst_num = datenum(gpst) * 24 * 3600;  % 转换为秒
else
    gpst_num = gpst;
end

% 3 对所有的卫星按照接受机时间，进行卫星坐标的插值
% 3.1 将导航星历按照横轴时间，列是卫星编号，分x，y，z存储
numt = numel(navt);
numid = numel(gpsIDU);
x = NaN(numt,numid);% 
y = NaN(numt,numid);
z = NaN(numt,numid);

% 显示星历数据信息
fprintf('\n星历数据信息:\n');
fprintf('星历时间点数量: %d\n', numt);
fprintf('卫星数量: %d\n', numid);

for i = 1:numel(navt)
    for j =1:numel(gpsIDU)
        % 确保两个变量都是数值类型
        satID_num = str2double(eph(i).satID);
        if isnan(satID_num)
            continue;
        end
        ia = (satID_num == gpsIDU(j));
        if ~any(ia)
            continue;
        else
            x(i,j) = eph(i).satPos(ia,1);
            y(i,j) = eph(i).satPos(ia,2);
            z(i,j) = eph(i).satPos(ia,3);
        end
    end
end

% 显示卫星位置数据信息
fprintf('\n卫星位置数据信息:\n');
fprintf('有效x坐标数量: %d\n', sum(~isnan(x(:))));
fprintf('有效y坐标数量: %d\n', sum(~isnan(y(:))));
fprintf('有效z坐标数量: %d\n', sum(~isnan(z(:))));

% 对x,y,z进行插值
satx = NaN(numel(gpst),numid);
saty = NaN(numel(gpst),numid);
satz = NaN(numel(gpst),numid);
for i =1:numel(gpsIDU)
    ia = ~isnan(x(:,i));
    if sum(ia) > 1  % 确保有足够的数据点进行插值
        try
            satx(:,i) = interp1(navt_num(ia),x(ia,i),gpst_num,'linear','extrap');
            saty(:,i) = interp1(navt_num(ia),y(ia,i),gpst_num,'linear','extrap');
            satz(:,i) = interp1(navt_num(ia),z(ia,i),gpst_num,'linear','extrap');
        catch
            fprintf('警告: 卫星 %d 的插值失败\n', gpsIDU(i));
        end
    end
end

satPosXYZ = NaN(numel(gpst),3);
for i=1:numel(gpst)
    ia = (gpsId(i) == gpsIDU);
    if any(ia)
        satPosXYZ(i,:) = [satx(i,ia),saty(i,ia),satz(i,ia)];
    end
end

% 显示最终数据信息
fprintf('\n最终数据信息:\n');
fprintf('有效卫星位置数量: %d\n', sum(~isnan(satPosXYZ(:,1))));
fprintf('有效伪距数量: %d\n', sum(~isnan(gpsC1C)));

% 数据验证
valid_data = ~isnan(gpsC1C) & ~isnan(satPosXYZ(:,1)) & ~isnan(satPosXYZ(:,2)) & ~isnan(satPosXYZ(:,3));
fprintf('同时有效的伪距和位置数据点数量: %d\n', sum(valid_data));

if sum(valid_data) < 4
    error('没有足够的有效数据点来计算接收机位置');
end

% 4 计算接收机的位置和加速度
recPos = receiverposition(gpsC1C(valid_data), satPosXYZ(valid_data,:));

end


