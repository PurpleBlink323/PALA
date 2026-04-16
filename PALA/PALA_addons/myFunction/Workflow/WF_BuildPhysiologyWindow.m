function physiologyWindow = WF_BuildPhysiologyWindow(physiology, idx)
physiologyWindow = struct();
physiologyWindow.WindowIndex = idx;
physiologyWindow.AoP_Systolic = physiology.AoP_Systolic(idx);
physiologyWindow.AoP_Diastolic = physiology.AoP_Diastolic(idx);
physiologyWindow.ICP = physiology.ICP(idx);
physiologyWindow.Source = physiology.LabChartFolder;
if isfield(physiology, 'WindowTable') && height(physiology.WindowTable) >= idx
    physiologyWindow.WindowTableRow = physiology.WindowTable(idx, :);
end
