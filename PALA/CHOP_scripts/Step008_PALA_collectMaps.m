function Step008_PALA_collectMaps
%%
close all
clc

% get data path
if exist('temp.mat','file')
    tempData = load('temp.mat','currentfolder');
    defaultfilepath = tempData.currentfolder;
else
    defaultfilepath = 'D:\VSX_Experiments\';
end
allfiles = uipickfiles('FilterSpec',defaultfilepath,...
    'Prompt','Step008: Select baseline case first, then all cases to collect',...
    'Output','struct');
currentfolder = allfiles(1).folder;

allimagepath = {allfiles.name}';
npath = length(allimagepath);

save('temp.mat','currentfolder','allimagepath','npath');

%% Collect vascular/blood velocity maps
Step008_SubStep001_CollectMaps

disp('All done!')

end
