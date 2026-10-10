function [xyz,clock,velocity]=interpolateSP3(sp3,id,time)
%INTERPOLATESP3 Local orbit polynomial and linear clock; no extrapolation.
ix=strcmp(sp3.ID,id) & all(isfinite(sp3.Position),2) & isfinite(sp3.Clock);
t=seconds(sp3.Time(ix)-time); p=sp3.Position(ix,:); c=sp3.Clock(ix);
[t,order]=sort(t); p=p(order,:); c=c(order);
[t,keep]=unique(t,'last'); p=p(keep,:); c=c(keep);
if numel(t)<2 || t(1)>0 || t(end)<0, error('SPP:SP3Coverage','No bracketing SP3 data for %s',id); end
lower=find(t<=0,1,'last'); upper=find(t>=0,1,'first');
if upper~=lower && t(upper)-t(lower)>2.1*median(diff(t))
    error('SPP:SP3Coverage','SP3 gap for %s',id);
end
[~,near]=sort(abs(t)); near=sort(near(1:min(9,numel(t)))); x=t(near); y=p(near,:);
scale=max(abs(x)); x=x/scale; weights=zeros(numel(x),1);
for k=1:numel(x), weights(k)=1/prod(x(k)-x([1:k-1 k+1:end])); end
exact=find(abs(x)<1e-11,1);
if ~isempty(exact)
    xyz=y(exact,:); velocity=zeros(1,3);
    for j=[1:exact-1 exact+1:numel(x)]
        velocity=velocity+(weights(j)/weights(exact))*(y(j,:)-xyz)/(x(exact)-x(j));
    end
    velocity=velocity/scale;
else
    z=weights./(-x); xyz=(z'*y)/sum(z);
    dz=-weights./(x.^2);
    velocity=((dz'*y)-xyz*sum(dz))/sum(z)/scale;
end
clock=interp1(t,c,0,'linear');
end
