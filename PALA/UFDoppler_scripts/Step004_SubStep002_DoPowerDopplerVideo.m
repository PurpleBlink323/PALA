for ip = 1:npath
    workingdir = allimagepath{ip};
    filtdir = fullfile(workingdir, 'filtImg');
    resultsdir = fullfile(workingdir, 'PowerDopplerVideo');
    if ~exist(resultsdir, 'dir')
        [status, msg] = mkdir(resultsdir);
        if ~status
            error('Failed to create power Doppler video folder: %s\nReason: %s', resultsdir, msg);
        end
    end
    load([workingdir,'\PTVparas.mat'],'batchnum','PDparas')

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

    fprintf('Creating power Doppler video path %d/%d, %d frames...\n', ip, npath, totalFrames);
    [PowerDopplerVideo, windowStartFrames, windowEndFrames] = ...
        powerDopplerSlidingWindowIQ(IQall, PDparas);
    clear IQall

    PowerDopplerDisplay = PowerDopplerVideo.^(1/3);
    PowerDopplerDisplay = PowerDopplerDisplay - min(PowerDopplerDisplay(:));
    PowerDopplerDisplay = PowerDopplerDisplay ./ max(PowerDopplerDisplay(:) + eps);

    save(fullfile(resultsdir, 'PowerDopplerVideo.mat'), ...
        'PowerDopplerVideo', 'PowerDopplerDisplay', 'windowStartFrames', ...
        'windowEndFrames', 'PDparas', 'UFbatch', 'PData', '-v7.3','-nocompression');

    framedir = fullfile(resultsdir, 'frames');
    if ~exist(framedir, 'dir')
        mkdir(framedir);
    end

    videoFile = fullfile(resultsdir, 'PowerDopplerVideo.mp4');
    videoObj = VideoWriter(videoFile, 'MPEG-4');
    videoObj.FrameRate = 10;
    open(videoObj)

    for iframe = 1:size(PowerDopplerDisplay, 3)
        img16 = uint16(PowerDopplerDisplay(:, :, iframe) * 65535);
        imwrite(img16, fullfile(framedir, sprintf('PowerDoppler_%04d.tif', iframe)));
        writeVideo(videoObj, ind2rgb(gray2ind(PowerDopplerDisplay(:, :, iframe), 256), hot(256)));
    end
    close(videoObj)

    clear PowerDopplerVideo PowerDopplerDisplay
end
