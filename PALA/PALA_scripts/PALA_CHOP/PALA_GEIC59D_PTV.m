function result = PALA_GEIC59D_PTV(experimentDir, varargin)
%PALA_GEIC59D_PTV Run CHOP PTV processing for a single experiment.
%   result = PALA_GEIC59D_PTV() interactively selects one experiment folder.
%   result = PALA_GEIC59D_PTV(experimentDir) processes the given experiment.

if nargin < 1
    experimentDir = '';
end

parser = inputParser;
parser.addParameter('DefaultWorkingDir', 'D:\VSX_Experiments\', @(x) ischar(x) || isstring(x));
parser.addParameter('PickROI', false, @(x) islogical(x) || isnumeric(x));
parser.addParameter('DefaultROI', [293 821 154 601], @(x) isnumeric(x) && numel(x) == 4);
parser.addParameter('BatchSize', 3000, @(x) isnumeric(x) && isscalar(x) && x > 0);
parser.addParameter('PreviewFrames', 500, @(x) isnumeric(x) && isscalar(x) && x > 0);
parser.addParameter('PreviewDbFloor', -60, @(x) isnumeric(x) && isscalar(x));
parser.addParameter('BlockSize', 80, @(x) isnumeric(x) && isscalar(x) && x > 0);
parser.addParameter('BlockOverlap', 0.8, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x < 1);
parser.addParameter('ShowPreview', true, @(x) islogical(x) || isnumeric(x));
parser.addParameter('ShowFinalFigures', true, @(x) islogical(x) || isnumeric(x));
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

fprintf('Running PALA_GEIC59D_PTV.m\n');
tStart = tic;

%% Select experiment folder
experimentDir = char(string(experimentDir));
if isempty(experimentDir)
    experimentDir = uigetdir(char(string(opts.DefaultWorkingDir)), 'Select CHOP experiment folder');
    if isequal(experimentDir, 0)
        error('No folder selected.');
    end
end
if ~isfolder(experimentDir)
    error('Experiment folder does not exist: %s', experimentDir);
end

[iqFile, iqStem] = iResolveIqFile(experimentDir);
trackDir = fullfile(experimentDir, 'Tracks');
resultsDir = fullfile(experimentDir, 'Results');
if ~exist(trackDir, 'dir'), mkdir(trackDir); end
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
trackFilePrefix = fullfile(trackDir, [iqStem '_']);
resultsFilePrefix = fullfile(resultsDir, [iqStem '_']);

IQmat = matfile(fullfile(iqFile.folder, iqFile.name));
S = load(fullfile(iqFile.folder, iqFile.name), 'UF', 'PData');
UF = S.UF;
PData = S.PData;

if UF.NbFrames < opts.BatchSize
    error('UF.NbFrames (%d) must be at least the batch size (%d).', UF.NbFrames, opts.BatchSize);
end

batchnum = floor(UF.NbFrames / opts.BatchSize);
if mod(UF.NbFrames, opts.BatchSize) ~= 0
    warning('Ignoring the final %d frame(s) because batchsize is %d.', mod(UF.NbFrames, opts.BatchSize), opts.BatchSize);
end

%% Load first batch for setup
IQ_batch = IQmat.IQ(:, :, 1:opts.BatchSize);

if logical(opts.PickROI)
    I = mean(abs(IQ_batch(:, :, 1:min(opts.PreviewFrames, size(IQ_batch, 3)))), 3);
    figure;
    imagesc(I);
    axis image;
    colormap gray;
    clim([0, quantile(I(:), 0.99)]);
    title('Draw rectangle, then double-click inside to finalize');

    h = drawrectangle;
    wait(h);
    pos = round(h.Position);
    x1 = max(1, pos(1));
    y1 = max(1, pos(2));
    x2 = min(size(I, 2), x1 + pos(3) - 1);
    y2 = min(size(I, 1), y1 + pos(4) - 1);
else
    defaultROI = round(opts.DefaultROI(:).');
    x1 = defaultROI(1);
    x2 = defaultROI(2);
    y1 = defaultROI(3);
    y2 = defaultROI(4);
    fprintf('Using default ROI.\n');
end

%% Modify parameters for cropped processing
PData(1).Size(1) = y2 - y1 + 1;
PData(1).Size(2) = x2 - x1 + 1;
UF.NbFrames = size(IQ_batch, 3);
PData.Origin = [0, PData.Size(2) / 2 * PData.PDelta(2), 0];
framerate = UF.FrameRateUF;

speedOfSound = 1540;
umperwvl = speedOfSound / UF.TxFreq;
dpixwvl = round(80 / umperwvl, 2);
PData(1).PDelta = [dpixwvl, 0, dpixwvl];

%% ULM parameters
res = 5;
ULM = struct( ...
    'numberOfParticles', 300, ...
    'res', res, ...
    'SVD_cutoff', [floor(0.025 * UF.NbFrames), UF.NbFrames], ...
    'max_linking_distance', 2, ...
    'min_length', 10, ...
    'fwhm', [5 5], ...
    'max_gap_closing', 0, ...
    'size', [PData.Size(1), PData.Size(2), UF.NbFrames], ...
    'scale', [1 1 1 / framerate], ...
    'numberOfFramesProcessed', UF.NbFrames, ...
    'interp_factor', 1 / res, ...
    'sigmaLCN', 12 ...
    );
ULM.butter.CuttofFreq = [5, 180];
ULM.butter.samplingFreq = framerate;
[but_b, but_a] = butter(2, ULM.butter.CuttofFreq / (ULM.butter.samplingFreq / 2), 'bandpass');
ULM.parameters.NLocalMax = 9;
listAlgo = {'gaussian_fit'};
Nalgo = numel(listAlgo);

%% Preview filtering
[bulles, ~] = blockwiseSVDfilter(IQ_batch(y1:y2, x1:x2, :), opts.BlockSize, opts.BlockOverlap);
bulles_freqfilt = filter(but_b, but_a, bulles, [], 3);
bulles(~isfinite(bulles)) = 0;

amp = abs(bulles);
noise_amp = median(amp(:));
amp_denoised = max(amp - noise_amp, 0);
amp_ref = prctile(amp_denoised(:), 99.9) + eps;
amp_floor = amp_ref * 10^(opts.PreviewDbFloor / 20);
bulles_dB = 20 * log10(max(amp_denoised, amp_floor));

if logical(opts.ShowPreview)
    figure;
    sliceViewer(abs(bulles));
    figure;
    sliceViewer(abs(bulles_freqfilt));
    figure;
    sliceViewer(bulles_dB);
    bulles_enh = myEngImg(bulles_dB, 20);
    figure;
    imagesc(mean(bulles_enh, 3));
    figure;
    sliceViewer(bulles_enh);
end

%% Localization and tracking
fprintf('--- ULM PROCESSING --- \n\n');
tProcess = tic;
for hhh = 1:batchnum
    fprintf('Processing block %d/%d\n', hhh, batchnum);
    idxStart = 1 + opts.BatchSize * (hhh - 1);
    idxStop = opts.BatchSize * hhh;
    tmp = IQmat.IQ(:, :, idxStart:idxStop);
    IQ_filt = SVDfilter(tmp(y1:y2, x1:x2, :), ULM.SVD_cutoff);
    IQ_filt(~isfinite(IQ_filt)) = 0;
    IQ_filt = myEngImg(IQ_filt, ULM.sigmaLCN);

    PALA_multiULM(IQ_filt, listAlgo, ULM, PData, ...
        'savingfilename', [trackFilePrefix 'Tracks' num2str(hhh, '%.3d') '.mat']);
end
tProcess = toc(tProcess);
fprintf('ULM done in %d hours %.1f minutes. (for all localization algorithms)\n', floor(tProcess / 3600), rem(tProcess / 60, 60));

%% Create MatOuts
fprintf('--- CREATING MATOUTS --- \n\n');
MatOutSat = zeros(batchnum, Nalgo);
NbrOfLoc = zeros(Nalgo, 1);
ProcessingTime = zeros(batchnum, Nalgo);
MatOut = cell(Nalgo, 1);
MatOut(:) = {0};
MatOutNoInterp = MatOut;
MatOut_vel = MatOut;

hwait = waitbar(0, 'Building intensity renderings', 'Name', 'Building matouts');
for hhh = 1:min(batchnum, 999)
    trackPath = [trackFilePrefix 'Tracks' num2str(hhh, '%.3d') '.mat'];
    STrack = load(trackPath, 'Track_raw', 'Track_interp', 'ProTime');
    Track_raw = STrack.Track_raw;
    Track_interp = STrack.Track_interp;
    ProTime = STrack.ProTime;

    waitbar(hhh / batchnum, hwait);
    aa = -PData(1).Origin([3 1]) + [1 1];
    bb = 1 ./ PData(1).PDelta([3 1]) * ULM.res;
    aa(3) = 0;
    bb(3) = 1;
    for ialgo = 1:Nalgo
        Track_matout = Track_interp{ialgo};
        Track_matout = cellfun(@(x) (x(:, [1 2 3]) + aa) .* bb, Track_matout, 'UniformOutput', false);
        [MatOut_i, MatOut_vel_i] = ULM_Track2MatOut( ...
            Track_matout, ULM.res * [PData(1).Size(1) PData(1).Size(2)] + [1 1], 'mode', '2D_velmean');
        MatOut_vel{ialgo} = MatOut_vel{ialgo} .* MatOut{ialgo} + MatOut_vel_i .* MatOut_i;
        MatOut{ialgo} = MatOut{ialgo} + MatOut_i;
        validMask = MatOut{ialgo} > 0;
        MatOut_vel{ialgo}(validMask) = MatOut_vel{ialgo}(validMask) ./ MatOut{ialgo}(validMask);
        MatOutSat(hhh, ialgo) = nnz(validMask);

        Track_matout = Track_raw{ialgo};
        Track_matout = cellfun(@(x) (x(:, [1 2]) + aa(1:2)) .* bb(1:2), Track_matout, 'UniformOutput', false);
        MatOut_i = ULM_Track2MatOut(Track_matout, ULM.res * [PData(1).Size(1) PData(1).Size(2)] + [1 1]);
        MatOutNoInterp{ialgo} = MatOutNoInterp{ialgo} + MatOut_i;
        Track_count = cat(1, Track_matout{:});
        NbrOfLoc(ialgo) = NbrOfLoc(ialgo) + size(Track_count, 1);
    end
    ProcessingTime(hhh, :) = ProTime;
end
close(hwait);

matOutFile = [resultsFilePrefix 'MatOut_multi.mat'];
matOutNoInterpFile = [resultsFilePrefix 'MatOut_multi_nointerp.mat'];
save(matOutFile, 'MatOut', 'MatOut_vel', 'MatOutSat', 'NbrOfLoc', 'ULM', 'listAlgo', 'Nalgo', 'PData', 'UF');
save(matOutNoInterpFile, 'MatOutNoInterp', 'MatOutSat', 'NbrOfLoc', 'ULM', 'listAlgo', 'PData', 'Nalgo', 'UF', 'ProcessingTime');

if logical(opts.ShowFinalFigures)
    figure(90);
    clf
    for ialgo = 1:numel(listAlgo)
        imagesc(MatOut{ialgo}.^(1 / 3));
        axis image
        colormap hot
        clim([0 3]);
    end

    wv = 1540 / UF.TxFreq * 1e-3 / 10;
    figure(91);
    clf
    for ialgo = 1:numel(listAlgo)
        V = MatOut_vel{ialgo} .* wv;
        imagesc(V);
        axis image
        clim([0 max(V(:))]);
        cmap = jet(256);
        cmap(1, :) = [0 0 0];
        colormap(cmap);
        cb = colorbar;
        cb.Label.String = 'cm/s';
        cb.Label.FontSize = 12;
    end
end

tElapsed = toc(tStart);
fprintf('PALA_GEIC59D_PTV.m completed in %d hours and %.1f minutes.\n', floor(tElapsed / 3600), rem(tElapsed / 60, 60));

result = struct();
result.ExperimentDir = experimentDir;
result.IQFile = fullfile(iqFile.folder, iqFile.name);
result.IQStem = iqStem;
result.TrackDir = trackDir;
result.ResultsDir = resultsDir;
result.TrackFilePrefix = trackFilePrefix;
result.ResultsFilePrefix = resultsFilePrefix;
result.MatOutFile = matOutFile;
result.MatOutNoInterpFile = matOutNoInterpFile;
result.ROI = [x1 x2 y1 y2];
result.BatchCount = batchnum;
result.ListAlgo = listAlgo;
result.ElapsedSeconds = tElapsed;
end

function [iqFile, iqStem] = iResolveIqFile(experimentDir)
iqRoot = fullfile(experimentDir, 'IQ');
if ~isfolder(iqRoot)
    error('Expected an IQ folder under %s.', experimentDir);
end

iqFiles = dir(fullfile(iqRoot, '*.mat'));
iqFiles = iqFiles(~[iqFiles.isdir]);
if isempty(iqFiles)
    error('No .mat file found in %s.', iqRoot);
elseif numel(iqFiles) > 1
    error('More than one .mat file found in %s. This function expects exactly one IQ file.', iqRoot);
end

iqFile = iqFiles(1);
[iqStem, ~] = fileparts(iqFile.name);
end
