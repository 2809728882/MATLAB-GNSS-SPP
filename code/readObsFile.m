function OBS_D = readObsFile(set)
%{
读取所有的OBS文件

%}
%% 1确定观测文件夹下有多少文件
filePath = set.filePath;
files = dir(filePath);%读取这个文件下的所有信息
fileNames = {files(~[files.isdir]).name};


%% 2将结果存储
num_rinexfiles = numel(fileNames);


%% 3 判读有没有文件
if num_rinexfiles == 0
    msgbox("你搞笑吧，文件夹下没有文件！！！");
    return;    %不干了，回去了
end

%% 4 读取观测文件
for n_fisle = 1:num_rinexfiles %
    % header = readRinexObsHeader([filePath '\' fileNames{n_fisle}]);
    % OBS_D{n_fisle} = rinexread([filePath '\' fileNames{n_fisle}]);

    headinfo = readOBShead([filePath '\' fileNames{n_fisle}]);
    switch headinfo.ver

        case 2
            OBS_D = readOSBrinex2([filePath '\' fileNames{n_fisle}],headinfo);
        case 3
            OBS_D = readOSBrinex3([filePath '\' fileNames{n_fisle}],headinfo);
        case 4
            OBS_D = readOSBrinex4([filePath '\' fileNames{n_fisle}],headinfo);

        otherwise

            msgbox("没有发现rinex观测文件的版本，出错，请检查观测文件文件名，路径，以及观测文件中的内容");
    end

end
