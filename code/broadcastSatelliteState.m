function [xyz,clock]=broadcastSatelliteState(eph,time)
%BROADCASTSATELLITESTATE GPS broadcast orbit (ECEF m) and L1 clock (seconds).
mu=3.986005e14; omegaEarth=7.2921151467e-5;
gpsSeconds=seconds(time-datetime(1980,1,6));
tk=wrapWeek(gpsSeconds-(eph.GPS_Week*604800+eph.Toe));
a=eph.sqrtA^2; e=eph.Eccentricity;
if ~isfinite(a) || a<=0 || ~isfinite(e) || e<0 || e>=1, error('SPP:Orbit','Invalid orbit parameters'); end
m=eph.M0+(sqrt(mu/a^3)+eph.Delta_n)*tk; E=m;
for k=1:20
    d=(E-e*sin(E)-m)/(1-e*cos(E)); E=E-d; if abs(d)<1e-13, break; end
end
phi=atan2(sqrt(1-e^2)*sin(E),cos(E)-e)+eph.omega;
u=phi+eph.Cus*sin(2*phi)+eph.Cuc*cos(2*phi);
r=a*(1-e*cos(E))+eph.Crs*sin(2*phi)+eph.Crc*cos(2*phi);
inc=eph.i0+eph.IDOT*tk+eph.Cis*sin(2*phi)+eph.Cic*cos(2*phi);
omega=eph.OMEGA0+(eph.OMEGA_DOT-omegaEarth)*tk-omegaEarth*eph.Toe;
x=r*cos(u); y=r*sin(u);
xyz=[x*cos(omega)-y*cos(inc)*sin(omega), x*sin(omega)+y*cos(inc)*cos(omega), y*sin(inc)];
dt=wrapWeek(seconds(time-eph.Time));
clock=eph.SVClockBias+eph.SVClockDrift*dt+eph.SVClockDriftRate*dt^2 ...
    -4.442807633e-10*e*eph.sqrtA*sin(E)-eph.TGD;
end
function t=wrapWeek(t)
t=mod(t+302400,604800)-302400;
end
