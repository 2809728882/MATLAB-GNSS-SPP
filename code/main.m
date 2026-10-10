function result=main(options)
%MAIN Run the offline sample or pass options to RUNSPP. No clear-all or GUI.
% From the repository root: addpath('code'); result=main;
if nargin<1, options=struct(); end
result=runSPP(options);
fprintf('Solved %d / %d epochs.\n',sum(result.Status=="ok"),height(result));
end
