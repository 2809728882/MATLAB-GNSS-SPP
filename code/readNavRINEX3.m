function nav=readNavRINEX3(path)
%READNAVRINEX3 Read GPS ephemerides from RINEX 2 GPS / RINEX 3 mixed NAV.
% Unsupported constellations are skipped as complete records, never decoded as GPS.
fid=fopen(path,'rt'); if fid<0, error('SPP:FileOpen','Cannot open %s',path); end
guard=onCleanup(@() fclose(fid)); version=NaN; ended=false;
while true
    line=fgetl(fid); if ~ischar(line), break; end
    if contains(line,'RINEX VERSION'), version=floor(str2double(line(1:9))); end
    if contains(line,'END OF HEADER'), ended=true; break; end
end
if ~ended, error('SPP:Header','Missing NAV header terminator'); end
if ~ismember(version,[2 3]), error('SPP:Version','Supported NAV versions: 2 and 3'); end
rows={}; epochs=[];
while true
    line=fgetl(fid); if ~ischar(line), break; end
    if isempty(strtrim(line)), continue; end
    line=[line repmat(' ',1,max(0,80-length(line)))];
    if version==3
        sys=line(1); id=str2double(line(2:3)); stamp=sscanf(line(4:23),'%f'); start=24; indent=4;
        if ismember(sys,'RS'), block=4; elseif ismember(sys,'GECJI'), block=8;
        else, error('SPP:Navigation','Unsupported NAV system %s',sys); end
    else
        sys='G'; id=str2double(line(1:2)); stamp=sscanf(line(4:22),'%f'); start=23; indent=3; block=8;
        if numel(stamp)==6
            if stamp(1)<80, stamp(1)=stamp(1)+2000; else, stamp(1)=stamp(1)+1900; end
        end
    end
    values=NaN(1,31); values(1:3)=navFields(line,start,3);
    for k=1:block-1
        line=fgetl(fid); if ~ischar(line), error('SPP:Truncated','Truncated NAV record'); end
        if sys=='G', values(3+4*k-3:3+4*k)=navFields(line,indent+1,4); end
    end
    if sys=='G'
        if numel(stamp)~=6 || ~isfinite(id), error('SPP:Navigation','Invalid GPS NAV epoch'); end
        rows{end+1,1}=[id values]; epochs(end+1,1)=datenum(stamp'); %#ok<AGROW>
    end
end
names={'SatelliteID','SVClockBias','SVClockDrift','SVClockDriftRate', ...
    'IODE','Crs','Delta_n','M0','Cuc','Eccentricity','Cus','sqrtA', ...
    'Toe','Cic','OMEGA0','Cis','i0','Crc','omega','OMEGA_DOT', ...
    'IDOT','L2ChannelCodes','GPS_Week','L2PDataFlag','SVAccuracy', ...
    'SVHealth','TGD','IODC','TransmissionTime','FitInterval','Spare1','Spare2'};
if isempty(rows), data=zeros(0,32); else, data=vertcat(rows{:}); end
nav.GPS=array2table(data,'VariableNames',names);
nav.GPS.Time=datetime(epochs,'ConvertFrom','datenum');
nav.GPS=movevars(nav.GPS,'Time','Before',1);
nav.GPS.PRN=nav.GPS.SatelliteID;
end
function v=navFields(line,start,n)
line=[line repmat(' ',1,max(0,start+19*n-1-length(line)))]; v=NaN(1,n);
for j=1:n, v(j)=str2double(strrep(line(start+19*(j-1):start+19*j-1),'D','E')); end
end
