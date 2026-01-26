function [pos, vel, satIDs] = GNSSSatelliteLocation(Nav_D, t)


%% 1 提取参数
[weekNum, toe, ARef, deltaA, ADot, deltan0, ...
    deltan0Dot, M0, e0, omega0, i0, iDot, iDel, ...
    Cis, Cic, Crs, Crc, Cus, Cuc, OmegaRefDot, ...
    Omega0, deltaOmegaDot, satIDs] = extractParameters(Nav_D);

%% 2 计算时间
[gnssWeek, tow] = getGNSSTime(t);
i0 = i0 + iDel;


%% 3 计算一些常数

% Get Earth's gravitational constant and rotation rate
dataType = 'double';
% Gravitational constant (m^3/s^2)
mu = cast(3.986005e14, dataType);
% Rotation rate (rad/s)
OmegaEDot = cast(7.2921151467e-5, dataType);


%% 卫星位置和加速度计算
[pos, vel] = computeSatPosVel(gnssWeek, tow, weekNum, toe, ARef, deltaA, ADot, ...
                                    mu, deltan0, deltan0Dot, M0, e0, ...
                                    omega0, i0, iDot, ...
                                    Cis, Cic, Crs, Crc, Cus, Cuc, ...
                                    OmegaEDot, OmegaRefDot, Omega0, deltaOmegaDot);
end


%% 以下是子函数-----------------------------------------------------------
function [gnssWeek, Tow] = getGNSSTime(t)
gpsStart = datetime(1980, 1, 6, 0, 0, 0, 'TimeZone', 'UTCLeapSeconds');
if isempty(t.TimeZone)
    t.TimeZone = 'UTC';
end
t.TimeZone = 'UTCLeapSeconds';
secondsPerWeek = 604800;
dateDiff = seconds(t - gpsStart);
gnssWeek = floor(dateDiff / secondsPerWeek);
Tow = dateDiff - (gnssWeek * secondsPerWeek);
end

function [pos, vel] = computeSatPosVel(gpsWeek, t, weekNum, toe, ...
    ARef, deltaA, ADot, ...
    mu, deltan0, deltan0Dot, ...
    M0, e0, omega0, ...
    i0, iDot, ...
    Cis, Cic, Crs, Crc, Cus, Cuc, ...
    OmegaEDot, OmegaRefDot, Omega0, deltaOmegaDot)

secondsPerWeek = 604800;

% Time from ephemeris reference time
tSys = t;
currGPSWeekNum = gpsWeek;
tk = ((currGPSWeekNum - weekNum)*secondsPerWeek + tSys) - toe;
% Add rollover if magnitude of |tk| is above a certain range, for GPS week
% crossover.
while any(tk > secondsPerWeek / 2)
    tk(tk > secondsPerWeek / 2) ...
        = tk(tk > secondsPerWeek / 2) - secondsPerWeek;
end
while any(tk < -secondsPerWeek / 2)
    tk(tk < -secondsPerWeek / 2) ...
        = tk(tk < -secondsPerWeek / 2) + secondsPerWeek;
end

% Semi-Major Axis at reference time
A0 = ARef + deltaA;
% Semi-Major Axis
Ak = A0 + ADot.*tk;

% Computed Mean Motion
n0 = sqrt(mu ./ A0.^3);
% Mean motion difference from computed value
deltanA = deltan0 + 0.5.*deltan0Dot.*tk;
% Corrected Mean Motion
nA = n0 + deltanA;

% Mean Anomaly
Mk = M0 + nA.*tk;
% Eccentric Anomaly
Ek = solveKeplerEquationEccentricAnomaly(e0, Mk);
cosEk = cos(Ek);
sinEk = sin(Ek);
% True Anomaly
vk = atan2((sqrt(1 - e0.^2) .* sinEk) ./ (1 - e0 .* cosEk), ...
    (cosEk - e0) ./ (1 - e0 .* cosEk));
% Argument of Latitude
Phik = vk + omega0;
sin2Phik = sin(2*Phik);
cos2Phik = cos(2*Phik);

% Calculate second harmonic perturbations
% Argument of Latitude Correction
deltauk = Cus .* sin2Phik + Cuc .* cos2Phik;
% Radial Correction
deltark = Crs .* sin2Phik + Crc .* cos2Phik;
% Inclination Correction
deltaik = Cis .* sin2Phik + Cic .* cos2Phik;

% Corrected Argument of Latitude
uk = Phik + deltauk;
cosuk = cos(uk);
sinuk = sin(uk);
% Corrected Radius
rk = Ak .* (1 - e0 .* cosEk) + deltark;
% Corrected Inclination
ik = i0 + iDot .* tk + deltaik;
cosik = cos(ik);
sinik = sin(ik);

% Positions in orbital plane
xkPrime = rk .* cosuk;
ykPrime = rk .* sinuk;

