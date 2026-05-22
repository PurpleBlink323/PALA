function Step004_PowerDopplerVideo
%%
close all
clc

% get data path
if exist('temp.mat','file')
    load('temp.mat')
    defaultfilepath = currentfolder;
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
Step004_SubStep001_TestPowerDopplerVideo

%% Create power Doppler video for all datasets
Step004_SubStep002_DoPowerDopplerVideo

disp('All done!')
end
