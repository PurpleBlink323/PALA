# LabChart LoadData

This folder contains the LabChart physiology loader used by the CHOP workflow.

## Main entrypoints

- `PALA_LoadLabChartPreExp.m`: reusable function that loads `*_pre` and `*_exp` LabChart files, aligns them to a timestamp spreadsheet, and returns per-window physiology data.
- `LabChart_DataExport_PreExp.m`: interactive wrapper script that calls `PALA_LoadLabChartPreExp.m` and leaves the loaded variables in the MATLAB workspace.

## Required local contents

- `adinstruments_sdk_matlab-master/adinstruments_sdk_matlab-master/+adi`
- matching LabChart `*_pre.*` and `*_exp.*` files in the selected folder
- one timestamp spreadsheet (`.xlsx`, `.xls`, or `.csv`) describing the recording windows

## CHOP integration

`PALA_scripts/PALA_CHOP/PALA_GEIC59D_VesselDiameter.m` adds this folder to the MATLAB path and can call `PALA_LoadLabChartPreExp.m` automatically when physiology variables are missing.

The loader returns:

- `MeanTable`
- `Data`
- `AoP_Systolic`
- `AoP_Diastolic`
- `PulsePressure`
- `ICP` and the detected `ICPChannelName` when an ICP channel is found
