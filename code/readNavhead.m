function h=readNavhead(path)
%READNAVHEAD Read NAV version with bounded EOF handling.
fid=fopen(path,'rt'); if fid<0, error('SPP:FileOpen','Cannot open %s',path); end
guard=onCleanup(@() fclose(fid)); h=struct('ver',NaN);
while true
    line=fgetl(fid); if ~ischar(line), error('SPP:Header','Missing NAV header terminator'); end
    if contains(line,'RINEX VERSION'), h.ver=floor(str2double(line(1:9))); end
    if contains(line,'END OF HEADER'), return; end
end
end
