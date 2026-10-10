function eph=calSatPos(nav)
%CALSATPOS Build per-satellite broadcast states without gnssconstellation.
if iscell(nav), nav=nav{1}; end
if isstruct(nav), nav=nav.GPS; end
[pos,~,ids]=GNSSSatelliteLocation(nav,nav.Time);
eph=struct('t',cell(height(nav),1),'satID',[],'satPos',[],'clock',[]);
for k=1:height(nav)
    eph(k).t=nav.Time(k); eph(k).satID=sprintf('G%02d',ids(k)); eph(k).satPos=pos(k,:);
    [~,eph(k).clock]=broadcastSatelliteState(nav(k,:),nav.Time(k));
end
end
