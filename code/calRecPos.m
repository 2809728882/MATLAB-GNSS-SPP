function positions=calRecPos(obs,eph)
%CALRECPOS Compatibility helper for reception-frame precomputed satellite states.
% Prefer RUNSPP for transmit-time orbit/clock and Earth-rotation corrections.
gps=obs.GPS; epochs=unique(gps.Time); positions=NaN(numel(epochs),3);
for k=1:numel(epochs)
    rows=gps(gps.Time==epochs(k),:); xyz=NaN(height(rows),3); clk=zeros(height(rows),1);
    code=intersect({'C1C','C1W','C1','P1'},rows.Properties.VariableNames,'stable');
    if isempty(code), error('SPP:NoCode','GPS L1 pseudorange is required'); end
    for j=1:height(rows)
        ids={eph.satID}; ix=find(strcmp(ids,sprintf('G%02d',rows.SatNO(j))) & [eph.t]==epochs(k),1);
        if isempty(ix), continue; end
        xyz(j,:)=eph(ix).satPos; if isfield(eph,'clock'), clk(j)=eph(ix).clock; end
    end
    solution=solveSPPEpoch(rows.(code{1}),xyz,clk); positions(k,:)=solution.Position;
end
end
