function processInfo = filesParper(set)

%%
% 1 检查有无观测文件，观测文件的版本
obsheadinfo = checkobsfiles(set.filePath);
if isnan(obsheadinfo.ver)
    useobs = 0;
else
    useobs = 1;
end

%2 检查有无精密星历
SP3headinfo = checkSP3files(set.filePath_SP3);

% 初始化usenav变量
usenav = 0;

% 3 如果过2中没有精密星历，再检查有无广播星历
if isempty(SP3headinfo) || (numel(SP3headinfo) == 1 && isstruct(SP3headinfo) && isempty(fieldnames(SP3headinfo)))
    usesp3 = 0;
    Navfilesinfo = checkNavfiles(set.filePath_N);
    if isnan(Navfilesinfo.ver)
        usenav = 0;
    else
        usenav = 1;
    end
else
    usesp3 = 1;
    Navfilesinfo = NaN;
end

% 4 给出处理策略
processInfo.useobs = useobs;
processInfo.usenav = usenav;
processInfo.usesp3 = usesp3;
processInfo.obsheadinfo = obsheadinfo;
processInfo.SP3headinfo = SP3headinfo;
processInfo.Navfilesinfo = Navfilesinfo;
end
%%
%% subfunction ---------------
%% 1 检查obs
function obsheadinfo = checkobsfiles(obsfilePath)

obsfiles = dir(obsfilePath);%读取这个文件下的所有信息
obsfileNames = {obsfiles(~[obsfiles.isdir]).name};
num_obsfiles = numel(obsfileNames);
if num_obsfiles == 0
    msgbox([obsfilePath '文件夹下没有文件！！！']);
    obsheadinfo = NaN;
    return;
end
for i = 1:num_obsfiles
    obsheadinfo(i) = readOBShead([obsfilePath '\' obsfileNames{i}]);
end
end

%% 检查 sp3
function SP3headinfo = checkSP3files(SP3filePath)

SP3files = dir(SP3filePath);%读取这个文件下的所有信息
SP3fileNames = {SP3files(~[SP3files.isdir]).name};
num_files = numel(SP3fileNames);
if num_files == 0
    msgbox([SP3filePath '文件夹下没有文件！！！']);
    SP3headinfo = NaN;
    return;
end
for i = 1:num_files
    SP3headinfo(i) = readSP3head([SP3filePath '\' SP3fileNames{i}]);
end
end


%% 4 检查NAV
function Navfilesinfo = checkNavfiles(obsfilePath)
obsfiles = dir(obsfilePath);%读取这个文件下的所有信息
obsfileNames = {obsfiles(~[obsfiles.isdir]).name};
num_obsfiles = numel(obsfileNames);
if num_obsfiles == 0
    msgbox([obsfilePath '文件夹下没有文件！！！']);
    obsheadinfo = NaN;
    return;
end
for i = 1:num_obsfiles
    Navfilesinfo(i) = readNavhead([obsfilePath '\' obsfileNames{i}]);
end
end
