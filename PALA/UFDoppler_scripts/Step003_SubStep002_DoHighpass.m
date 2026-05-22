for ip = 1:npath
    workingdir = allimagepath{ip};
    batchdir = fullfile(workingdir, 'batches');
    filtdir = fullfile(workingdir, 'filtImg');
    if ~exist(filtdir, 'dir')
        [status, msg] = mkdir(filtdir);
        if ~status
            error('Failed to create filtered images folder: %s\nReason: %s', filtdir, msg);
        end
    end
    load([workingdir,'\PTVparas.mat'],'batchnum','Enhparas')

    batchfiles = cell(batchnum, 1);
    nFramesPerBatch = zeros(batchnum, 1);
    for hhh = 1:batchnum
        batchfiles{hhh} = fullfile(batchdir, sprintf('IQ_batch_%03d.mat', hhh));
        batchInfo = whos('-file', batchfiles{hhh}, 'IQbatch');
        nFramesPerBatch(hhh) = batchInfo.size(3);
    end

    firstBatch = load(batchfiles{1}, 'IQbatch');
    totalFrames = sum(nFramesPerBatch);
    IQall = zeros(size(firstBatch.IQbatch, 1), size(firstBatch.IQbatch, 2), totalFrames, ...
        'like', firstBatch.IQbatch);
    clear firstBatch

    UFbatchAll = cell(batchnum, 1);
    PDataAll = cell(batchnum, 1);
    frameStart = 1;
    for hhh = 1:batchnum
         fprintf('Loading path %d/%d, batch %d/%d...\n', ...
            ip, npath, hhh, batchnum);
         %% Load raw images
         load(batchfiles{hhh}, 'IQbatch', 'UFbatch', 'PData');
         frameEnd = frameStart + nFramesPerBatch(hhh) - 1;
         IQall(:, :, frameStart:frameEnd) = IQbatch;
         UFbatchAll{hhh} = UFbatch;
         PDataAll{hhh} = PData;
         frameStart = frameEnd + 1;
    end

    %% Do enhancement on the full case to avoid filter transients at batch boundaries
    fprintf('High-pass filtering path %d/%d, %d frames...\n', ip, npath, totalFrames);
    IQ_filt_all = highpassEnhanceIQ(IQall, Enhparas);
    clear IQall

    frameStart = 1;
    for hhh = 1:batchnum
         fprintf('Saving path %d/%d, batch %d/%d...\n', ...
            ip, npath, hhh, batchnum);
         frameEnd = frameStart + nFramesPerBatch(hhh) - 1;
         IQ_filt = IQ_filt_all(:, :, frameStart:frameEnd);
         UFbatch = UFbatchAll{hhh};
         PData = PDataAll{hhh};
         %% Save filtered images
         save(fullfile(filtdir, sprintf('IQ_filt_%03d.mat', hhh)), ...
            'IQ_filt', 'UFbatch', 'PData', '-v7.3','-nocompression');
         if hhh == 1
            displaydir = fullfile(filtdir, 'display');
            if ~exist(displaydir, 'dir')
                mkdir(displaydir);
            end

            nDisplay = min(1000, size(IQ_filt, 3));

            for iframe = 1:nDisplay
                img = abs(IQ_filt(:, :, iframe));

                % Normalize to uint16 for ImageJ display
                img = img - min(img(:));
                img = img ./ max(img(:) + eps);
                img16 = uint16(img * 65535);

                imwrite(img16, fullfile(displaydir, sprintf('IQ_filt_%04d.tif', iframe)));
            end
         end
         frameStart = frameEnd + 1;
    end
    clear IQ_filt_all UFbatchAll PDataAll
end
