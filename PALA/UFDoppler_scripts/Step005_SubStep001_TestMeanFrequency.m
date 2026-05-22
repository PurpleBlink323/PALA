for ip = 1:npath
    parasflag = 1;

    % load 1st filtered batch for testing
    workingdir = allimagepath{ip};
    filtdir = fullfile(workingdir, 'filtImg');
    load(fullfile(filtdir, sprintf('IQ_filt_%03d.mat', 1)), ...
        'IQ_filt', 'UFbatch', 'PData');

    sliceViewer(abs(IQ_filt)); %(optional)

    MFparas.firstSlice = min(41, size(IQ_filt, 3));
    MFparas.windowSize = min(80, size(IQ_filt, 3) - MFparas.firstSlice + 1);
    MFparas.overlapSize = min(70, MFparas.windowSize - 1);
    MFparas.samplingFreq = UFbatch.FrameRateUF;

    while parasflag == 1

        [MeanFrequencyArray, windowStartFrames, windowEndFrames, frequencyAxis] = ...
            meanFrequencySlidingWindowIQ(IQ_filt, MFparas);

        sliceViewer(MeanFrequencyArray); %(optional)

        meanFrequencyImage = mean(MeanFrequencyArray, 3);
        maxAbsFrequency = max(abs(meanFrequencyImage(:)));

        figure
        imagesc(meanFrequencyImage)
        axis image off
        colormap jet
        colorbar
        if maxAbsFrequency > 0
            clim([-maxAbsFrequency maxAbsFrequency])
        end
        title(sprintf('Mean frequency test, %d windows, %.1f to %.1f Hz', ...
            size(MeanFrequencyArray, 3), frequencyAxis(1), frequencyAxis(end)))

        fprintf('Window starts from frame %d to %d.\n', windowStartFrames(1), windowStartFrames(end));
        fprintf('Window ends from frame %d to %d.\n', windowEndFrames(1), windowEndFrames(end));
        fprintf('Frequency bins run from %.3f Hz to %.3f Hz.\n', frequencyAxis(1), frequencyAxis(end));

        parasflag = 1-input('Accept current MFparas? yes = 1, no = 0: '); % avoid sliceviewer window conflict
        if parasflag == 1

            title1 = 'Update Mean Frequency Parameters';

            prompt = { ...
                'MFparas.firstSlice', ...
                'MFparas.windowSize', ...
                'MFparas.overlapSize'};

            dims = [1 75];

            definput = { ...
                num2str(MFparas.firstSlice), ...
                num2str(MFparas.windowSize), ...
                num2str(MFparas.overlapSize)};

            answer = inputdlg(prompt, title1, dims, definput);

            if isempty(answer)
                disp('Parameter update cancelled. Keeping current MFparas.');
            else
                MFparas.firstSlice = round(str2double(answer{1}));
                MFparas.windowSize = round(str2double(answer{2}));
                MFparas.overlapSize = round(str2double(answer{3}));
                MFparas.samplingFreq = UFbatch.FrameRateUF;
            end
        end
    end
    save(fullfile(workingdir, 'PTVparas.mat'), 'MFparas', '-append')
    close all
end
