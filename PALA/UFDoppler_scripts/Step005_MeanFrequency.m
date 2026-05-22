function Step005_MeanFrequency
%%
close all
clc

% get data path
if exist('temp.mat','file')
    tempData = load('temp.mat', 'currentfolder');
    if isfield(tempData, 'currentfolder')
        defaultfilepath = tempData.currentfolder;
    else
        defaultfilepath = 'D:\VSX_Experiments\';
    end
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
Step005_SubStep001_TestMeanFrequency

%% Create mean frequency array for all datasets
Step005_SubStep002_DoMeanFrequency

disp('All done!')
end
