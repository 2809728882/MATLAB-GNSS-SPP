
function headinfo = readNavhead(filepathName)
fpID = fopen(filepathName);
if fpID == -1
    msg = [filename ' 此文件读取失败，请检查文件名是否正确，或者检查路径是否正确。'];
    msgbox(msg)
end

while 1
    line = fgetl(fpID);
    % 1 读取rinex 版本
    if contains(line,'RINEX VERSION')
        headinfo.ver = floor(str2double(line(1:12)));

    end

     % 判断是否位于文件尾部
    if contains(line,'END OF HEADER')
        break
    end
end