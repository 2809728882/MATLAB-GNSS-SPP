MATLAB GNSS 标准单点定位工具
本项目是一个基于 MATLAB 开发的 GNSS 标准单点定位（SPP）开源程序。它能够解析 RINEX 格式观测数据和广播星历（或精密星历），对齐时间戳，并解算接收机 PVT（位置、速度、时间）。

 核心特性 (Features)
多版本 RINEX 支持：
完全支持 RINEX 2.xx 观测文件解析。
完全支持 RINEX 3.xx 观测文件解析。
(代码预留了 RINEX 4.xx 接口，需补充对应模块)。
多系统数据读取：
底层解析器支持提取 GPS (G), BDS (C), GLONASS (R), Galileo (E) 的原始观测数据。
注：目前的解算主程序 (main.m) 主要针对 GPS 系统进行定位演示。
灵活的星历模式：
广播星历模式：支持 RINEX 导航电文读取与轨道计算。
精密星历模式 (SP3)：支持读取 .sp3 文件，并内置了利用位置中心差分法计算卫星速度的功能。
自动化处理流程：
自动识别观测文件版本。
自动从 NASA CDDIS 下载最新的广播星历。
目录结构与文件说明 (Structure)
请确保你的项目文件夹结构如下，以便 setting.m 能正确索引：

Project_Root/
├── data/                  # 数据存放目录 (需手动创建)
│   ├── obs/               # 存放观测文件 (.xxo, .rnx)
│   ├── nav/               # 存放广播星历 (.xxn, .xxp)
│   └── SP3/               # 存放精密星历 (.sp3)
├── main.m                 # [入口] 主程序
├── setting.m              # [配置] 路径与参数配置文件
├── filesParper.m          # [预处理] 文件存在性与版本检查
├── downloadNAV.m          # [工具] 自动下载广播星历
├── 核心解算/
│   ├── calRecPos.m               # 接收机位置解算 (最小二乘/插值)
│   ├── calSatPos.m               # 卫星位置计算封装
│   ├── GNSSSatelliteLocation.m   # 广播星历轨道计算核心算法
│   └── computeSatellitePosition.m # 开普勒轨道参数解算
└── 数据读取/
    ├── readObsFile.m      # 观测文件读取入口 (分发器)
    ├── readOBShead.m      # 读取观测文件头信息
    ├── readOSBrinex2.m    # 解析 RINEX 2.x 数据体
    ├── readOSBrinex3.m    # 解析 RINEX 3.x 数据体
    ├── readNavFile.m      # 读取导航电文
    └── readSP3.m          # 读取 SP3 精密星历
