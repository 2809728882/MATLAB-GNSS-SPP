function h = readOBShead(path)
%READOBSHEAD Read RINEX 2/3 observation metadata and continuation records.
fid=fopen(path,'rt');
if fid<0, error('SPP:FileOpen','Cannot open %s',path); end
guard=onCleanup(@() fclose(fid));
h=struct('ver',NaN,'version',NaN,'stationAPPR',[NaN NaN NaN], ...
    'types',struct(),'num_lines',0,'timeSystem','GPS');
lastSystem=''; ended=false;
while true
    line=fgetl(fid); if ~ischar(line), break; end
    h.num_lines=h.num_lines+1; line=[line repmat(' ',1,max(0,80-length(line)))];
    label=strtrim(line(61:end));
    if contains(label,'RINEX VERSION')
        h.version=str2double(line(1:9)); h.ver=floor(h.version);
    elseif contains(label,'APPROX POSITION')
        h.stationAPPR=sscanf(line(1:60),'%f',3)';
    elseif contains(label,'TIME OF FIRST OBS')
        h.firstObsTime=sscanf(line(1:43),'%f',6)';
        ts=strtrim(line(49:51)); if ~isempty(ts), h.timeSystem=ts; end
    elseif contains(label,'SYS / # / OBS TYPES')
        if line(1)~=' '
            lastSystem=line(1); counts.(lastSystem)=str2double(line(4:6));
            h.types.(lastSystem)={};
        end
        if isempty(lastSystem), error('SPP:Header','Orphan observation-type continuation'); end
        h.types.(lastSystem)=[h.types.(lastSystem) regexp(strtrim(line(7:60)),'\S+','match')];
    elseif contains(label,'TYPES OF OBSERV')
        if ~isfield(h.types,'G'), h.types.G={}; counts.G=str2double(line(1:6)); end
        h.types.G=[h.types.G regexp(strtrim(line(7:60)),'\S+','match')];
    elseif contains(label,'END OF HEADER')
        ended=true; break;
    end
end
if ~ended, error('SPP:Header','Missing END OF HEADER in %s',path); end
if ~ismember(h.ver,[2 3]), error('SPP:Version','Supported observation versions: RINEX 2 and 3'); end
systems=fieldnames(h.types);
for k=1:numel(systems)
    s=systems{k}; if numel(h.types.(s))~=counts.(s), error('SPP:Header','Incorrect %s observation count',s); end
end
if isempty(systems), error('SPP:Header','Missing observation types'); end
if h.ver==2
    for s='RCE', h.types.(s)=h.types.G; end
end
% Compatibility metadata for the original readers.
for s='GCRE'
    if ~isfield(h.types,s), h.types.(s)={}; end
    h.(['type_' s])=h.types.(s); h.(['num_' s])=numel(h.types.(s));
end
end
