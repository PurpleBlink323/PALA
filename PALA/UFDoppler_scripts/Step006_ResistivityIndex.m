function Step006_ResistivityIndex
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
    'Prompt','Step006: Select all the cases(folder) for RI post-processing',...
    'Output','struct');
currentfolder = allfiles(1).folder;

allimagepath = {allfiles.name}';
npath = length(allimagepath);

save('temp.mat','currentfolder','allimagepath','npath');

%% Tune vessel binarization threshold
Step006_SubStep001_TestVesselMask

%% Create RI maps from mean frequency arrays
Step006_SubStep002_CreateResistivityIndex

disp('All done!')
end
