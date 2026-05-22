for ip = 1:npath
    workingdir = allimagepath{ip};
    meanFrequencyDir = fullfile(workingdir, 'MeanFrequency');
    meanFrequencyFile = fullfile(meanFrequencyDir, 'MeanFrequencyArray.mat');
    powerDopplerFile = fullfile(workingdir, 'PowerDopplerDemo', 'PowerDoppler.mat');
    resultsdir = fullfile(workingdir, 'ResistivityIndex');

    if ~exist(meanFrequencyFile, 'file')
        error('Mean frequency file not found: %s', meanFrequencyFile);
    end
    if ~exist(powerDopplerFile, 'file')
        error('Power Doppler demo file not found: %s', powerDopplerFile);
    end

    if ~exist(resultsdir, 'dir')
        [status, msg] = mkdir(resultsdir);
        if ~status
            error('Failed to create RI folder: %s\nReason: %s', resultsdir, msg);
        end
    end

    fprintf('Loading mean frequency array path %d/%d...\n', ip, npath);
    load(meanFrequencyFile, 'MeanFrequencyArray', 'windowStartFrames', ...
        'windowEndFrames', 'frequencyAxis', 'MFparas', 'UFbatch', 'PData');
    load(powerDopplerFile, 'PowerDoppler', 'startFrame');

    RIparas = struct();
    parasFile = fullfile(workingdir, 'PTVparas.mat');
    if exist(parasFile, 'file')
        savedParas = load(parasFile);
        if isfield(savedParas, 'RIparas')
            RIparas = savedParas.RIparas;
        end
    end

    fprintf('Creating RI map path %d/%d...\n', ip, npath);
    [RI, peakFrequency, endDiastolicFrequency] = resistivityIndexFromMeanFrequency(MeanFrequencyArray);
    [vesselMask, powerDopplerDisplay, localThresholdMap, RIparas] = createVesselMaskFromPowerDoppler(PowerDoppler, RIparas);

    if ~isequal(size(vesselMask), size(RI))
        error('Vessel mask size does not match RI size for path: %s', workingdir);
    end

    RIMasked = RI;
    RIMasked(~vesselMask) = NaN;

    cmap = blueGreenRedColormap(256);
    RIRGB = maskedRIToRGB(RIMasked, cmap);

    save(fullfile(resultsdir, 'ResistivityIndex.mat'), ...
        'RI', 'RIMasked', 'vesselMask', 'powerDopplerDisplay', ...
        'localThresholdMap', 'peakFrequency', 'endDiastolicFrequency', ...
        'windowStartFrames', 'windowEndFrames', 'frequencyAxis', ...
        'MFparas', 'RIparas', 'UFbatch', 'PData', 'startFrame', ...
        '-v7.3','-nocompression');

    imwrite(uint16(vesselMask) * 65535, fullfile(resultsdir, 'VesselMask.tif'));
    imwrite(uint16(powerDopplerDisplay * 65535), fullfile(resultsdir, 'PowerDopplerDisplay.tif'));
    imwrite(uint16(min(max(localThresholdMap, 0), 1) * 65535), fullfile(resultsdir, 'AdaptiveThresholdMap.tif'));
    imwrite(RIRGB, fullfile(resultsdir, 'RI_masked_blue_green_red.tif'));

    figure
    imagesc(RIMasked, 'AlphaData', isfinite(RIMasked))
    set(gca, 'Color', 'k')
    axis image off
    colormap(cmap)
    colorbar
    clim([0 1])
    title('Masked resistivity index')

    clear MeanFrequencyArray RI RIMasked vesselMask PowerDoppler powerDopplerDisplay
    clear localThresholdMap peakFrequency endDiastolicFrequency RIRGB
end
