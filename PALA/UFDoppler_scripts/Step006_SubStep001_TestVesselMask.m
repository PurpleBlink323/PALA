for ip = 1:npath
    parasflag = 1;

    workingdir = allimagepath{ip};
    meanFrequencyFile = fullfile(workingdir, 'MeanFrequency', 'MeanFrequencyArray.mat');
    powerDopplerFile = fullfile(workingdir, 'PowerDopplerDemo', 'PowerDoppler.mat');

    if ~exist(meanFrequencyFile, 'file')
        error('Mean frequency file not found: %s', meanFrequencyFile);
    end
    if ~exist(powerDopplerFile, 'file')
        error('Power Doppler demo file not found: %s', powerDopplerFile);
    end

    load(powerDopplerFile, 'PowerDoppler');
    RIparas.adaptiveSensitivity = 0.5;
    RIparas.adaptiveNeighborhoodSize = 2 * floor(min(size(PowerDoppler))/16) + 1;

    [~, powerDopplerDisplay, ~, RIparas] = createVesselMaskFromPowerDoppler(PowerDoppler, RIparas);

    parasFile = fullfile(workingdir, 'PTVparas.mat');
    if exist(parasFile, 'file')
        savedParas = load(parasFile);
        if isfield(savedParas, 'RIparas')
            if isfield(savedParas.RIparas, 'adaptiveSensitivity')
                RIparas.adaptiveSensitivity = savedParas.RIparas.adaptiveSensitivity;
            end
            if isfield(savedParas.RIparas, 'adaptiveNeighborhoodSize')
                RIparas.adaptiveNeighborhoodSize = savedParas.RIparas.adaptiveNeighborhoodSize;
            end
        end
    end

    load(meanFrequencyFile, 'MeanFrequencyArray');
    RI = resistivityIndexFromMeanFrequency(MeanFrequencyArray);

    while parasflag == 1
        [vesselMask, ~, localThresholdMap, RIparas] = createVesselMaskFromPowerDoppler(PowerDoppler, RIparas);

        RIMasked = RI;
        RIMasked(~vesselMask) = NaN;

        cmap = blueGreenRedColormap(256);

        figure
        imagesc(powerDopplerDisplay)
        axis image off
        colormap hot
        colorbar
        title(sprintf('Power Doppler, sensitivity %.3f, window %d px', ...
            RIparas.adaptiveSensitivity, RIparas.adaptiveNeighborhoodSize))

        figure
        imagesc(localThresholdMap)
        axis image off
        colormap gray
        colorbar
        title('Adaptive local threshold map')

        figure
        imagesc(vesselMask)
        axis image off
        colormap gray
        colorbar
        title('Vessel binarization mask')

        figure
        imagesc(RIMasked, 'AlphaData', isfinite(RIMasked))
        set(gca, 'Color', 'k')
        axis image off
        colormap(cmap)
        colorbar
        clim([0 1])
        title('Masked resistivity index preview')

        parasflag = 1-input('Accept current RIparas? yes = 1, no = 0: ');
        if parasflag == 1
            title1 = 'Update Vessel Binarization Parameters';
            prompt = { ...
                'RIparas.adaptiveSensitivity', ...
                'RIparas.adaptiveNeighborhoodSize'};
            dims = [1 75];
            definput = { ...
                num2str(RIparas.adaptiveSensitivity), ...
                num2str(RIparas.adaptiveNeighborhoodSize)};
            answer = inputdlg(prompt, title1, dims, definput);

            if isempty(answer)
                disp('Parameter update cancelled. Keeping current RIparas.');
            else
                newSensitivity = str2double(answer{1});
                newNeighborhoodSize = str2double(answer{2});
                if isnan(newSensitivity) || newSensitivity < 0 || newSensitivity > 1
                    warning('RIparas.adaptiveSensitivity must be between 0 and 1. Keeping current value.');
                else
                    RIparas.adaptiveSensitivity = newSensitivity;
                end
                if isnan(newNeighborhoodSize) || newNeighborhoodSize < 1
                    warning('RIparas.adaptiveNeighborhoodSize must be a positive odd integer. Keeping current value.');
                else
                    RIparas.adaptiveNeighborhoodSize = round(newNeighborhoodSize);
                end
            end
        end
    end

    save(fullfile(workingdir, 'PTVparas.mat'), 'RIparas', '-append')
    clear MeanFrequencyArray RI RIMasked vesselMask PowerDoppler powerDopplerDisplay
    close all
end
