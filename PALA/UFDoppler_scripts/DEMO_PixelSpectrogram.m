%% DEMO_PixelSpectrogram
% Select one processed case, click one pixel, and display the Step005
% mean-frequency spectrogram for that pixel.

clear
close all
clc

if exist('temp.mat','file')
    tempData = load('temp.mat', 'currentfolder');
    if isfield(tempData, 'currentfolder')
        defaultfilepath = tempData.currentfolder;
    else
        defaultfilepath = 'D:\VSX_Experiments\';
    end
else
    defaultfilepath = 'D:\VSX_Experiments\';
end

casefile = uipickfiles('FilterSpec',defaultfilepath,...
    'Prompt','DEMO: Select one processed case folder for pixel spectrogram',...
    'NumFiles',1,...
    'Output','struct');

if isequal(casefile, 0)
    disp('No case selected.')
    return
end

workingdir = casefile(1).name;
currentfolder = casefile(1).folder;
save('temp.mat','currentfolder','-append')

[IQUsed, UFbatch, datadir, iqvar] = loadCaseIQStackForSpectrogram(workingdir);
samplingFreq = UFbatch.FrameRateUF;
totalFrames = size(IQUsed, 3);

meanFrequencyFile = fullfile(workingdir, 'MeanFrequency', 'MeanFrequencyArray.mat');
if ~exist(meanFrequencyFile, 'file')
    error('Mean frequency file not found. Run Step005_MeanFrequency first: %s', meanFrequencyFile);
end
mfData = load(meanFrequencyFile, 'MeanFrequencyArray', 'windowStartFrames', ...
    'windowEndFrames', 'frequencyAxis', 'MFparas');
if ~isequal(size(mfData.MeanFrequencyArray, 1), size(IQUsed, 1)) || ...
        ~isequal(size(mfData.MeanFrequencyArray, 2), size(IQUsed, 2))
    error('MeanFrequencyArray image size does not match IQ image size.');
end

powerDopplerDemoFile = fullfile(workingdir, 'PowerDopplerDemo', 'PowerDoppler.mat');
if exist(powerDopplerDemoFile, 'file')
    demoData = load(powerDopplerDemoFile, 'PowerDoppler');
    selectionImage = demoData.PowerDoppler.^(1/3);
else
    selectionImage = mean(abs(mfData.MeanFrequencyArray), 3);
end
selectionImage = selectionImage - min(selectionImage(:));
selectionImage = selectionImage ./ max(selectionImage(:) + eps);

figure
imagesc(selectionImage)
axis image off
colormap hot
colorbar
title('Click one pixel for spectrogram')

[xClick, yClick] = ginput(1);
pixelCol = min(max(round(xClick), 1), size(IQUsed, 2));
pixelRow = min(max(round(yClick), 1), size(IQUsed, 1));

MFparas = mfData.MFparas;
MFparas.samplingFreq = samplingFreq;
[spectrogramPower, meanFrequencyTrace, timeAxis, frequencyAxis] = ...
    pixelMeanFrequencySpectrogram(IQUsed, pixelRow, pixelCol, MFparas, ...
    mfData.windowStartFrames, mfData.windowEndFrames);
savedMeanFrequencyTrace = squeeze(mfData.MeanFrequencyArray(pixelRow, pixelCol, :));

spectrogramMagnitude = sqrt(spectrogramPower);
spectrogramMagnitude = spectrogramMagnitude - min(spectrogramMagnitude(:));
spectrogramMagnitude = spectrogramMagnitude ./ max(spectrogramMagnitude(:) + eps);

figure
imagesc(timeAxis, frequencyAxis, spectrogramMagnitude)
axis xy
colormap gray
colorbar
clim([0 1])
xlabel('Time (s)')
ylabel('Doppler frequency (Hz)')
title(sprintf('Mean-frequency spectrogram at pixel row %d, col %d', pixelRow, pixelCol))

figure
plot(timeAxis, savedMeanFrequencyTrace, 'k--', 'LineWidth', 1)
hold on
plot(timeAxis, meanFrequencyTrace, 'b-', 'LineWidth', 1.5)
xlabel('Time (s)')
ylabel('Mean frequency (Hz)')
title(sprintf('Mean frequency at pixel row %d, col %d', pixelRow, pixelCol))
legend({'Saved Step005 mean frequency', 'Recomputed from pixel PSD'}, 'Location', 'best')
grid on

