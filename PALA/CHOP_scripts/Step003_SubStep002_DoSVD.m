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
    for hhh = 1:batchnum
         fprintf('Processing path %d/%d, batch %d/%d...\n', ...
            ip, npath, hhh, batchnum);
         %% Load raw images
         load(fullfile(batchdir, sprintf('IQ_batch_%03d.mat', hhh)), ...
        'IQbatch', 'UFbatch', 'PData');
         %% Do enhancement
         IQ_filt = svdEnhanceIQ(IQbatch, Enhparas);
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
    end
end