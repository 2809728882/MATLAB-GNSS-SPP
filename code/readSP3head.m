function h=readSP3head(path)
%READSP3HEAD Derive coverage metadata from actual SP3 epochs.
[~,~,ids,times]=readSP3(path);
h=struct('startTime',min(times),'endTime',max(times),'satellites',{unique(ids)});
epochs=unique(times); if numel(epochs)>1, h.intervalSeconds=median(seconds(diff(epochs))); else, h.intervalSeconds=NaN; end
end
