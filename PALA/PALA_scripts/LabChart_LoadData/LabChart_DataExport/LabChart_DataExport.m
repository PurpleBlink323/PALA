%% Setup Path
clc
addpath(genpath("D:\LabChart\adinstruments_sdk_matlab-master\adinstruments_sdk_matlab-master"));

%% Pick Labchart File
cd 
allfiles = uipickfiles('FilterSpec',defaultfilepath,...
    'Prompt','Step001: Select all the DICOM files to be processed',...
    'Output','struct');
currentfolder = allfiles(1).folder;
