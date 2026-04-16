function aggregateTable = WF_BuildAggregateTable(vesselSummaries, summaryThresholdUm)
n = numel(vesselSummaries);
experimentIndex = (1:n).';
experimentLabel = strings(n, 1);
experimentDir = strings(n, 1);
resultsDir = strings(n, 1);
iqStem = strings(n, 1);
summaryMatPath = strings(n, 1);
summaryCsvPath = strings(n, 1);
timestampIndex = zeros(n, 1);
AoP_Systolic = nan(n, 1);
AoP_Diastolic = nan(n, 1);
ICP = nan(n, 1);
MAP = nan(n, 1);
CPP = nan(n, 1);
CMC = nan(n, 1);
CMAC = nan(n, 1);
DensityMicro = nan(n, 1);
DensityMacro = nan(n, 1);
MeanVelMicro = nan(n, 1);
MeanVelMacro = nan(n, 1);
MeanDiaMicro = nan(n, 1);
MeanDiaMacro = nan(n, 1);

for i = 1:n
    s = vesselSummaries(i);
    experimentLabel(i) = string(s.ExperimentLabel);
    experimentDir(i) = string(s.ExperimentDir);
    resultsDir(i) = string(s.ResultsDir);
    iqStem(i) = string(s.IQStem);
    summaryMatPath(i) = string(s.SummaryMatPath);
    summaryCsvPath(i) = string(s.SummaryCsvPath);
    timestampIndex(i) = s.PhysiologyWindowIndex;
    AoP_Systolic(i) = s.AoP_Systolic;
    AoP_Diastolic(i) = s.AoP_Diastolic;
    ICP(i) = s.ICP;
    MAP(i) = s.MAP;
    CPP(i) = s.CPP;
    CMC(i) = s.SummaryRow.CMC;
    CMAC(i) = s.SummaryRow.CMAC;
    DensityMicro(i) = s.SummaryRow.DensityMicro;
    DensityMacro(i) = s.SummaryRow.DensityMacro;
    MeanVelMicro(i) = s.SummaryRow.MeanVelMicro;
    MeanVelMacro(i) = s.SummaryRow.MeanVelMacro;
    MeanDiaMicro(i) = s.SummaryRow.MeanDiaMicro;
    MeanDiaMacro(i) = s.SummaryRow.MeanDiaMacro;
end

aggregateTable = table( ...
    experimentIndex, experimentLabel, experimentDir, resultsDir, iqStem, ...
    summaryMatPath, summaryCsvPath, timestampIndex, ...
    repmat(summaryThresholdUm, n, 1), ...
    AoP_Systolic, AoP_Diastolic, ICP, MAP, CPP, ...
    CMC, CMAC, DensityMicro, DensityMacro, ...
    MeanVelMicro, MeanVelMacro, MeanDiaMicro, MeanDiaMacro, ...
    WF_SafeNormalize(CMC), WF_SafeNormalize(CMAC), ...
    WF_SafeNormalize(MeanVelMicro), WF_SafeNormalize(MeanVelMacro), ...
    'VariableNames', { ...
        'ExperimentIndex', 'ExperimentLabel', 'ExperimentDir', 'ResultsDir', 'IQStem', ...
        'SummaryMatPath', 'SummaryCsvPath', 'TimestampIndex', 'SummaryThresholdUm', ...
        'AoP_Systolic', 'AoP_Diastolic', 'ICP', 'MAP', 'CPP', ...
        'CMC', 'CMAC', 'DensityMicro', 'DensityMacro', ...
        'MeanVelMicro', 'MeanVelMacro', 'MeanDiaMicro', 'MeanDiaMacro', ...
        'CMC_Normalized', 'CMAC_Normalized', 'MeanVelMicro_Normalized', 'MeanVelMacro_Normalized'} ...
    );
