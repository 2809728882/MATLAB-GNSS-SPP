function solution=solveSPPEpoch(pseudorange,satPosition,satClock,initial)
%SOLVESPPEPOCH Estimate ECEF receiver position and clock in a single epoch.
% Satellite coordinates must already refer to the reception ECEF frame.
if nargin<4, initial=[0 0 0]; end
c=299792458; pseudorange=pseudorange(:); satClock=satClock(:);
if size(satPosition,1)~=numel(pseudorange) || size(satPosition,2)~=3 || numel(satClock)~=numel(pseudorange)
    error('SPP:Dimensions','One XYZ and clock per pseudorange are required');
end
valid=isfinite(pseudorange) & pseudorange>1e6 & pseudorange<1e8 & all(isfinite(satPosition),2) & isfinite(satClock);
p=pseudorange(valid)+c*satClock(valid); s=satPosition(valid,:);
if numel(p)<4, error('SPP:InsufficientSatellites','At least four valid satellites are required'); end
state=[initial(:);0]; converged=false;
for iteration=1:15
    [H,rho]=geometry(state(1:3),s);
    if rank(H)<4 || rcond(H'*H)<1e-12, error('SPP:Geometry','Satellite geometry is singular'); end
    delta=H\(p-rho-state(4)); state=state+delta;
    if norm(delta)<1e-4, converged=true; break; end
end
if ~converged, error('SPP:Convergence','Receiver solution did not converge'); end
[H,rho]=geometry(state(1:3),s); residual=p-rho-state(4); Q=(H'*H)\eye(4);
solution=struct('Position',state(1:3)','ClockBiasSeconds',state(4)/c, ...
    'Residual',residual,'ResidualRMS',sqrt(mean(residual.^2)), ...
    'NumSatellites',numel(p),'PDOP',sqrt(trace(Q(1:3,1:3))), ...
    'GDOP',sqrt(trace(Q)),'Iterations',iteration);
end
function [H,rho]=geometry(receiver,sat)
delta=receiver'-sat; rho=sqrt(sum(delta.^2,2));
if any(rho<1), error('SPP:Geometry','Receiver coincides with satellite'); end
H=[delta./rho ones(size(sat,1),1)];
end
