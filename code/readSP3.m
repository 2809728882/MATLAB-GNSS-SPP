function [pos,vel,satIDs,times,clocks]=readSP3(path)
%READSP3 Read SP3 positions in metres, clocks in seconds, true epoch times.
% Missing positions/clocks become NaN. Velocities use only the SAME satellite.
if nargin<1
    root=fileparts(fileparts(mfilename('fullpath')));
    path=fullfile(root,'data','SP3','igs20464.sp3');
end
fid=fopen(path,'rt'); if fid<0, error('SPP:FileOpen','Cannot open %s',path); end
guard=onCleanup(@() fclose(fid)); pos=zeros(0,3); satIDs=cell(0,1); serial=[]; clocks=[]; epoch=NaN;
while true
    line=fgetl(fid); if ~ischar(line), break; end
    if startsWith(line,'*')
        stamp=sscanf(line(2:end),'%f',6);
        if numel(stamp)~=6, error('SPP:SP3','Invalid SP3 epoch'); end
        epoch=datenum(stamp');
    elseif startsWith(line,'P')
        line=[line repmat(' ',1,max(0,60-length(line)))];
        if ~isfinite(epoch), error('SPP:SP3','Position record before epoch'); end
        xyz=NaN(1,3);
        for k=1:3, xyz(k)=str2double(line(5+14*(k-1):18+14*(k-1)))*1000; end
        if all(xyz==0) || any(abs(xyz)>=999999*1000), xyz(:)=NaN; end
        clk=str2double(line(47:60)); if abs(clk)>=999999, clk=NaN; end
        pos(end+1,:)=xyz; satIDs{end+1,1}=strtrim(line(2:4)); %#ok<AGROW>
        serial(end+1,1)=epoch; clocks(end+1,1)=clk*1e-6; %#ok<AGROW>
    elseif startsWith(line,'%c') && length(line)>=12
        ts=strtrim(line(10:12));
        if ~isempty(ts) && ~ismember(ts,{'GPS','ccc','cc'})
            error('SPP:TimeSystem','SP3 time system %s requires explicit conversion to GPS',ts);
        end
    end
end
if isempty(serial), error('SPP:SP3','No SP3 position records'); end
times=datetime(serial,'ConvertFrom','datenum'); vel=NaN(size(pos));
ids=unique(satIDs);
for k=1:numel(ids)
    ix=find(strcmp(satIDs,ids{k}) & all(isfinite(pos),2));
    [~,order]=sort(serial(ix)); ix=ix(order);
    for j=1:numel(ix)
        if numel(ix)<2, break; end
        a=max(1,j-1); b=min(numel(ix),j+1); elapsed=(serial(ix(b))-serial(ix(a)))*86400;
        if elapsed>0, vel(ix(j),:)=(pos(ix(b),:)-pos(ix(a),:))/elapsed; end
    end
end
end
