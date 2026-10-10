function info=filesParper(config)
%FILESPARPER Compatibility file check; absence is reported without dialogs.
info=struct('useobs',isfile(config.obsFile),'usenav',isfile(config.navFile), ...
    'usesp3',strcmp(config.ephemerisMode,'sp3') && isfile(config.sp3File));
if info.useobs, info.obsheadinfo=readOBShead(config.obsFile); else, info.obsheadinfo=[]; end
end
