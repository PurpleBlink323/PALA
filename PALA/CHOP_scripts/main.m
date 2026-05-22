clear
close all
clc

run("D:\GitProject\PALA\PALA\PALA_scripts\PALA_SetUpPaths.m")

%% Read and crop IQ files
Step001_crop_IQ

%% Create IQ batches
Step002_batch_IQ

%% Apply SVD 
Step003_SVDFilter

%% Localization
% Step004_localizationTracking
Step004_PALA_localization

%% Tracking
Step005_PALA_tracking

%% Visualization
Step006_PALA_rendering

%% Vascular and blood velocity maps
Step007_PALA_maps

%% Collect maps into baseline case
Step008_PALA_collectMaps
