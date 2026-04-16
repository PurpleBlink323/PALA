%% LabChart_DataExport_PreExp.m
% Interactive wrapper that loads pre/exp physiology data and leaves the
% results in the MATLAB workspace for downstream CHOP analysis.

clc
physiology = PALA_LoadLabChartPreExp();

MeanTable = physiology.MeanTable;
Data = physiology.Data;
AoP_Systolic = physiology.AoP_Systolic;
AoP_Diastolic = physiology.AoP_Diastolic;
AoP_PulsePressure = physiology.PulsePressure;

if ~isempty(physiology.ICP)
    ICP = physiology.ICP;
end

fprintf('Loaded %d physiology windows from %s\n', height(MeanTable), physiology.LabChartFolder);
if ~isempty(physiology.ICPChannelName)
    fprintf('Using ICP channel: %s\n', physiology.ICPChannelName);
else
    fprintf('No ICP channel was identified automatically.\n');
end
