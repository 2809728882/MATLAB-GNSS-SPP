function sp3 = readSP3head(fp)
    fid = fopen(fp);
    if fid == -1
        error(['无法打开文件 ' fp]);
    end
    sp3 = struct();
    line = fgetl(fid);
    while ~strncmp(line, 'EOF', 3)
        if strncmp(line, '*', 1)
            % 读取头部时间信息
            temp = textscan(line(2:end), '%f %f %f %f %f %f');
            sp3.dt = datetime(cell2mat(temp));
        end
        line = fgetl(fid);
    end
    fclose(fid);
end