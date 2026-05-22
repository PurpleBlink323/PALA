for ip = 1:npath
    parasflag = 1;

    workingdir = allimagepath{ip};
    filtdir = fullfile(workingdir, 'filtImg');

    load([workingdir,'\PTVparas.mat'],'batchnum','Enhparas')

    testBatch = ceil(batchnum/2);
    load(fullfile(filtdir, sprintf('IQ_filt_%03d.mat', testBatch)), ...
        'IQ_filt', 'PData');

    testFrame = ceil(size(IQ_filt,3)/2);
    Algo = 'gaussian_fit';
    ULM = Enhparas.ULM;

    while parasflag == 1
        MatTracking = PALA_localization(IQ_filt(:,:,testFrame), Algo, ULM, PData);

        img = abs(IQ_filt(:,:,testFrame));
        figure(1),clf
        imagesc(img),colormap gray,axis image
        hold on
        locZ = (MatTracking(:,2) - PData.Origin(3))./PData.PDelta(3) + 1;
        locX = (MatTracking(:,3) - PData.Origin(1))./PData.PDelta(1) + 1;
        plot(locX, locZ, 'r+', 'MarkerSize', 6, 'LineWidth', 1)
        title(sprintf('Path %d/%d, batch %d, frame %d', ip, npath, testBatch, testFrame))
        drawnow

        parasflag = 1-input('Accept current localization parameters? yes = 1, no = 0: ');
        if parasflag == 1
            title1 = 'Update Localization Parameters';

            prompt = { ...
                'ULM.numberOfParticles', ...
                'ULM.fwhm', ...
                'ULM.parameters.NLocalMax'};

            dims = [1 75];

            definput = { ...
                num2str(ULM.numberOfParticles), ...
                num2str(ULM.fwhm), ...
                num2str(ULM.parameters.NLocalMax)};

            answer = inputdlg(prompt, title1, dims, definput);

            if isempty(answer)
                disp('Parameter update cancelled. Keeping current localization parameters.');
            else
                ULM.numberOfParticles = str2double(answer{1});
                newFwhm = sscanf(answer{2}, '%f')';
                if isscalar(newFwhm)
                    newFwhm = repmat(newFwhm,1,2);
                end
                ULM.fwhm = newFwhm;
                ULM.parameters.NLocalMax = str2double(answer{3});
            end
        end
    end

    Locparas.Algo = Algo;
    Locparas.ULM = ULM;
    Enhparas.ULM = ULM;
    save(fullfile(workingdir, 'PTVparas.mat'), 'Locparas', 'Enhparas', '-append')
    close all
end
