function out = readObservationFile(path,maxEpochs)
%READOBSERVATIONFILE Parse RINEX 2/3 fixed-width observations (metres/cycles).
% Time is represented as naive datetime in the header's time system, not UTC.
if nargin<2, maxEpochs=Inf; end
validateattributes(maxEpochs,{'numeric'},{'scalar','positive'});
h=readOBShead(path); fid=fopen(path,'rt'); guard=onCleanup(@() fclose(fid));
for k=1:h.num_lines, fgetl(fid); end
rows=struct('G',{{}},'C',{{}},'R',{{}},'E',{{}}); count=0;
while count<maxEpochs
    line=fgetl(fid); if ~ischar(line), break; end
    if isempty(strtrim(line)), continue; end
    if h.ver==3
        if line(1)~='>', error('SPP:Observation','Expected RINEX 3 epoch record'); end
        epochData=sscanf(line(2:end),'%f');
        if numel(epochData)<8, error('SPP:Observation','Invalid epoch record'); end
        flag=epochData(7); nsat=epochData(8);
        if flag==4, error('SPP:HeaderChange','Mid-file header changes are not supported'); end
        if flag>=2 && flag<=5
            for j=1:nsat, requiredLine(fid); end
            continue;
        end
        dt=datetime(epochData(1:6)');
        for j=1:nsat
            rec=requiredLine(fid); rec=[rec repmat(' ',1,max(0,3-length(rec)))]; s=rec(1);
            if ~isfield(h.types,s), error('SPP:Observation','Missing header types for system %s',s); end
            n=numel(h.types.(s)); payload=rec(4:end);
            % Accept wrapped records without consuming the next satellite/epoch.
            while length(payload)<16*n
                saved=ftell(fid); extra=fgetl(fid);
                if ~ischar(extra), break; end
                if length(extra)>=3 && all(extra(1:3)==' ') && ~isempty(strtrim(extra))
                    payload=[payload repmat(' ',1,mod(-length(payload),16)) extra(4:end)]; %#ok<AGROW>
                else
                    fseek(fid,saved,'bof'); break;
                end
            end
            if flag<=1 && isfield(rows,s)
                rows.(s){end+1,1}=[datenum(dt) str2double(rec(2:3)) obsFields(payload,n)];
            end
        end
    else
        line=[line repmat(' ',1,max(0,80-length(line)))];
        flag=str2double(line(29)); nsat=str2double(line(30:32));
        if ~isfinite(nsat), error('SPP:Observation','Invalid RINEX 2 satellite count'); end
        if flag==4, error('SPP:HeaderChange','Mid-file header changes are not supported'); end
        if flag>=2 && flag<=5
            for j=1:nsat, requiredLine(fid); end
            continue;
        end
        epochData=sscanf(line(1:26),'%f');
        if numel(epochData)~=6, error('SPP:Observation','Invalid RINEX 2 epoch'); end
        y=epochData(1); if y<80, y=y+2000; else, y=y+1900; end
        epochData(1)=y; dt=datetime(epochData'); ids=line(33:68);
        while length(ids)<3*nsat
            extra=requiredLine(fid); extra=[extra repmat(' ',1,max(0,68-length(extra)))];
            ids=[ids extra(33:68)]; %#ok<AGROW>
        end
        n=numel(h.types.G);
        for j=1:nsat
            payload='';
            for q=1:ceil(n/5)
                rec=requiredLine(fid); rec=[rec repmat(' ',1,max(0,80-length(rec)))];
                payload=[payload rec(1:80)]; %#ok<AGROW>
            end
            id=ids(3*j-2:3*j); s=id(1); if s==' ', s='G'; end
            if flag<=1 && isfield(rows,s)
                rows.(s){end+1,1}=[datenum(dt) str2double(id(2:3)) obsFields(payload,n)];
            end
        end
    end
    if flag<=1, count=count+1; end
end
names=struct('G','GPS','C','BDS','R','GLONASS','E','Galileo');
for s='GCRE'
    if isempty(rows.(s)), data=zeros(0,2+numel(h.types.(s))); else, data=vertcat(rows.(s){:}); end
    t=array2table(data(:,2:end),'VariableNames',[{'SatNO'} h.types.(s)]);
    t.Time=datetime(data(:,1),'ConvertFrom','datenum');
    t=movevars(t,'Time','Before',1); out.(names.(s))=t;
end
out.Header=h;
end
function line=requiredLine(fid)
line=fgetl(fid); if ~ischar(line), error('SPP:Truncated','Unexpected end of observation file'); end
end
function values=obsFields(text,n)
text=[text repmat(' ',1,max(0,16*n-length(text)))]; values=NaN(1,n);
for k=1:n
    values(k)=str2double(strrep(text(16*k-15:16*k-2),'D','E'));
end
end
