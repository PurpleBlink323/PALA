# CHOP Workflow

This folder contains the CHOP-specific MATLAB scripts integrated into the PALA project.

Supported entrypoints:

- `PALA_GEIC59D_PTV.m`: interactive processing workflow for one CHOP experiment folder.
- `PALA_GEIC59D_Plot.m`: interactive plotting workflow for saved CHOP `MatOut` results.
- `PALA_GEIC59D_VesselDiameter.m`: interactive ROI-based vessel segmentation and diameter workflow.

## Helper layout

- Project-wide helpers come from `PALA_addons`, including `blockwiseSVDfilter` and `myEngImg`.
- Workflow-shared helpers now live in `PALA_addons/myFunction/Workflow`.
- CHOP-local helpers stay in `PALA_scripts/PALA_CHOP/myFunction`, including `uipickfiles` and the vesselness package.
- The CHOP scripts add their local helper folder explicitly so they can be launched from `PALA_CHOP` without depending on the current MATLAB folder.

## Expected input layout

`PALA_GEIC59D_PTV.m` expects an experiment folder with this structure:

```text
<experiment>
  IQ/
    <single iq file>.mat
```

It writes outputs to:

```text
<experiment>
  Tracks/
  Results/
```

`PALA_GEIC59D_Plot.m` and `PALA_GEIC59D_VesselDiameter.m` expect you to select experiment folders that contain a `Results` subfolder with one `*_multi.mat` file, or to select the `Results` folder directly.

## Manual edits

- `PALA_GEIC59D_Plot.m` keeps CHOP-specific title examples near the top of the script in editable config blocks.
- `PALA_GEIC59D_VesselDiameter.m` now tries to load LabChart physiology automatically from `PALA_scripts/LabChart_LoadData` when `AoP_Systolic`, `AoP_Diastolic`, and `ICP` are not already in the workspace.
- If automatic LabChart loading is not wanted, set `autoLoadPhysiology = false` near the top of `PALA_GEIC59D_VesselDiameter.m`.
