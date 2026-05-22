for ip = 1:npath
    workingdir = allimagepath{ip};
    filtdir = fullfile(workingdir, 'filtImg');
    resultsdir = fullfile(workingdir, 'MeanFrequency');
    if ~exist(resultsdir, 'dir')
        [status, msg] = mkdir(resultsdir);
        if ~status
            error('Failed to create mean frequency folder: %s\nReason: %s', resultsdir, msg);
        end
    end
    load([workingdir,'\PTVparas.mat'],'batchnum','MFparas')

    filtfiles = cell(batchnum, 1);
    nFramesPerBatch = zeros(batchnum, 1);
    for hhh = 1:batchnum
        filtfiles{hhh} = fullfile(filtdir, sprintf('IQ_filt_%03d.mat', hhh));
        filtInfo = whos('-file', filtfiles{hhh}, 'IQ_filt');
        nFramesPerBatch(hhh) = filtInfo.size(3);
    end

    firstBatch = load(filtfiles{1}, 'IQ_filt');
    totalFrames = sum(nFramesPerBatch);
    IQall = zeros(size(firstBatch.IQ_filt, 1), size(firstBatch.IQ_filt, 2), totalFrames, ...
        'like', firstBatch.IQ_filt);
    clear firstBatch

    frameStart = 1;
    for hhh = 1:batchnum
        fprintf('Loading path %d/%d, filtered batch %d/%d...\n', ...
            ip, npath, hhh, batchnum);
        load(filtfiles{hhh}, 'IQ_filt', 'UFbatch', 'PData');
        frameEnd = frameStart + nFramesPerBatch(hhh) - 1;
        IQall(:, :, frameStart:frameEnd) = IQ_filt;
        frameStart = frameEnd + 1;
    end

    MFparas.samplingFreq = UFbatch.FrameRateUF;
    fprintf('Creating mean frequency array path %d/%d, %d frames...\n', ip, npath, totalFrames);
    [MeanFrequencyArray, windowStartFrames, windowEndFrames, frequencyAxis] = ...
        meanFrequencySlidingWindowIQ(IQall, MFparas);
    clear IQall

    save(fullfile(resultsdir, 'MeanFrequencyArray.mat'), ...
        'MeanFrequencyArray', 'windowStartFrames', 'windowEndFrames', ...
        'frequencyAxis', 'MFparas', 'UFbatch', 'PData', '-v7.3','-nocompression');

    framedir = fullfile(resultsdir, 'frames');
    if ~exist(framedir, 'dir')
        mkdir(framedir);
    end

    maxAbsFrequency = max(abs(MeanFrequencyArray(:)));
    if maxAbsFrequency == 0
        maxAbsFrequency = 1;
    end

    for iframe = 1:size(MeanFrequencyArray, 3)
        img = (MeanFrequencyArray(:, :, iframe) + maxAbsFrequency) ./ (2 * maxAbsFrequency);
        img = min(max(img, 0), 1);
        imwrite(uint16(img * 65535), fullfile(framedir, sprintf('MeanFrequency_%04d.tif', iframe)));
    end

    clear MeanFrequencyArray
end
