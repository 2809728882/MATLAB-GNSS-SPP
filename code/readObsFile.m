function out=readObsFile(config)
%READOBSFILE Read one configured observation file or merge a directory.
if isfield(config,'obsFile'), out=readObservationFile(config.obsFile); return; end
files=dir(config.filePath); files=files(~[files.isdir]);
if isempty(files), error('SPP:NoObservations','No observation files found'); end
out=readObservationFile(fullfile(config.filePath,files(1).name));
for k=2:numel(files)
    next=readObservationFile(fullfile(config.filePath,files(k).name));
    for name={'GPS','BDS','GLONASS','Galileo'}
        key=name{1}; out.(key)=sortrows([out.(key);next.(key)],{'Time','SatNO'});
    end
end
end
