function [pos,vel,satIDs]=computeSatellitePosition(t,nav)
%COMPUTESATELLITEPOSITION Compatibility alias for the toolbox-free orbit.
[pos,vel,satIDs]=GNSSSatelliteLocation(nav,t);
end
