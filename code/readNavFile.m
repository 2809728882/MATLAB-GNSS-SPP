function out=readNavFile(config)
%READNAVFILE Load navigation files without GUI prompts.
if isfield(config,'navFile'), out={readNavRINEX3(config.navFile)}; return; end
files=dir(config.filePath_N); files=files(~[files.isdir]); out=cell(numel(files),1);
if isempty(files), error('SPP:NoNavigation','No navigation files found'); end
for k=1:numel(files), out{k}=readNavRINEX3(fullfile(config.filePath_N,files(k).name)); end
end
