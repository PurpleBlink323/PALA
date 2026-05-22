for ip = 1:npath
    workingdir = allimagepath{ip};
    filtdir = fullfile(workingdir, 'filtImg');
    localizationdir = fullfile(workingdir, 'localizationResults');
    if ~exist(localizationdir, 'dir')
        [status, msg] = mkdir(localizationdir);
        if ~status
            error('Failed to create localization results folder: %s\nReason: %s', localizationdir, msg);
        end
    end

    load([workingdir,'\PTVparas.mat'],'batchnum','Enhparas')
    parasInfo = whos('-file',[workingdir,'\PTVparas.mat']);
    if any(strcmp({parasInfo.name}, 'Locparas'))
        load([workingdir,'\PTVparas.mat'],'Locparas')
    else
        Locparas.Algo = 'gaussian_fit';
        Locparas.ULM = Enhparas.ULM;
    end

    for hhh = 1:batchnum
         fprintf('Processing path %d/%d, batch %d/%d...\n', ...
            ip, npath, hhh, batchnum);
         %% Load filtered images
         load(fullfile(filtdir, sprintf('IQ_filt_%03d.mat', hhh)), ...
        'IQ_filt', 'UFbatch', 'PData');
         %% Do localization
         MatTracking = PALA_localization(IQ_filt, Locparas.Algo, Locparas.ULM, PData);
         %% Save localization results
         save(fullfile(localizationdir, sprintf('Loc_%03d.mat', hhh)), ...
            'MatTracking', 'Locparas', 'PData', 'UFbatch', '-v7.3','-nocompression');
    end
end
