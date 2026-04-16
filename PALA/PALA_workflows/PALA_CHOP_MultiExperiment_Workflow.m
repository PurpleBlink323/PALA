%% PALA_CHOP_MultiExperiment_Workflow.m
% Script-style batch workflow for multiple CHOP experiments.
% This workflow keeps the top-level orchestration as a script while reusing
% the existing processing code in sequence.

%% User-editable options
defaultRoot = 'D:\';
experimentDirs = {};
outputDir = '';
runPTVPreview = false;
runPTVFinalFigures = false;
promptForROI = true;
showVesselDiagnosticFigures = false;
summaryThresholdUm = 100;

%% Bootstrap
workflowPath = mfilename('fullpath');
if isempty(workflowPath)
    error('Run this script from its saved file so MATLAB can resolve project paths.');
end
workflowDir = fileparts(workflowPath);
projectRoot = fileparts(workflowDir);
addonsDir = fullfile(projectRoot, 'PALA_addons');
chopDir = fullfile(projectRoot, 'PALA_scripts', 'PALA_CHOP');
labChartDir = fullfile(projectRoot, 'PALA_scripts', 'LabChart_LoadData');
chopHelperDir = fullfile(chopDir, 'myFunction');

addpath(genpath(addonsDir));
addpath(chopDir);
addpath(labChartDir);
addpath(genpath(chopHelperDir));

%% Select experiments
experimentDirs = WF_ResolveExperimentDirs(experimentDirs, defaultRoot);
[experimentDirs, experimentLabels] = WF_ValidateExperimentDirs(experimentDirs);

if isempty(outputDir)
    runStamp = char(string(datetime('now', 'Format', 'yyyyMMdd_HHmmss')));
    outputDir = fullfile(workflowDir, 'Outputs', ['CHOP_MultiExperiment_' runStamp]);
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

fprintf('Selected %d experiment(s).\n', numel(experimentDirs));

%% Stage 1: batch PTV
ptvResults = repmat(struct(), numel(experimentDirs), 1);
for i = 1:numel(experimentDirs)
    fprintf('\n[%d/%d] Running PTV for %s\n', i, numel(experimentDirs), experimentLabels{i});
    ptvResults(i) = PALA_GEIC59D_PTV( ...
        experimentDirs{i}, ...
        'ShowPreview', logical(runPTVPreview), ...
        'ShowFinalFigures', logical(runPTVFinalFigures));
end
resultsDirs = arrayfun(@(s) s.ResultsDir, ptvResults, 'UniformOutput', false);

%% Stage 2: aggregate plot
fprintf('\nRendering aggregate CHOP plots...\n');
plotInfo = PALA_GEIC59D_Plot(resultsDirs, 'ResultLabels', experimentLabels);

%% Stage 3: shared LabChart loading
fprintf('\nLoading shared LabChart physiology...\n');
physiology = PALA_LoadLabChartPreExp('ExpectedWindows', numel(experimentDirs), 'DefaultRoot', defaultRoot);
if isempty(physiology.ICPChannelName)
    error('Could not identify an ICP channel from the shared LabChart dataset.');
end

%% Stage 4: per-experiment vessel analysis and summary persistence
vesselSummaries = repmat(struct(), numel(experimentDirs), 1);
for i = 1:numel(experimentDirs)
    fprintf('\n[%d/%d] Running vessel analysis for %s\n', i, numel(experimentDirs), experimentLabels{i});
    physiologyWindow = WF_BuildPhysiologyWindow(physiology, i);
    vesselSummaries(i) = PALA_GEIC59D_VesselDiameter( ...
        resultsDirs{i}, ...
        physiologyWindow, ...
        'PromptForROI', logical(promptForROI), ...
        'AutoLoadPhysiology', false, ...
        'ShowDiagnosticFigures', logical(showVesselDiagnosticFigures), ...
        'ShowAggregatePhysiologyPlots', false, ...
        'SaveSummary', true, ...
        'SummaryThresholdUm', summaryThresholdUm);
end

%% Stage 5: aggregate summaries
aggregateTable = WF_BuildAggregateTable(vesselSummaries, summaryThresholdUm);
aggregateMatPath = fullfile(outputDir, 'CHOP_Workflow_AggregateSummary.mat');
aggregateCsvPath = fullfile(outputDir, 'CHOP_Workflow_AggregateSummary.csv');
writetable(aggregateTable, aggregateCsvPath);

workflow = struct();
workflow.ExperimentDirs = experimentDirs;
workflow.ExperimentLabels = experimentLabels;
workflow.ResultsDirs = resultsDirs;
workflow.PTVResults = ptvResults;
workflow.PlotInfo = plotInfo;
workflow.PhysiologyLabChartFolder = physiology.LabChartFolder;
workflow.PhysiologyTimestampFile = physiology.TimestampFile;
workflow.ICPChannelName = physiology.ICPChannelName;
workflow.AggregateTable = aggregateTable;
workflow.PerExperimentSummaryMat = arrayfun(@(s) s.SummaryMatPath, vesselSummaries, 'UniformOutput', false);
workflow.PerExperimentSummaryCsv = arrayfun(@(s) s.SummaryCsvPath, vesselSummaries, 'UniformOutput', false);
save(aggregateMatPath, 'workflow');

fprintf('\nRendering aggregate physiology summary plots...\n');
WF_RenderAggregatePhysiologyPlots(aggregateTable, summaryThresholdUm);

fprintf('\nWorkflow complete.\n');
fprintf('Aggregate MAT: %s\n', aggregateMatPath);
fprintf('Aggregate CSV: %s\n', aggregateCsvPath);
