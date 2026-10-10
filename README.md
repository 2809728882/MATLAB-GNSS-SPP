# MATLAB GNSS 标准单点定位系统

[![MATLAB validation](https://github.com/2809728882/MATLAB-GNSS-SPP/actions/workflows/matlab.yml/badge.svg)](https://github.com/2809728882/MATLAB-GNSS-SPP/actions/workflows/matlab.yml)

基于 MATLAB 的 **GPS L1 标准单点定位（SPP）** 项目。将 RINEX 读取、广播星历或 SP3 处理、卫星钟差与地球旋转改正、逐历元最小二乘解算和结果导出组织成可复现的离线流程。

仓库包含实测观测及配套星历，默认示例无需下载数据；核心算法使用 MATLAB 基础功能，不依赖 Navigation Toolbox。

## 功能

- **观测读取**：RINEX 2/3、观测类型与卫星列表续行、缺失值、LLI/SNR 字段隔离和普通事件记录；读取 GPS、BDS、GLONASS、Galileo 数据。
- **广播星历**：从 RINEX 2 GPS NAV 或 RINEX 3 混合 NAV 提取 GPS 星历，按卫星和观测时间选择健康且在有效年龄内的记录。
- **轨道和钟差**：计算广播轨道 ECEF 坐标、钟差多项式、相对论项和 L1 TGD；按信号发射时刻计算位置，处理传播期间地球旋转。
- **SP3 模式**：读取真实历元和钟差，统一 km→m、µs→s，识别缺失值；同星差分计算卫星速度，使用最多 9 个邻近节点的局部轨道插值及线性钟差插值，禁止外推。
- **逐历元解算**：估计 ECEF 坐标与接收机钟差，筛选无效观测，检查卫星几何和收敛状态，支持高度角截止与标称大气对流层改正。
- **质量与导出**：输出卫星数量、伪距残差 RMS、PDOP 和历元状态，生成 CSV、MAT、JSON 和质量曲线。
- **持续测试**：GitHub Actions 运行 MATLAB 回归测试及广播星历/SP3 实测样例，工作流附件包含测试报告和实际结果。

**功能范围**：多星座读取与多星座联合定位是不同的功能。当前定位使用 GPS L1 伪距，不包含接收机测速、RTK、PPP、RINEX 4、双频电离层消除、载波平滑或精密天线改正。使用 SP3 轨道也不会将算法变成 PPP。

## 快速开始

建议 MATLAB R2021b 或更新版本；自动测试使用 R2024b。切换到仓库根目录后运行：

```matlab
addpath('code');
result = main(); % 默认广播星历，前120个历元，保存至outputs/

% 精密轨道与钟差模式
result = main(struct('ephemerisMode','sp3'));

% 自定义数据
options = struct( ...
    'obsFile',fullfile(pwd,'data','obs','my_observation.rnx'), ...
    'navFile',fullfile(pwd,'data','nav','my_navigation.rnx'), ...
    'ephemerisMode','broadcast', ...
    'maxEpochs',300, ...
    'elevationMaskDeg',10, ...
    'maxEphemerisAgeSeconds',7200, ...
    'outputDir',fullfile(pwd,'outputs','my_run'), ...
    'makePlots',true);
result = runSPP(options);
```

SP3 模式通过 `sp3File` 指定文件。观测与星历必须覆盖同一日期和历元；当前流程要求 GPS 时间，不自动换算 UTC 或其他星座时间。下载是独立的显式操作，默认流程不联网。

## 输出文件

| 文件 | 内容 |
| --- | --- |
| positions.csv | 时间、ECEF XYZ、钟差、卫星数量、残差 RMS、PDOP、状态 |
| results.mat | 结果表与本次配置 |
| summary.json | 成功历元数、残差/PDOP中位数、头信息参考坐标 |
| quality.png | 逐历元残差 RMS 与 PDOP 曲线 |

坐标和残差单位是**米**，钟差单位是**秒**。`ok` 表示通过当前几何和收敛检查；失败历元保留状态与空值，全部失败时报错。残差 RMS 是模型拟合指标，不等于定位精度；观测文件头近似坐标也不自动作为独立真值。

## 数据和算法限制

- 默认 OBS、NAV、SP3 均为 2019-03-28 数据。`rinex2.11/bjfs0010.25o` 是 2025-01-01 数据，用于读取回归测试，不应与默认 2019 年星历配对。
- 当前单频伪距未做电离层改正，对流层使用标称大气近似；多路径、噪声、码偏差仍会影响结果。
- 不对不足四颗卫星、秩不足几何、超龄广播星历或缺少 SP3 覆盖强行输出坐标。
- 中途头信息变更明确报错，需先分割为头信息一致的数据段。
- 混合 NAV 的非 GPS 记录按完整记录跳过，GPS 解算不套用其他星座的时间与轨道模型。
- SP3 缺失坐标和钟差转为 NaN；轨道差分速度是卫星速度，不是接收机速度。

## 测试

```matlab
addpath('code');
results = runtests('tests');
assertSuccess(results);
```

覆盖合成坐标与钟差恢复、病态几何、缺失值、RINEX 2/3 续行与事件、SP3 单位与实际历元、同星速度差分、插值覆盖、广播轨道，以及两种星历模式的实测样例。

## 核心模块

```text
code/main.m                     示例入口
code/runSPP.m                   参数化逐历元流程
code/setting.m                  相对路径与默认参数
code/readObservationFile.m      RINEX 2/3 观测读取
code/readOBShead.m              头信息与观测类型
code/readNavRINEX3.m             RINEX 2/3 GPS 星历
code/readSP3.m                  精密轨道与钟差
code/broadcastSatelliteState.m  广播轨道与钟差计算
code/interpolateSP3.m           精密轨道与钟差插值
code/solveSPPEpoch.m            最小二乘坐标与钟差
tests/                          MATLAB 回归测试
.github/workflows/              自动测试与结果附件
docs/CHANGELOG.md               更新记录
```

原 `readOSBrinex2/3` 等入口保留为兼容包装；`calRecPos` 只处理准备好的同历元接收坐标系卫星状态。完整选择、传播时间和改正流程使用 `runSPP`。

## 格式参考

- [IGS RINEX 3.05](https://files.igs.org/pub/data/format/rinex305.pdf)
- [IGS SP3](https://files.igs.org/pub/data/format/sp3d.pdf)
- [MATLAB 官方 GitHub Actions](https://github.com/matlab-actions)

MIT 许可证。作者 XIa Bai。
