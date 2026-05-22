function Step007_PALA_maps
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
    'Prompt','Step007: Select all the cases(folder) to be processed',...
    'Output','struct');
currentfolder = allfiles(1).folder;

allimagepath = {allfiles.name}';
npath = length(allimagepath);

save('temp.mat','currentfolder','allimagepath','npath');

%% Save vascular/blood velocity map
Step007_SubStep001_CreateMaps

disp('All done!')

end
