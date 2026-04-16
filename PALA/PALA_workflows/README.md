# PALA Workflows

This directory contains high-level workflow entrypoints that orchestrate the
lower-level scripts under `PALA_scripts`.

Shared workflow helper functions live under
`PALA_addons/myFunction/Workflow`.

## CHOP batch workflow

- Entry point: `PALA_CHOP_MultiExperiment_Workflow.m`
- Input: multiple experiment folders selected in order
- Processing order:
  1. Run `PALA_GEIC59D_PTV` for each experiment
  2. Render batch plots with `PALA_GEIC59D_Plot`
  3. Load one shared LabChart pre/exp + timestamp dataset
  4. Map timestamp window `i` to experiment `i`
  5. Run `PALA_GEIC59D_VesselDiameter` per experiment
  6. Save per-experiment summaries and one aggregate summary

## Directory expectations

Each experiment folder must contain:

```text
<experiment>
  IQ/
    <single iq file>.mat
```

Processing outputs are written under:

```text
<experiment>
  Tracks/
  Results/
```

## Shared LabChart mapping

- A single LabChart `*_pre`/`*_exp` dataset is loaded once per workflow run.
- The timestamp file must contain exactly as many windows as selected experiments.
- The first selected experiment uses timestamp window 1, the second uses window 2, and so on.

## Saved outputs

- Per-experiment summaries are saved in each experiment's `Results` folder:
  - `<iqStem>_WorkflowSummary.mat`
  - `<iqStem>_WorkflowSummary.csv`
- Aggregate outputs are saved in a timestamped folder under `PALA_workflows/Outputs`:
  - `CHOP_Workflow_AggregateSummary.mat`
  - `CHOP_Workflow_AggregateSummary.csv`
