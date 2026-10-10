function [pos,vel,satIDs]=GNSSSatelliteLocation(nav,t)
%GNSSSATELLITELOCATION Compatibility broadcast-state wrapper, row-wise.
if numel(t)~=1 && numel(t)~=height(nav), error('SPP:Dimensions','Supply a scalar time or one time per NAV row'); end
pos=NaN(height(nav),3); vel=pos; satIDs=nav.SatelliteID;
for k=1:height(nav)
    if isscalar(t), tk=t; else, tk=t(k); end
    pos(k,:)=broadcastSatelliteState(nav(k,:),tk);
    before=broadcastSatelliteState(nav(k,:),tk-seconds(.5)); after=broadcastSatelliteState(nav(k,:),tk+seconds(.5));
    vel(k,:)=after-before;
end
end
