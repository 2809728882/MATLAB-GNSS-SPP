function downloadNAV()
% 下载广播星历文件
% 从CDDIS下载最新的广播星历文件

% 设置下载参数
url = 'https://cddis.nasa.gov/archive/gnss/data/daily/';
year = datestr(now, 'yyyy');
doy = floor(datenum(now) - datenum(year, 'yyyy') + 1);
doy_str = sprintf('%03d', doy);

% 构建文件名
filename = sprintf('brdc%03d0.%02dn', doy, mod(str2double(year), 100));
url = [url year '/' doy_str '/' filename '.gz'];

% 设置保存路径
save_path = 'data/NAV/';
if ~exist(save_path, 'dir')
    mkdir(save_path);
end

% 下载文件
try
    fprintf('正在下载广播星历文件...\n');
    websave([save_path filename '.gz'], url);
    
    % 解压文件
    fprintf('正在解压文件...\n');
    gunzip([save_path filename '.gz']);
    delete([save_path filename '.gz']);
    
    fprintf('广播星历文件下载完成\n');
catch e
    fprintf('下载失败: %s\n', e.message);
    error('无法下载广播星历文件');
end

end 