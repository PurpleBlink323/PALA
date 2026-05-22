for ip = 1:npath
    workingdir = allimagepath{ip};
    localizationdir = fullfile(workingdir, 'localizationResults');
    trackingdir = fullfile(workingdir, 'trackingResults');
    if ~exist(trackingdir, 'dir')
        [status, msg] = mkdir(trackingdir);
        if ~status
            error('Failed to create tracking results folder: %s\nReason: %s', trackingdir, msg);
        end
    end

    load([workingdir,'\PTVparas.mat'],'batchnum','Enhparas')
    parasInfo = whos('-file',[workingdir,'\PTVparas.mat']);
    if any(strcmp({parasInfo.name}, 'Trackparas'))
        load([workingdir,'\PTVparas.mat'],'Trackparas')
    else
        Trackparas.ULM = Enhparas.ULM;
        Trackparas.TestBatch = [];
        Trackparas.TestFrameRange = [];
    end
    if any(strcmp({parasInfo.name}, 'Locparas'))
        load([workingdir,'\PTVparas.mat'],'Locparas')
    else
        Locparas.Algo = 'gaussian_fit';
        Locparas.ULM = Enhparas.ULM;
    end

    for hhh = 1:batchnum
         fprintf('Processing path %d/%d, batch %d/%d...\n', ...
            ip, npath, hhh, batchnum);
         %% Load localization results
         load(fullfile(localizationdir, sprintf('Loc_%03d.mat', hhh)), ...
        'MatTracking', 'PData', 'UFbatch');
         %% Do tracking
         [Track_raw,Track_interp] = PALA_tracking(MatTracking, Trackparas.ULM, PData);
         %% Save tracking results
         save(fullfile(trackingdir, sprintf('Tracks_%03d.mat', hhh)), ...
            'Track_raw', 'Track_interp', 'Trackparas', 'Locparas', 'PData', 'UFbatch', '-v7.3','-nocompression');
    end
end
