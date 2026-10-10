function tests=testSPP
tests=functiontests(localfunctions);
end
function setupOnce(testCase)
root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'code'));
testCase.TestData.root=root;
end
function testSyntheticPositionAndClock(testCase)
sat=[15600 7540 20140;18760 2750 18610;17610 14630 13480;19170 610 18390;-17800 15100 13900;13000 -21000 11000]*1000;
truth=[-2408698 4698106 3566697]; clocks=[1;-2;3;1;-1;2]*1e-5; bias=0.00012; c=299792458;
p=sqrt(sum((sat-truth).^2,2))+c*bias-c*clocks;
solution=solveSPPEpoch(p,sat,clocks);
verifyLessThan(testCase,norm(solution.Position-truth),1e-4);
verifyEqual(testCase,solution.ClockBiasSeconds,bias,'AbsTol',1e-12);
verifyLessThan(testCase,solution.ResidualRMS,1e-4);
end
function testSingularGeometry(testCase)
verifyError(testCase,@() solveSPPEpoch(ones(4,1)*2e7,repmat([2e7 0 0],4,1),zeros(4,1)), 'SPP:Geometry');
end
function testMissingDataRequiresFourSatellites(testCase)
verifyError(testCase,@() solveSPPEpoch([2e7;NaN;2e7;2e7],eye(4,3)*2e7,zeros(4,1)), 'SPP:InsufficientSatellites');
end
function testRinex3ContinuationAndEpochWithoutClock(testCase)
path=[tempname '.rnx']; cleanup=onCleanup(@() delete(path)); fid=fopen(path,'wt');
types={'C1C','L1C','D1C','S1C','C2W','L2W','D2W','S2W','C5X','L5X','D5X','S5X','C2X','L2X'};
header(fid,'     3.03           OBSERVATION DATA    M','RINEX VERSION / TYPE');
header(fid,['G   14 ' strjoin(types(1:13),' ')],'SYS / # / OBS TYPES');
header(fid,['       ' types{14}],'SYS / # / OBS TYPES');
header(fid,'R    1 C1C','SYS / # / OBS TYPES'); header(fid,'','END OF HEADER');
fprintf(fid,'> 2025 01 01 00 00 00.0000000  3  1\nEVENT RECORD\n');
fprintf(fid,'> 2025 01 01 00 00 01.0000000  0  3\n');
values=ones(1,14); values(1)=24000000; values(2)=NaN; data=obsLine(values);
fprintf(fid,'G01%s\n   %s\n',data(1:64),data(65:end));
fprintf(fid,'R01%s\n',obsLine(25000000)); fprintf(fid,'G02%s\n',obsLine(values+1)); fclose(fid);
obs=readObservationFile(path);
verifyEqual(testCase,height(obs.GPS),2); verifyEqual(testCase,height(obs.GLONASS),1);
verifyEqual(testCase,obs.GPS.C1C(1),24000000); verifyTrue(testCase,isnan(obs.GPS.L1C(1)));
verifyEqual(testCase,obs.GPS.SatNO,[1;2]); verifyEqual(testCase,numel(obs.Header.types.G),14);
end
function testRinex2SatelliteAndTypeContinuations(testCase)
path=[tempname '.25o']; cleanup=onCleanup(@() delete(path)); fid=fopen(path,'wt');
types={'C1','L1','P1','D1','S1','C2','L2','P2','D2','S2','C5'};
header(fid,'     2.11           OBSERVATION DATA    G','RINEX VERSION / TYPE');
header(fid,[sprintf('%6d',11) sprintf('%6s',types{1:9})],'# / TYPES OF OBSERV');
header(fid,[repmat(' ',1,6) sprintf('%6s',types{10:11})],'# / TYPES OF OBSERV'); header(fid,'','END OF HEADER');
ids=sprintf('G%02d',1:13);
fprintf(fid,' %02d%3d%3d%3d%3d%11.7f%3d%3d%s\n',25,1,1,0,0,0,0,13,ids(1:36));
fprintf(fid,'%s%s\n',repmat(' ',1,32),ids(37:end));
for k=1:13
    values=ones(1,11)*k; values(1)=24000000+k; values(3)=NaN; text=obsLine(values);
    fprintf(fid,'%s\n%s\n%s\n',text(1:80),text(81:160),text(161:end));
