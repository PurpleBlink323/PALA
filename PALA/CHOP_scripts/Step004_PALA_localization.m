function Step004_PALA_localization
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
    'Prompt','Step004: Select all the cases(folder) to be processed',...
    'Output','struct');
currentfolder = allfiles(1).folder;

allimagepath = {allfiles.name}';
npath = length(allimagepath);

save('temp.mat','currentfolder','allimagepath','npath');

%% Obtain best paras
Step004_SubStep001_TestLocalization

%% Do localization
Step004_SubStep002_DoLocalization

disp('All done!')

end
