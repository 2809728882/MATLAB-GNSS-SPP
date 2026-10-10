function path=downloadNAV(url,outputDir)
%DOWNLOADNAV Explicit opt-in download; offline runs never fetch today's NAV.
% Supply a public HTTPS NAV/.gz URL covering the OBS date. No credentials stored.
if nargin<1 || ~startsWith(url,'https://'), error('SPP:DownloadURL','Supply an explicit HTTPS NAV URL'); end
if nargin<2, config=setting(); outputDir=config.filePath_N; end
if ~exist(outputDir,'dir'), mkdir(outputDir); end
[~,name,ext]=fileparts(url); path=fullfile(outputDir,[name ext]); websave(path,url);
if strcmpi(ext,'.gz'), files=gunzip(path,outputDir); path=files{1}; end
readNavhead(path); % Reject HTML/login pages masquerading as navigation files.
end