end
fclose(fid); obs=readObservationFile(path,1);
verifyEqual(testCase,height(obs.GPS),13); verifyEqual(testCase,obs.GPS.SatNO,(1:13)');
verifyEqual(testCase,obs.GPS.C1(13),24000013); verifyTrue(testCase,all(isnan(obs.GPS.P1)));
verifyEqual(testCase,obs.GPS.Time(1),datetime(2025,1,1),'AbsTol',seconds(1e-4));
end
function testMalformedHeaderStopsAtEOF(testCase)
path=[tempname '.rnx']; cleanup=onCleanup(@() delete(path)); fid=fopen(path,'wt');
header(fid,'     3.03           OBSERVATION DATA    G','RINEX VERSION / TYPE'); fclose(fid);
verifyError(testCase,@() readOBShead(path),'SPP:Header');
end
function testSP3UnitsRealTimesAndSameSatelliteVelocity(testCase)
path=[tempname '.sp3']; cleanup=onCleanup(@() delete(path)); fid=fopen(path,'wt');
for t=[0 30 90]
    fprintf(fid,'*  2025 01 01 00 %02d %11.8f\n',floor(t/60),mod(t,60));
    fprintf(fid,'PG01%14.6f%14.6f%14.6f%14.6f\n',20000+t*.01,10000,12000,100);
    fprintf(fid,'PG02%14.6f%14.6f%14.6f%14.6f\n',-20000,15000-t*.02,18000,999999.999999);
end
fclose(fid); [pos,vel,ids,times,clocks]=readSP3(path);
verifyEqual(testCase,pos(1,:),[20000000 10000000 12000000]);
verifyEqual(testCase,vel(3,:),[10 0 0],'AbsTol',1e-4);
verifyEqual(testCase,vel(4,:),[0 -20 0],'AbsTol',1e-4);
verifyEqual(testCase,seconds(times(5)-times(1)),90,'AbsTol',1e-4);
verifyEqual(testCase,clocks(1),1e-4,'AbsTol',1e-15); verifyTrue(testCase,isnan(clocks(2)));
verifyEqual(testCase,ids{4},'G02');
end
function testSP3InterpolationAndCoverage(testCase)
t=(-4:4)'*900; epoch=datetime(2025,1,1,12,0,0);
s=struct('Time',epoch+seconds(t),'ID',{repmat({'G01'},9,1)}, ...
    'Position',[2e7+10*t+.001*t.^2 1e7+5*t 1.5e7-2*t], 'Clock',1e-4+t*1e-10);
[pos,clock]=interpolateSP3(s,'G01',epoch+seconds(123));
verifyEqual(testCase,pos,[2e7+1230+.001*123^2 1e7+615 1.5e7-246],'AbsTol',1e-6);
verifyEqual(testCase,clock,1e-4+123e-10,'AbsTol',1e-14);
verifyError(testCase,@() interpolateSP3(s,'G01',epoch+seconds(4000)),'SPP:SP3Coverage');
end
function testBroadcastCircularOrbitAndClock(testCase)
nav=readNavRINEX3(fullfile(testCase.TestData.root,'data','nav','brdm0870.19p')); eph=nav.GPS(1,:);
for name={'Crs','Crc','Cus','Cuc','Cis','Cic','i0','IDOT','M0','omega','OMEGA0','OMEGA_DOT','Eccentricity','Delta_n','Toe','SVClockDrift','SVClockDriftRate'}
    eph.(name{1})=0;
end
eph.GPS_Week=2000; eph.Time=datetime(1980,1,6)+seconds(2000*604800); eph.SVClockBias=1e-4; eph.TGD=5e-9;
[pos,clock]=broadcastSatelliteState(eph,eph.Time);
verifyEqual(testCase,pos,[eph.sqrtA^2 0 0],'AbsTol',1e-6);
verifyEqual(testCase,clock,1e-4-5e-9,'AbsTol',1e-15);
end
function testBundledRinex2Sample(testCase)
obs=readObservationFile(fullfile(testCase.TestData.root,'rinex2.11','bjfs0010.25o'),2);
verifyGreaterThan(testCase,height(obs.GPS),0); verifyGreaterThan(testCase,height(obs.GLONASS),0);
verifyEqual(testCase,numel(unique(obs.GPS.Time)),2); verifyTrue(testCase,ismember('C1',obs.GPS.Properties.VariableNames));
end
function testBundledBroadcastPipeline(testCase)
result=runSPP(struct('maxEpochs',5,'outputDir','','makePlots',false));
verifyTrue(testCase,all(result.Status=="ok")); verifyEqual(testCase,height(result),5);
ref=[-2408698.4833 4698106.5529 3566697.2077];
verifyLessThan(testCase,max(vecnorm([result.X result.Y result.Z]-ref,2,2)),100);
end
function testBundledSP3Pipeline(testCase)
result=runSPP(struct('maxEpochs',5,'ephemerisMode','sp3','outputDir','','makePlots',false));
verifyTrue(testCase,all(result.Status=="ok"));
ref=[-2408698.4833 4698106.5529 3566697.2077];
verifyLessThan(testCase,max(vecnorm([result.X result.Y result.Z]-ref,2,2)),100);
end
function header(fid,body,label)
assert(length(body)<=60); fprintf(fid,'%-60s%-20s\n',body,label);
end
function text=obsLine(values)
text='';
for v=values
    if isnan(v), field=[repmat(' ',1,14) '12']; else, field=sprintf('%14.3f12',v); end
    text=[text field]; %#ok<AGROW>
end
end
