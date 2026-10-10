function result=runSPP(options)
%RUNSPP Reproducible GPS L1 SPP from RINEX observations and NAV or SP3.
config=setting(); if nargin<1, options=struct(); end
keys=fieldnames(options);
for k=1:numel(keys)
    if ~isfield(config,keys{k}), error('SPP:Option','Unknown option %s',keys{k}); end
    config.(keys{k})=options.(keys{k});
end
validateattributes(config.maxEpochs,{'numeric'},{'scalar','positive','integer'});
validateattributes(config.elevationMaskDeg,{'numeric'},{'scalar','>=',0,'<',90});
validateattributes(config.maxEphemerisAgeSeconds,{'numeric'},{'scalar','positive','finite'});
mode=validatestring(config.ephemerisMode,{'broadcast','sp3'});
obs=readObservationFile(config.obsFile,config.maxEpochs);
if ~strcmp(obs.Header.timeSystem,'GPS'), error('SPP:TimeSystem','GPS solver requires observations in GPS time'); end
if isempty(obs.GPS), error('SPP:NoGPS','No GPS observations'); end
if strcmp(mode,'broadcast')
    nav=readNavRINEX3(config.navFile); nav=nav.GPS;
else
    [pos,~,id,t,clk]=readSP3(config.sp3File); sp3=struct('Position',pos,'ID',{id},'Time',t,'Clock',clk);
end
epochs=unique(obs.GPS.Time); n=numel(epochs); values=NaN(n,7); status=strings(n,1);
receiver=obs.Header.stationAPPR;
if numel(receiver)~=3 || any(~isfinite(receiver)), receiver=[0 0 0]; end
c=299792458; omega=7.2921151467e-5;
for k=1:n
    current=obs.GPS(obs.GPS.Time==epochs(k),:); [~,uniqueRows]=unique(current.SatNO,'stable'); current=current(uniqueRows,:);
    P=NaN(height(current),1);
    for code={'C1C','C1W','C1P','C1X','C1','P1'}
        if ismember(code{1},current.Properties.VariableNames)
            take=~isfinite(P) & isfinite(current.(code{1})); P(take)=current.(code{1})(take);
        end
    end
    try
        for outer=1:3
            xyz=NaN(height(current),3); clocks=NaN(height(current),1); correctedP=P;
            for j=1:height(current)
                if ~isfinite(P(j)) || P(j)<=1e6 || P(j)>=1e8, continue; end
                id=sprintf('G%02d',current.SatNO(j)); tau=P(j)/c;
                if strcmp(mode,'broadcast')
                    candidates=find(nav.SatelliteID==current.SatNO(j) & nav.SVHealth==0);
                    if isempty(candidates), continue; end
                    age=abs(seconds(epochs(k)-nav.Time(candidates))); [age,nearest]=min(age);
                    if age>config.maxEphemerisAgeSeconds, continue; end
                    eph=nav(candidates(nearest),:);
                end
                for travel=1:2
                    tx=epochs(k)-seconds(tau);
                    if strcmp(mode,'broadcast'), [sat,clock]=broadcastSatelliteState(eph,tx);
                    else
                        try, [sat,clock]=interpolateSP3(sp3,id,tx);
                        catch err
                            if strcmp(err.identifier,'SPP:SP3Coverage'), sat=[NaN NaN NaN]; clock=NaN; break; end
                            rethrow(err);
                        end
                    end
                    angle=omega*tau; rotated=[cos(angle)*sat(1)+sin(angle)*sat(2), -sin(angle)*sat(1)+cos(angle)*sat(2),sat(3)];
                    if norm(receiver)>1e6 && all(isfinite(rotated)), tau=norm(rotated-receiver)/c; end
                end
                if any(~isfinite(sat)), continue; end
                if norm(receiver)>1e6
                    [elev,heightM]=receiverElevation(receiver,rotated);
                    if elev<config.elevationMaskDeg, continue; end
                    if config.troposphereCorrection
                        % Nominal Saastamoinen atmosphere, not measured meteorology.
                        heightM=max(-100,min(10000,heightM)); pressure=1013.25*(1-2.2557e-5*heightM)^5.2568;
                        correctedP(j)=P(j)-0.002277*(pressure+1255/288.15*11.7+0.05*11.7)/sin(deg2rad(elev));
                    end
                end
                xyz(j,:)=rotated; clocks(j)=clock;
            end
            solved=solveSPPEpoch(correctedP,xyz,clocks,receiver); receiver=solved.Position;
        end
        values(k,:)=[receiver solved.ClockBiasSeconds solved.NumSatellites solved.ResidualRMS solved.PDOP]; status(k)="ok";
    catch err
        expected={'SPP:InsufficientSatellites','SPP:Geometry','SPP:Convergence'};
        if ~ismember(err.identifier,expected), rethrow(err); end
        status(k)=string(err.identifier); values(k,5)=0;
    end
end
result=array2table(values,'VariableNames',{'X','Y','Z','ClockBiasSeconds','NumSatellites','ResidualRMS','PDOP'});
result.Time=epochs; result.Status=status; result=movevars(result,'Time','Before',1);
if ~any(status=="ok"), error('SPP:NoSolution','No valid solution; check epoch coverage, GPS L1 codes and geometry'); end
if ~isempty(config.outputDir)
    if ~exist(config.outputDir,'dir'), mkdir(config.outputDir); end
    writetable(result,fullfile(config.outputDir,'positions.csv'));
    save(fullfile(config.outputDir,'results.mat'),'result','config');
    ok=status=="ok";
    summary=struct('ephemerisMode',mode,'epochs',n,'solvedEpochs',sum(ok), ...
        'medianResidualRMSMetres',median(result.ResidualRMS(ok)), ...
        'medianPDOP',median(result.PDOP(ok)),'referenceECEF',obs.Header.stationAPPR);
    fid=fopen(fullfile(config.outputDir,'summary.json'),'wt');
    if fid<0, error('SPP:Output','Cannot write summary'); end
    guard=onCleanup(@() fclose(fid)); fprintf(fid,'%s\n',jsonencode(summary)); clear guard;
    if config.makePlots
        f=figure('Visible','off'); guard=onCleanup(@() close(f));
        subplot(2,1,1); plot(result.Time,result.ResidualRMS); ylabel('Residual RMS (m)'); grid on;
        subplot(2,1,2); plot(result.Time,result.PDOP); ylabel('PDOP'); grid on;
        exportgraphics(f,fullfile(config.outputDir,'quality.png')); clear guard;
    end
end
end
function [elev,h]=receiverElevation(receiver,sat)
x=receiver(1); y=receiver(2); z=receiver(3); p=hypot(x,y); e2=6.69437999014e-3; a=6378137;
lat=atan2(z,p*(1-e2));
for k=1:8, N=a/sqrt(1-e2*sin(lat)^2); lat=atan2(z+e2*N*sin(lat),p); end
N=a/sqrt(1-e2*sin(lat)^2); h=p*cos(lat)+z*sin(lat)-a*sqrt(1-e2*sin(lat)^2);
lon=atan2(y,x); up=[cos(lat)*cos(lon),cos(lat)*sin(lon),sin(lat)]; d=sat-receiver;
elev=asind(max(-1,min(1,dot(d,up)/norm(d))));
end
