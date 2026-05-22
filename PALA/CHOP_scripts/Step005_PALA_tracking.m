function Step005_PALA_tracking
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
    'Prompt','Step005: Select all the cases(folder) to be processed',...
    'Output','struct');
currentfolder = allfiles(1).folder;

allimagepath = {allfiles.name}';
npath = length(allimagepath);

save('temp.mat','currentfolder','allimagepath','npath');

%% Obtain best paras
Step005_SubStep001_TestTracking

%% Do tracking
Step005_SubStep002_DoTracking

disp('All done!')

end
