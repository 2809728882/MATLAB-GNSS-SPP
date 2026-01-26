%{
这是一个标准单点定位的程序
使用方法：
1.下载观测文件
2.在setting函数中输入观测文件存放的路径
3.运行main.m函数
@copyright 

%}

%% 1 清除系统
clc;
clear all ;
addpath(genpath(pwd)); %添加了一个默认路径
% rmpath(genpath(pwd));
%% 2 读取设置文件
set = setting;
%% 预读取文件，文件时间，进行匹配，给出匹配结果******************
processinfo = filesParper(set);

%% 3 读取观测文件
if processinfo.useobs == 1
    obs_data = readObsFile(set);
    if isempty(obs_data)
        msgbox('读取观测文件失败！');
        return;
    end
else
    msgbox('没有找到可用的观测文件！');
    return;
end

%% 4 处理卫星断轨道数据
if processinfo.usesp3 == 1
    % 读取SP3
    [pos, vel, satIDs] = readSP3;
    % 将数据组织成结构体数组格式
    eph = struct('t', cell(size(pos,1),1), 'satID', cell(size(pos,1),1), 'satPos', cell(size(pos,1),1));
    for i = 1:size(pos,1)
        eph(i).t = i * 15; % 假设时间间隔为15秒
        eph(i).satID = satIDs(i);
        eph(i).satPos = pos(i,:);
    end
else
    if processinfo.usenav == 0
        % 使用现有的导航文件
        fprintf('使用现有的导航文件: data/nav/brdm0870.19p\n');
        Nav_files = readNavFile(set);
        if isempty(Nav_files)
            error('无法读取导航文件');
        end
        nav = Nav_files{1,1};
        gpsNav = nav.GPS; %数据
        tgps = gpsNav.Time;% 时间
        t_u= unique(tgps);
        [pos, vel, satIDs] = GNSSSatelliteLocation(gpsNav, t_u);
        % 将数据组织成结构体数组格式
        eph = struct('t', cell(size(pos,1),1), 'satID', cell(size(pos,1),1), 'satPos', cell(size(pos,1),1));
        for i = 1:size(pos,1)
            eph(i).t = t_u(i);
            eph(i).satID = satIDs(i);
            eph(i).satPos = pos(i,:);
        end
    else
        Nav_files = readNavFile(set);
        nav = Nav_files{1,1};
        gpsNav = nav.GPS; %数据
        tgps = gpsNav.Time;% 时间
        t_u= unique(tgps);
        [pos, vel, satIDs] = GNSSSatelliteLocation(gpsNav, t_u);
        % 将数据组织成结构体数组格式
        eph = struct('t', cell(size(pos,1),1), 'satID', cell(size(pos,1),1), 'satPos', cell(size(pos,1),1));
        for i = 1:size(pos,1)
            eph(i).t = t_u(i);
            eph(i).satID = satIDs(i);
            eph(i).satPos = pos(i,:);
        end
    end
end

%% 6 计算接收机的位置以及加速度
[P] = calRecPos(obs_data, eph);
% 问题6 计算接收机位置的算法也是黑盒子，不可控制。天顶对流层延迟的误差。


