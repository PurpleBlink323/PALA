function plotInfo = PALA_GEIC59D_Plot(resultsDirsOrData, varargin)
%PALA_GEIC59D_PLOT Render CHOP velocity and density mosaics.
%   plotInfo = PALA_GEIC59D_Plot() interactively selects result folders.
%   plotInfo = PALA_GEIC59D_Plot(resultsDirs) renders the specified results.

if nargin < 1
    resultsDirsOrData = [];
end

parser = inputParser;
parser.addParameter('DefaultFilePath', 'D:\', @(x) ischar(x) || isstring(x));
parser.addParameter('DxMm', 0.016, @(x) isnumeric(x) && isscalar(x) && x > 0);
parser.addParameter('BarLengthMm', 5, @(x) isnumeric(x) && isscalar(x) && x > 0);
parser.addParameter('VelocityDisplayLimit', 4.5, @(x) isnumeric(x) && isscalar(x) && x > 0);
parser.addParameter('DensityDisplayLimit', 10, @(x) isnumeric(x) && isscalar(x) && x > 0);
parser.addParameter('VelocityTitleList', {}, @(x) iscell(x) || isstring(x));
parser.addParameter('DensityTitleList', {}, @(x) iscell(x) || isstring(x));
parser.addParameter('ResultLabels', {}, @(x) iscell(x) || isstring(x));
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
addpath(genpath(addonsDir));
addpath(genpath(fullfile(scriptDir, 'myFunction')));

[Matout_Cell, MatOut_Vel_Cell, resultsDirs, loadedFiles, labels] = iLoadPlotData(resultsDirsOrData, opts.DefaultFilePath, opts.ResultLabels);

velocityTitleList = iResolveTitleList(opts.VelocityTitleList, labels);
densityTitleList = iResolveTitleList(opts.DensityTitleList, labels);

velocityConfig = struct( ...
    'figureId', 91, ...
    'colorbarFigureId', 92, ...
    'colorMap', jet(256), ...
    'displayLimit', opts.VelocityDisplayLimit, ...
    'titleList', {velocityTitleList}, ...
    'colorbarLabel', 'cm/s', ...
    'dataScale', 1540 / 5.6818 * 1e-3 / 10, ...
    'useSmoothing', true ...
    );
renderChopMapGrid(MatOut_Vel_Cell, velocityConfig, opts.DxMm, opts.BarLengthMm);

densityConfig = struct( ...
    'figureId', 93, ...
    'colorbarFigureId', 94, ...
    'colorMap', hot(256), ...
    'displayLimit', opts.DensityDisplayLimit, ...
    'titleList', {densityTitleList}, ...
    'colorbarLabel', 'Count of Tracks', ...
    'dataScale', 1, ...
    'useSmoothing', true ...
    );
renderChopMapGrid(Matout_Cell, densityConfig, opts.DxMm, opts.BarLengthMm);

plotInfo = struct();
plotInfo.ResultsDirs = resultsDirs;
plotInfo.LoadedFiles = loadedFiles;
plotInfo.Labels = labels;
plotInfo.MatOut = Matout_Cell;
plotInfo.MatOutVel = MatOut_Vel_Cell;
plotInfo.VelocityTitleList = velocityTitleList;
plotInfo.DensityTitleList = densityTitleList;
end

function [Matout_Cell, MatOut_Vel_Cell, resultsDirs, loadedFiles, labels] = iLoadPlotData(resultsDirsOrData, defaultFilePath, resultLabels)
if isempty(resultsDirsOrData)
    allfiles = uipickfiles( ...
        'FilterSpec', char(string(defaultFilePath)), ...
        'Prompt', 'Pick the result folders', ...
        'Output', 'struct');
    if isempty(allfiles)
        error('No folders selected.');
    end

    resultsDirs = cell(numel(allfiles), 1);
    labels = cell(numel(allfiles), 1);
    for i = 1:numel(allfiles)
        selectedPath = WF_ResolveSelectedFolder(allfiles(i));
        resultsDirs{i} = WF_ResolveResultsFolder(selectedPath);
        labels{i} = WF_LabelFromPath(selectedPath);
    end
elseif isstruct(resultsDirsOrData)
    dataList = resultsDirsOrData;
    Matout_Cell = cell(numel(dataList), 1);
    MatOut_Vel_Cell = cell(numel(dataList), 1);
    resultsDirs = cell(numel(dataList), 1);
    loadedFiles = cell(numel(dataList), 1);
    labels = cell(numel(dataList), 1);
    for i = 1:numel(dataList)
        if ~isfield(dataList(i), 'MatOut') || ~isfield(dataList(i), 'MatOut_vel')
            error('Struct input must contain MatOut and MatOut_vel fields.');
        end
        Matout_Cell{i} = dataList(i).MatOut;
        MatOut_Vel_Cell{i} = dataList(i).MatOut_vel;
        if isfield(dataList(i), 'ResultsDir')
            resultsDirs{i} = dataList(i).ResultsDir;
        else
            resultsDirs{i} = '';
        end
        if isfield(dataList(i), 'SourceFile')
            loadedFiles{i} = dataList(i).SourceFile;
        else
            loadedFiles{i} = '';
        end
        if isfield(dataList(i), 'Label')
            labels{i} = char(string(dataList(i).Label));
        else
            labels{i} = sprintf('Map %d', i);
        end
    end
    return
else
    resultsDirs = iNormalizeResultsInput(resultsDirsOrData);
    if isempty(resultsDirs)
        error('No result folders were provided.');
    end
    labels = iNormalizeLabels(resultLabels, resultsDirs);
end

Matout_Cell = cell(numel(resultsDirs), 1);
MatOut_Vel_Cell = cell(numel(resultsDirs), 1);
loadedFiles = cell(numel(resultsDirs), 1);
for i = 1:numel(resultsDirs)
    resultsDir = WF_ResolveResultsFolder(resultsDirs{i});
    matoutfiles = dir(fullfile(resultsDir, '*_multi.mat'));
    matoutfiles = matoutfiles(~[matoutfiles.isdir]);
    if isempty(matoutfiles)
        error('No *_multi.mat file found in %s.', resultsDir);
    elseif numel(matoutfiles) > 1
        error('More than one *_multi.mat file found in %s. Select folders with a single CHOP result.', resultsDir);
    end

    S = load(fullfile(matoutfiles(1).folder, matoutfiles(1).name), 'MatOut', 'MatOut_vel');
    Matout_Cell{i} = S.MatOut{1};
    MatOut_Vel_Cell{i} = S.MatOut_vel{1};
    loadedFiles{i} = fullfile(matoutfiles(1).folder, matoutfiles(1).name);
    resultsDirs{i} = resultsDir;
end
end

function labels = iResolveTitleList(customTitles, fallbackLabels)
if isempty(customTitles)
    labels = fallbackLabels;
else
    labels = cellstr(string(customTitles(:)));
end
end

function labels = iNormalizeLabels(resultLabels, resultsDirs)
if isempty(resultLabels)
    labels = cell(numel(resultsDirs), 1);
    for i = 1:numel(resultsDirs)
        labels{i} = WF_LabelFromPath(resultsDirs{i});
    end
else
    labels = cellstr(string(resultLabels(:)));
    if numel(labels) ~= numel(resultsDirs)
        error('ResultLabels must contain one label per result directory.');
    end
end
end

function resultDirs = iNormalizeResultsInput(resultsDirsOrData)
if ischar(resultsDirsOrData) || isstring(resultsDirsOrData)
    resultDirs = cellstr(string(resultsDirsOrData(:)));
elseif iscell(resultsDirsOrData)
    resultDirs = cellfun(@(x) char(string(x)), resultsDirsOrData(:), 'UniformOutput', false);
else
    error('Unsupported input type for result directories.');
end
end

function renderChopMapGrid(matoutCell, config, dx_mm, barLength_mm)
filenum = numel(matoutCell);
nrow = 2;
ncol = ceil(filenum / nrow);

gapX = 0;
gapY = -0.13;
leftMargin = 0.01;
rightMargin = 0.01;
topMargin = 0.01;
bottomMargin = 0.01;
titleFontSize = 12;
titleColor = 'w';
barLineWidth = 3;
barColor = 'w';
barFontSize = 10;

cmap = config.colorMap;
cmap(1, :) = [0 0 0];

figure(config.figureId);
clf
set(gcf, 'Color', 'k', 'Units', 'pixels', 'Position', [100 100 1800 700]);

tileW = (1 - leftMargin - rightMargin - (ncol - 1) * gapX) / ncol;
tileH = (1 - topMargin - bottomMargin - (nrow - 1) * gapY) / nrow;

for i = 1:filenum
    r = ceil(i / ncol);
    c = mod(i - 1, ncol) + 1;

    x = leftMargin + (c - 1) * (tileW + gapX);
    y = 1 - topMargin - r * tileH - (r - 1) * gapY;
    ax = axes('Position', [x y tileW tileH]);

    V = double(matoutCell{i}) .* config.dataScale;
    V(~isfinite(V)) = 0;
    V(V < 0) = 0;
    if config.useSmoothing
        V = imgaussfilt(V, 0.6);
    end

    imagesc(V, [0 config.displayLimit]);
    axis image off
    colormap(ax, cmap);
    hold(ax, 'on');

    [h, w] = size(V);
    if i <= numel(config.titleList)
        myTitle = config.titleList{i};
    else
        myTitle = sprintf('Map %d', i);
    end

    text(ax, 0.01 * w, 0.01 * h, myTitle, ...
        'Color', titleColor, ...
        'FontSize', titleFontSize, ...
        'FontWeight', 'bold', ...
        'Interpreter', 'none', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'top');

    barLength_px = round(barLength_mm / dx_mm);
    x1 = 0.05 * w;
    x2 = min(w * 0.05 + barLength_px, w * 0.95);
    yb = 0.90 * h;

    line(ax, [x1 x2], [yb yb], 'Color', barColor, 'LineWidth', barLineWidth);
    text(ax, x1, yb - 0.03 * h, sprintf('%g mm', barLength_mm), ...
        'Color', barColor, ...
        'FontSize', barFontSize, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'bottom');
end

figure(config.colorbarFigureId);
clf
set(gcf, 'Color', 'w', 'Units', 'pixels', 'Position', [100 100 220 700]);
ax = axes('Position', [0.1 0.05 0.2 0.9], 'Visible', 'off');
colormap(ax, cmap);
clim(ax, [0 config.displayLimit]);
cb = colorbar(ax, 'eastoutside');
cb.Position = [0.35 0.08 0.14 0.84];
cb.FontSize = 16;
cb.Label.String = config.colorbarLabel;
cb.Label.FontSize = 18;
end