% Rate of Right Ascension
OmegaDot = OmegaRefDot + deltaOmegaDot;
% Corrected Longitude of Ascending Node
Omegak = Omega0 + (OmegaDot - OmegaEDot) .* tk - OmegaEDot .* toe;
cosOmegak = cos(Omegak);
sinOmegak = sin(Omegak);

% ECEF Positions of Satellites
xk = xkPrime .* cosOmegak - ykPrime .* cosik .* sinOmegak;
yk = xkPrime .* sinOmegak + ykPrime .* cosik .* cosOmegak;
zk = ykPrime .* sinik;

% Concatenate outputs. S-by-3-by-T output matrix where S is the number of
% satellites and T is the number of time samples.
pos = [xk, yk, zk];

% Eccentric Anomaly derivative
EkDot = nA ./ (1 - e0 .* cosEk);
% Argument of Latitude derivative
PhikDot = (sin(vk) ./ sinEk) .* EkDot;

% Argument of Latitude Correction derivative
deltaukDot = 2 * (Cus .* cos2Phik - Cuc .* sin2Phik) .* PhikDot;
% Radial Correction derivative
deltarkDot = 2 * (Crs .* cos2Phik - Crc .* sin2Phik) .* PhikDot;
% Inclination Correction derivative
deltaikDot = 2 * (Cis .* cos2Phik - Cic .* sin2Phik) .* PhikDot;

% Corrected Radius derivative
rkDot = (Ak .* e0 .* sinEk) .* EkDot + deltarkDot;
% Corrected Argument of Latitude derivative
ukDot = PhikDot + deltaukDot;
% Corrected Inclination derivative
ikDot = iDot + deltaikDot;

% Velocities in orbital plane
xkPrimeDot = rkDot .* cosuk - rk .* ukDot .* sinuk;
ykPrimeDot = rkDot .* sinuk + rk .* ukDot .* cosuk;

% Corrected Longitude of Ascending Node derivative
OmegakDot = OmegaDot - OmegaEDot;

% ECEF Velocities of Satellites
xkDot = xkPrimeDot .* cosOmegak - ykPrimeDot .* cosik .* sinOmegak ...
    + ikDot .* ykPrime .* sinik .* sinOmegak - OmegakDot .* yk;
ykDot = xkPrimeDot .* sinOmegak + ykPrimeDot .* cosik .* cosOmegak ...
    - ikDot .* ykPrime .* sinik .* cosOmegak + OmegakDot .* xk;
zkDot = ykPrimeDot .* sinik + ikDot .* ykPrime .* cosik;

% Concatenate outputs. S-by-3-by-T output matrix where S is the number of
% satellites and T is the number of time samples.
vel = [xkDot, ykDot, zkDot];
end

function Ek = solveKeplerEquationEccentricAnomaly(e0, Mk)
% Solve Kepler's equation for Eccentric Anomaly
% Mk = Ek - e0*sin(Ek)
%
% Inputs:
% e0 Eccentricity
% Mk Mean Anomaly (rad)
%
% Outputs:
% Ek Eccentric Anomaly (rad)

numIters = 22;  % Empirical number to achieve millimeter accuracy.

Ek = Mk + (e0 .* sin(Mk)) ./ (1 - sin(Mk + e0) + sin(Mk));
for iter = 1:numIters
    Ek = Mk + e0 .* sin(Ek);
end

end

function [weekNum, toe, ARef, deltaA, ADot, deltan0, ...
    deltan0Dot, M0, e0, omega0, i0, iDot, iDel, ...
    Cis, Cic, Crs, Crc, Cus, Cuc, OmegaRefDot, ...
    Omega0, deltaOmegaDot, satIDs] = extractParameters(Nav_D)

weekNum = Nav_D.GPS_Week;
numSatellites = size(Nav_D, 1);
zeroVector  = zeros(numSatellites, 1, 'like', weekNum);

% Extract the orbital parameters from Nav_D and set
% remaining parameters to 0
toe           = Nav_D.Toe;
ARef          = Nav_D.sqrtA.^2;
deltaA        = zeroVector;
ADot          = zeroVector;
deltan0       = Nav_D.Delta_n;
deltan0Dot    = zeroVector;
M0            = Nav_D.M0;
e0            = Nav_D.Eccentricity;
omega0        = Nav_D.omega;
i0            = Nav_D.i0;
iDot          = Nav_D.IDOT;
iDel          = zeroVector;
Cis           = Nav_D.Cis;
Cic           = Nav_D.Cic;
Crs           = Nav_D.Crs;
Crc           = Nav_D.Crc;
Cus           = Nav_D.Cus;
Cuc           = Nav_D.Cuc;
OmegaRefDot   = Nav_D.OMEGA_DOT;
Omega0        = Nav_D.OMEGA0;
deltaOmegaDot = zeroVector;
satIDs        = Nav_D.PRN;

end