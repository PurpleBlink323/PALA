function summary = PALA_GEIC59D_VesselDiameter(resultDirs, physiologyInput, varargin)
%PALA_GEIC59D_VESSELDIAMETER Compute vessel diameter metrics for CHOP results.
%   summary = PALA_GEIC59D_VesselDiameter() interactively selects one or
%   more result folders.
%   summary = PALA_GEIC59D_VesselDiameter(resultDir, physiologyWindow)
%   analyzes a single result folder with the supplied physiology window.

if nargin < 1
    resultDirs = [];
end
if nargin < 2
    physiologyInput = [];
end

parser = inputParser;
parser.addParameter('DefaultFilePath', 'D:\', @(x) ischar(x) || isstring(x));
parser.addParameter('VelocityDisplayLimit', 5, @(x) isnumeric(x) && isscalar(x) && x > 0);
parser.addParameter('WavelengthScaleCmPerS', 1540 / 5.6818 * 1e-3 / 10, @(x) isnumeric(x) && isscalar(x) && x > 0);
parser.addParameter('DxUm', 16, @(x) isnumeric(x) && isscalar(x) && x > 0);
parser.addParameter('DList', 80:200, @(x) isnumeric(x) && isvector(x) && ~isempty(x));
parser.addParameter('DCheck', 100, @(x) isnumeric(x) && isscalar(x));
parser.addParameter('SummaryThresholdUm', 100, @(x) isnumeric(x) && isscalar(x));
parser.addParameter('AutoLoadPhysiology', true, @(x) islogical(x) || isnumeric(x));
parser.addParameter('PromptForROI', true, @(x) islogical(x) || isnumeric(x));
parser.addParameter('ROIMasks', {}, @(x) iscell(x) || islogical(x));
parser.addParameter('ShowDiagnosticFigures', true, @(x) islogical(x) || isnumeric(x));
parser.addParameter('ShowAggregatePhysiologyPlots', true, @(x) islogical(x) || isnumeric(x));
parser.addParameter('SaveSummary', false, @(x) islogical(x) || isnumeric(x));
parser.addParameter('OutputDir', '', @(x) ischar(x) || isstring(x));
parser.parse(varargin{:});
opts = parser.Results;

%% Bootstrap
scriptPath = mfilename('fullpath');
if isempty(scriptPath)
    error('Run this function from its saved file so MATLAB can resolve the CHOP helper paths.');
end
scriptDir = fileparts(scriptPath);
projectScriptsDir = fileparts(scriptDir);
projectRoot = fileparts(projectScriptsDir);
addonsDir = fullfile(projectRoot, 'PALA_addons');
labChartDir = fullfile(projectScriptsDir, 'LabChart_LoadData');
addpath(genpath(addonsDir));
addpath(genpath(fullfile(scriptDir, 'myFunction')));
if isfolder(labChartDir)
    addpath(labChartDir);
end

%% Resolve result directories
resultDirs = iResolveResultDirs(resultDirs, opts.DefaultFilePath);
filesnum = numel(resultDirs);

[Matout_Cell, MatOut_Vel_Cell, matoutFiles, experimentLabels, iqStems] = iLoadMatOuts(resultDirs);
roiMask = iResolveRoiMasks(MatOut_Vel_Cell, experimentLabels, opts);
physiology = iResolvePhysiology(physiologyInput, filesnum, opts);

%% Vesselness filter and diameter analysis
D_list = opts.DList(:).';
nD = numel(D_list);
wv = opts.WavelengthScaleCmPerS;

vel_sum_all = zeros(filesnum, nD);
micro_sum_all = zeros(filesnum, nD);
area_sum_all = zeros(filesnum, nD);
CMC_all = zeros(filesnum, nD);
Density_all = zeros(filesnum, nD);
diameter_fill_um_all = cell(filesnum, 1);
CMAC_all = zeros(filesnum, nD);
macro_sum_all = zeros(filesnum, nD);
vel_sum_macro = zeros(filesnum, nD);
Density_macro_all = zeros(filesnum, nD);
V0_all = cell(filesnum, 1);
BW_micro_all = cell(filesnum, nD);
BW_macro_all = cell(filesnum, nD);
Vmicro_all = cell(filesnum, nD);
Vmacro_all = cell(filesnum, nD);
MeanVel_micro_all = zeros(filesnum, nD);
MeanVel_macro_all = zeros(filesnum, nD);
MeanDia_micro_all = zeros(filesnum, nD);
MeanDia_macro_all = zeros(filesnum, nD);

for i = 1:filesnum
    I = double(Matout_Cell{i});
    I = I - min(I(:));
    if max(I(:)) > 0
        I = I ./ max(I(:));
    end

    I_smooth = imgaussfilt(I, 1);
    I_enh = adapthisteq(I_smooth, 'NumTiles', [8 8], 'ClipLimit', 0.01);

    Ip = single(I_enh);
    if any(Ip(:) > 0)
        thr = prctile(Ip(Ip(:) > 0), 0.99);
        Ip(Ip <= thr) = thr;
    end
    Ip = Ip - min(Ip(:));
    if max(Ip(:)) > 0
        Ip = Ip ./ max(Ip(:));
    end

    V_extract = vesselness2D(Ip, 1:0.25:6, [1, 1], 1, true);
    BW = imbinarize(V_extract, 'adaptive', 'Sensitivity', 0.5);

    Skel = bwskel(BW);
    Dmap = bwdist(~BW);
    diameter_map = 2 * Dmap .* Skel;
    diameter_map_um = diameter_map * opts.DxUm;

    [~, idxNearestSkel] = bwdist(Skel);
    diameter_fill_um = diameter_map_um(idxNearestSkel);
    diameter_fill_um(~BW) = 0;
    diameter_fill_um_all{i} = diameter_fill_um;

    V0 = double(MatOut_Vel_Cell{i}) .* wv;
    V0(~isfinite(V0)) = 0;
    V0(V0 < 0) = 0;
    V0_all{i} = V0;

    for k = 1:nD
        Dth = D_list(k);
        BW_small = (diameter_fill_um > 0) & (diameter_fill_um < Dth);
        BW_large = diameter_fill_um >= Dth;

        BW_small = bwareaopen(BW_small, 10);
        BW_large = bwareaopen(BW_large, 10);

        BW_micro_all{i, k} = BW_small;
        BW_macro_all{i, k} = BW_large;

        V_small = V0 .* BW_small;
        V_large = V0 .* BW_large;
        Vmicro_all{i, k} = V_small;
        Vmacro_all{i, k} = V_large;

        Vroi_small = V_small(roiMask{i});
        BWroi_small = BW_small(roiMask{i});
        vel_sum_all(i, k) = sum(Vroi_small(:));
        micro_sum_all(i, k) = nnz(BWroi_small);
        area_sum_all(i, k) = numel(BWroi_small);

        if area_sum_all(i, k) > 0
            CMC_all(i, k) = vel_sum_all(i, k) / area_sum_all(i, k);
            Density_all(i, k) = micro_sum_all(i, k) / area_sum_all(i, k);
        end
        if micro_sum_all(i, k) > 0
            MeanVel_micro_all(i, k) = vel_sum_all(i, k) / micro_sum_all(i, k);
        end

        Droi = diameter_fill_um(roiMask{i});
        Droi_micro = Droi(BWroi_small);
        if ~isempty(Droi_micro)
            MeanDia_micro_all(i, k) = mean(Droi_micro);
        end

        Vroi_large = V_large(roiMask{i});
        BWroi_large = BW_large(roiMask{i});
        vel_sum_macro(i, k) = sum(Vroi_large(:));
        macro_sum_all(i, k) = nnz(BWroi_large);

        if area_sum_all(i, k) > 0
            CMAC_all(i, k) = vel_sum_macro(i, k) / area_sum_all(i, k);
            Density_macro_all(i, k) = macro_sum_all(i, k) / area_sum_all(i, k);
        end
        if macro_sum_all(i, k) > 0
            MeanVel_macro_all(i, k) = vel_sum_macro(i, k) / macro_sum_all(i, k);
        end

        Droi_macro = Droi(BWroi_large);
        if ~isempty(Droi_macro)
            MeanDia_macro_all(i, k) = mean(Droi_macro);
        end
    end
end

%% Build summaries
[~, summaryIdx] = min(abs(D_list - opts.SummaryThresholdUm));
summary = repmat(struct(), filesnum, 1);
for i = 1:filesnum
    metricsTable = table( ...
        D_list(:), ...
        CMC_all(i, :).', ...
        CMAC_all(i, :).', ...
        Density_all(i, :).', ...
        Density_macro_all(i, :).', ...
        MeanVel_micro_all(i, :).', ...
        MeanVel_macro_all(i, :).', ...
        MeanDia_micro_all(i, :).', ...
        MeanDia_macro_all(i, :).', ...
        'VariableNames', { ...
            'D_threshold_um', 'CMC', 'CMAC', 'DensityMicro', 'DensityMacro', ...
            'MeanVelMicro', 'MeanVelMacro', 'MeanDiaMicro', 'MeanDiaMacro'} ...
        );

    [mapValue, cppValue] = WF_ComputeMapCpp(physiology.AoP_Systolic(i), physiology.AoP_Diastolic(i), physiology.ICP(i));
    selectedRow = metricsTable(summaryIdx, :);
    selectedRow.AoP_Systolic = physiology.AoP_Systolic(i);
    selectedRow.AoP_Diastolic = physiology.AoP_Diastolic(i);
    selectedRow.ICP = physiology.ICP(i);
    selectedRow.MAP = mapValue;
    selectedRow.CPP = cppValue;

    summary(i).ExperimentIndex = i;
    summary(i).ExperimentLabel = experimentLabels{i};
    summary(i).ExperimentDir = fileparts(resultDirs{i});
    summary(i).ResultsDir = resultDirs{i};
    summary(i).MatOutFile = matoutFiles{i};
    summary(i).IQStem = iqStems{i};
    summary(i).MetricsTable = metricsTable;
    summary(i).SummaryThresholdUm = D_list(summaryIdx);
    summary(i).SummaryRow = selectedRow;
    summary(i).AoP_Systolic = physiology.AoP_Systolic(i);
    summary(i).AoP_Diastolic = physiology.AoP_Diastolic(i);
    summary(i).ICP = physiology.ICP(i);
    summary(i).MAP = mapValue;
    summary(i).CPP = cppValue;
    summary(i).PhysiologySource = physiology.Source;
    summary(i).PhysiologyWindowIndex = physiology.WindowIndex(i);
    summary(i).ROI = roiMask{i};
    summary(i).DiameterFillUm = diameter_fill_um_all{i};
    summary(i).VelocityMap = V0_all{i};
    summary(i).SelectedMicroMask = BW_micro_all{i, summaryIdx};
    summary(i).SelectedMacroMask = BW_macro_all{i, summaryIdx};
    summary(i).SelectedMicroVelocity = Vmicro_all{i, summaryIdx};
    summary(i).SelectedMacroVelocity = Vmacro_all{i, summaryIdx};
    summary(i).SummaryMatPath = '';
    summary(i).SummaryCsvPath = '';

    if logical(opts.SaveSummary)
        outputDir = char(string(opts.OutputDir));
        if isempty(outputDir)
            outputDir = resultDirs{i};
        end
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        summaryMatPath = fullfile(outputDir, [iqStems{i} '_WorkflowSummary.mat']);
        summaryCsvPath = fullfile(outputDir, [iqStems{i} '_WorkflowSummary.csv']);
        csvTable = metricsTable;
        csvTable.ExperimentLabel = repmat(string(experimentLabels{i}), height(csvTable), 1);
        csvTable.AoP_Systolic = repmat(physiology.AoP_Systolic(i), height(csvTable), 1);
        csvTable.AoP_Diastolic = repmat(physiology.AoP_Diastolic(i), height(csvTable), 1);
        csvTable.ICP = repmat(physiology.ICP(i), height(csvTable), 1);
        csvTable.MAP = repmat(mapValue, height(csvTable), 1);
        csvTable.CPP = repmat(cppValue, height(csvTable), 1);
        csvTable.PhysiologyWindowIndex = repmat(physiology.WindowIndex(i), height(csvTable), 1);

        summary(i).SummaryMatPath = summaryMatPath;
        summary(i).SummaryCsvPath = summaryCsvPath;
        summary_i = summary(i);
        roi_i = roiMask{i};
        diameter_fill_um_i = diameter_fill_um_all{i};
        save(summaryMatPath, 'summary_i', 'csvTable', 'roi_i', 'diameter_fill_um_i');
        writetable(csvTable, summaryCsvPath);
    end
end

%% Diagnostic figures
if logical(opts.ShowDiagnosticFigures)
    [~, kCheck] = min(abs(D_list - opts.DCheck));
    for i = 1:filesnum
        iRenderDiagnosticMaps(Vmicro_all{i, kCheck}, Vmacro_all{i, kCheck}, experimentLabels{i}, D_list(kCheck));
    end
end

if logical(opts.ShowAggregatePhysiologyPlots) && filesnum > 1 && all(isfinite([summary.CPP]))
    iRenderAggregatePhysiologyPlots(summary);
end

if isscalar(summary)
    summary = summary(1);
end
end

function resultDirs = iResolveResultDirs(resultDirs, defaultFilePath)
if isempty(resultDirs)
    allfiles = uipickfiles( ...
        'FilterSpec', char(string(defaultFilePath)), ...
        'Prompt', 'Pick the result folders', ...
        'Output', 'struct');
    if isempty(allfiles)
        error('No folders selected.');
    end

    resultDirs = cell(numel(allfiles), 1);
    for i = 1:numel(allfiles)
        selectedPath = WF_ResolveSelectedFolder(allfiles(i));
        resultDirs{i} = WF_ResolveResultsFolder(selectedPath);
    end
elseif ischar(resultDirs) || isstring(resultDirs)
    resultDirs = cellstr(string(resultDirs(:)));
elseif iscell(resultDirs)
    resultDirs = cellfun(@(x) char(string(x)), resultDirs(:), 'UniformOutput', false);
else
    error('Unsupported input for resultDirs.');
end
end

function [Matout_Cell, MatOut_Vel_Cell, matoutFiles, experimentLabels, iqStems] = iLoadMatOuts(resultDirs)
filesnum = numel(resultDirs);
Matout_Cell = cell(filesnum, 1);
MatOut_Vel_Cell = cell(filesnum, 1);
matoutFiles = cell(filesnum, 1);
experimentLabels = cell(filesnum, 1);
iqStems = cell(filesnum, 1);

for i = 1:filesnum
    resultDirs{i} = WF_ResolveResultsFolder(resultDirs{i});
    matoutfiles = dir(fullfile(resultDirs{i}, '*_multi.mat'));
    matoutfiles = matoutfiles(~[matoutfiles.isdir]);
    if isempty(matoutfiles)
        error('No *_multi.mat file found in %s.', resultDirs{i});
    elseif numel(matoutfiles) > 1
        error('More than one *_multi.mat file found in %s. Select folders with a single CHOP result.', resultDirs{i});
    end

    matoutFiles{i} = fullfile(matoutfiles(1).folder, matoutfiles(1).name);
    S = load(matoutFiles{i}, 'MatOut', 'MatOut_vel');
    Matout_Cell{i} = S.MatOut{1};
    MatOut_Vel_Cell{i} = S.MatOut_vel{1};
    experimentLabels{i} = WF_LabelFromResultDir(resultDirs{i});
    iqStems{i} = WF_DetectIqStem(matoutfiles(1).name);
end
end

function roiMask = iResolveRoiMasks(MatOut_Vel_Cell, experimentLabels, opts)
filesnum = numel(MatOut_Vel_Cell);
roiMask = cell(filesnum, 1);

providedMasks = opts.ROIMasks;
if islogical(providedMasks)
    providedMasks = {providedMasks};
end
if ~isempty(providedMasks)
    if numel(providedMasks) ~= filesnum
        error('ROIMasks must provide one mask per result.');
    end
    for i = 1:filesnum
        roiMask{i} = logical(providedMasks{i});
    end
    return
end

for i = 1:filesnum
    if logical(opts.PromptForROI)
        V0 = double(MatOut_Vel_Cell{i}) .* opts.WavelengthScaleCmPerS;
        V0(~isfinite(V0)) = 0;
        V0(V0 < 0) = 0;
        V0 = imgaussfilt(V0, 0.6);
        V0disp = min(V0, opts.VelocityDisplayLimit);

        cmap = jet(256);
        cmap(1, :) = [0 0 0];

        figure;
        clf
        imagesc(V0disp, [0 opts.VelocityDisplayLimit]);
        axis image off
        colormap(cmap);
        title(sprintf('Draw polygon ROI for %s and double-click', experimentLabels{i}), 'Interpreter', 'none');

        h = drawpolygon('Color', 'w');
        roiMask{i} = createMask(h);
    else
        roiMask{i} = true(size(MatOut_Vel_Cell{i}));
    end
end
end

function physiology = iResolvePhysiology(physiologyInput, filesnum, opts)
physiology = struct();
physiology.AoP_Systolic = nan(filesnum, 1);
physiology.AoP_Diastolic = nan(filesnum, 1);
physiology.ICP = nan(filesnum, 1);
physiology.WindowIndex = (1:filesnum).';
physiology.Source = 'none';

if isempty(physiologyInput)
    if logical(opts.AutoLoadPhysiology) && exist('PALA_LoadLabChartPreExp', 'file') == 2
        physiologyLoaded = PALA_LoadLabChartPreExp('ExpectedWindows', filesnum, 'DefaultRoot', opts.DefaultFilePath);
        physiology = iConvertPhysiologyStruct(physiologyLoaded, filesnum);
    end
    return
end

if isstruct(physiologyInput) && isscalar(physiologyInput)
    physiology = iConvertPhysiologyStruct(physiologyInput, filesnum);
    return
end

if isstruct(physiologyInput) && numel(physiologyInput) == filesnum
    for i = 1:filesnum
        physiology.AoP_Systolic(i) = iFieldOrNaN(physiologyInput(i), 'AoP_Systolic');
        physiology.AoP_Diastolic(i) = iFieldOrNaN(physiologyInput(i), 'AoP_Diastolic');
        physiology.ICP(i) = iFieldOrNaN(physiologyInput(i), 'ICP');
        if isfield(physiologyInput(i), 'WindowIndex')
            physiology.WindowIndex(i) = physiologyInput(i).WindowIndex;
        end
    end
    physiology.Source = 'provided';
    return
end

error('Unsupported physiologyInput. Provide a loader struct or one scalar struct per result.');
end

function physiology = iConvertPhysiologyStruct(source, filesnum)
physiology = struct();
physiology.AoP_Systolic = iResolveFieldVector(source, 'AoP_Systolic', filesnum);
physiology.AoP_Diastolic = iResolveFieldVector(source, 'AoP_Diastolic', filesnum);
physiology.ICP = iResolveFieldVector(source, 'ICP', filesnum);
if isfield(source, 'WindowIndex')
    physiology.WindowIndex = iResolveFieldVector(source, 'WindowIndex', filesnum);
else
    physiology.WindowIndex = (1:filesnum).';
end
if isfield(source, 'Source')
    physiology.Source = char(string(source.Source));
elseif isfield(source, 'LabChartFolder')
    physiology.Source = char(string(source.LabChartFolder));
else
    physiology.Source = 'provided';
end
end

function values = iResolveFieldVector(source, fieldName, filesnum)
values = nan(filesnum, 1);
if ~isfield(source, fieldName)
    return
end

fieldValue = source.(fieldName);
if isnumeric(fieldValue)
    fieldValue = fieldValue(:);
elseif islogical(fieldValue)
    fieldValue = double(fieldValue(:));
else
    error('Unsupported field type for %s.', fieldName);
end

if isscalar(fieldValue) && filesnum == 1
    values = fieldValue;
elseif numel(fieldValue) == filesnum
    values = fieldValue;
else
    error('%s must contain %d value(s).', fieldName, filesnum);
end
end

function value = iFieldOrNaN(S, fieldName)
if isfield(S, fieldName)
    value = double(S.(fieldName));
else
    value = nan;
end
end

function iRenderDiagnosticMaps(Vmicro, Vmacro, experimentLabel, dCheck)
vmax = max([Vmicro(:); Vmacro(:)]);
if vmax <= 0 || ~isfinite(vmax)
    vmax = 1;
end

cmap = jet(256);
cmap(1, :) = [0 0 0];

fig1 = figure('Color', 'k', 'Name', sprintf('%s Micro D<%d', experimentLabel, round(dCheck)));
subplot(1, 2, 1);
imagesc(Vmicro);
axis image off;
clim([0 vmax]);
title(sprintf('%s micro < %d um', experimentLabel, round(dCheck)), 'Color', 'w', 'Interpreter', 'none');
colormap(fig1, cmap);
cb1 = colorbar;
cb1.Color = 'w';
cb1.Label.String = 'Velocity';
cb1.Label.Color = 'w';

subplot(1, 2, 2);
imagesc(Vmacro);
axis image off;
clim([0 vmax]);
title(sprintf('%s macro >= %d um', experimentLabel, round(dCheck)), 'Color', 'w', 'Interpreter', 'none');
colormap(fig1, cmap);
cb2 = colorbar;
cb2.Color = 'w';
cb2.Label.String = 'Velocity';
cb2.Label.Color = 'w';
end

function iRenderAggregatePhysiologyPlots(summary)
cpp = [summary.CPP].';
cmc = arrayfun(@(s) s.SummaryRow.CMC, summary).';
cmac = arrayfun(@(s) s.SummaryRow.CMAC, summary).';
densityMicro = arrayfun(@(s) s.SummaryRow.DensityMicro, summary).';
densityMacro = arrayfun(@(s) s.SummaryRow.DensityMacro, summary).';
meanVelMicro = arrayfun(@(s) s.SummaryRow.MeanVelMicro, summary).';
meanVelMacro = arrayfun(@(s) s.SummaryRow.MeanVelMacro, summary).';
meanDiaMicro = arrayfun(@(s) s.SummaryRow.MeanDiaMicro, summary).';
meanDiaMacro = arrayfun(@(s) s.SummaryRow.MeanDiaMacro, summary).';
dPick = summary(1).SummaryThresholdUm;

figure;
subplot(3, 2, 1);
plot(cpp, WF_SafeNormalize(cmc), '.', 'MarkerSize', 18);
xlabel('CPP');
ylabel('Normalized CMC');
title(sprintf('Micro vessel, D < %d um', round(dPick)));
grid on;

subplot(3, 2, 2);
plot(cpp, WF_SafeNormalize(cmac), '.', 'MarkerSize', 18);
xlabel('CPP');
ylabel('Normalized CMAC');
title(sprintf('Macro vessel, D >= %d um', round(dPick)));
grid on;

subplot(3, 2, 3);
plot(cpp, densityMicro, '.', 'MarkerSize', 18);
xlabel('CPP');
ylabel('Micro density');
title(sprintf('Micro density, D < %d um', round(dPick)));
grid on;

subplot(3, 2, 4);
plot(cpp, densityMacro, '.', 'MarkerSize', 18);
xlabel('CPP');
ylabel('Macro density');
title(sprintf('Macro density, D >= %d um', round(dPick)));
grid on;

subplot(3, 2, 5);
plot(cpp, WF_SafeNormalize(meanVelMicro), '.', 'MarkerSize', 18);
xlabel('CPP');
ylabel('Normalized mean velocity');
title(sprintf('Mean micro velocity, D < %d um', round(dPick)));
grid on;

subplot(3, 2, 6);
plot(cpp, WF_SafeNormalize(meanVelMacro), '.', 'MarkerSize', 18);
xlabel('CPP');
ylabel('Normalized mean velocity');
title(sprintf('Mean macro velocity, D >= %d um', round(dPick)));
grid on;

figure;
subplot(1, 2, 1);
plot(cpp, meanDiaMicro, '.', 'MarkerSize', 18);
xlabel('CPP');
ylabel('Mean micro diameter (\mum)');
title(sprintf('Micro diameter, D < %d um', round(dPick)));
grid on;

subplot(1, 2, 2);
plot(cpp, meanDiaMacro, '.', 'MarkerSize', 18);
xlabel('CPP');
ylabel('Mean macro diameter (\mum)');
title(sprintf('Macro diameter, D >= %d um', round(dPick)));
grid on;
end