fprintf('Selected pixel row %d, col %d.\n', pixelRow, pixelCol);
fprintf('Loaded IQ from %s using variable %s.\n', datadir, iqvar);
fprintf('Used Step005 MFparas: firstSlice=%d, windowSize=%d, overlapSize=%d.\n', ...
    MFparas.firstSlice, MFparas.windowSize, MFparas.overlapSize);

function [IQUsed, UFbatch, datadir, iqvar] = loadCaseIQStackForSpectrogram(workingdir)
    filtdir = fullfile(workingdir, 'filtImg');
    if exist(filtdir, 'dir')
        datadir = filtdir;
        filepattern = 'IQ_filt_*.mat';
        iqvar = 'IQ_filt';
    else
        datadir = fullfile(workingdir, 'batches');
        filepattern = 'IQ_batch_*.mat';
        iqvar = 'IQbatch';
    end

    iqfiles = dir(fullfile(datadir, filepattern));
    if isempty(iqfiles)
        error('No IQ files found in: %s', datadir);
    end

    firstInfo = whos('-file', fullfile(iqfiles(1).folder, iqfiles(1).name), iqvar);
    nFramesPerFile = zeros(numel(iqfiles), 1);
    nFramesPerFile(1) = firstInfo.size(3);
    for ifile = 2:numel(iqfiles)
        fileInfo = whos('-file', fullfile(iqfiles(ifile).folder, iqfiles(ifile).name), iqvar);
        if ~isequal(fileInfo.size(1:2), firstInfo.size(1:2))
            error('IQ frame size mismatch in: %s', iqfiles(ifile).name);
        end
        nFramesPerFile(ifile) = fileInfo.size(3);
    end

    totalFrames = sum(nFramesPerFile);
    firstData = load(fullfile(iqfiles(1).folder, iqfiles(1).name), iqvar);
    firstIQ = firstData.(iqvar);
    IQUsed = zeros(firstInfo.size(1), firstInfo.size(2), totalFrames, 'like', firstIQ);
    clear firstData firstIQ

    frameStart = 1;
    for ifile = 1:numel(iqfiles)
        fprintf('Loading file %d/%d: %s\n', ifile, numel(iqfiles), iqfiles(ifile).name);
        data = load(fullfile(iqfiles(ifile).folder, iqfiles(ifile).name), iqvar, 'UFbatch');
        IQ = data.(iqvar);

        frameEnd = frameStart + nFramesPerFile(ifile) - 1;
        IQUsed(:, :, frameStart:frameEnd) = IQ;
        frameStart = frameEnd + 1;

        if ifile == 1
            UFbatch = data.UFbatch;
        end
    end
end

function [spectrogramPower, meanFrequencyTrace, timeAxis, frequencyAxis] = ...
        pixelMeanFrequencySpectrogram(IQUsed, pixelRow, pixelCol, MFparas, ...
        windowStartFrames, windowEndFrames)
    windowSize = round(MFparas.windowSize);
    samplingFreq = MFparas.samplingFreq;
    frequencyAxis = ((-floor(windowSize/2)):(ceil(windowSize/2)-1))' * ...
        (samplingFreq/windowSize);
    hannWindow = hann(windowSize, 'periodic');

    nWindows = numel(windowStartFrames);
    spectrogramPower = zeros(windowSize, nWindows);
    meanFrequencyTrace = zeros(nWindows, 1);
    timeAxis = ((windowStartFrames(:) + windowEndFrames(:))/2 - 1) / samplingFreq;

    for iwindow = 1:nWindows
        frameIdx = windowStartFrames(iwindow):windowEndFrames(iwindow);
        pixelSignal = squeeze(IQUsed(pixelRow, pixelCol, frameIdx));
        pixelSignal = pixelSignal(:) .* hannWindow;
        PSD = abs(fftshift(fft(pixelSignal, [], 1), 1)).^2;
        spectrogramPower(:, iwindow) = PSD;

        denominator = sum(PSD);
        if denominator > 0
            meanFrequencyTrace(iwindow) = sum(PSD .* frequencyAxis) / denominator;
        else
            meanFrequencyTrace(iwindow) = 0;
        end
    end
end
