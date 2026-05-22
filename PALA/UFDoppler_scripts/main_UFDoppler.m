clear
close all
clc

run("D:\GitProject\PALA\PALA\PALA_scripts\PALA_SetUpPaths.m")

%% Read and crop IQ files
Step001_crop_IQ

%% Create IQ batches
Step002_batch_IQ

%% Highpass filter
Step003_HPFilter

%% Demo + Determine the 1st image
DEMO_PowerDopplerOneCase

%% 
Step004_PowerDopplerVideo

%% Mean frequency array
Step005_MeanFrequency

%% Resistivity index post-processing
Step006_ResistivityIndex

%%
DEMO_PixelSpectrogram