for ip = 1:npath
    parasflag = 1;

    % load 1st filtered batch for testing
    workingdir = allimagepath{ip};
    filtdir = fullfile(workingdir, 'filtImg');
    load(fullfile(filtdir, sprintf('IQ_filt_%03d.mat', 1)), ...
        'IQ_filt', 'UFbatch', 'PData');

    sliceViewer(abs(IQ_filt)); %(optional)

    PDparas.startFrame = min(41, size(IQ_filt, 3));
    PDparas.windowSize = min(200, size(IQ_filt, 3) - PDparas.startFrame + 1);
    PDparas.overlap = round(PDparas.windowSize/2);

    while parasflag == 1

        [PowerDopplerVideo, windowStartFrames, windowEndFrames] = ...
            powerDopplerSlidingWindowIQ(IQ_filt, PDparas);
        PowerDopplerDisplay = PowerDopplerVideo.^(1/3);
        PowerDopplerDisplay = PowerDopplerDisplay - min(PowerDopplerDisplay(:));
        PowerDopplerDisplay = PowerDopplerDisplay ./ max(PowerDopplerDisplay(:) + eps);

        sliceViewer(PowerDopplerDisplay); %(optional)

        figure
        imagesc(mean(PowerDopplerDisplay, 3))
        axis image off
        colormap hot
        colorbar
        title(sprintf('Power Doppler test, %d windows', size(PowerDopplerVideo, 3)))

        fprintf('Window starts from frame %d to %d.\n', windowStartFrames(1), windowStartFrames(end));
        fprintf('Window ends from frame %d to %d.\n', windowEndFrames(1), windowEndFrames(end));

        parasflag = 1-input('Accept current PDparas? yes = 1, no = 0: '); % avoid sliceviewer window conflict
        if parasflag == 1

            title1 = 'Update Power Doppler Video Parameters';

            prompt = { ...
                'PDparas.startFrame', ...
                'PDparas.windowSize', ...
                'PDparas.overlap'};

            dims = [1 75];

            definput = { ...
                num2str(PDparas.startFrame), ...
                num2str(PDparas.windowSize), ...
                num2str(PDparas.overlap)};

            answer = inputdlg(prompt, title1, dims, definput);

            if isempty(answer)
                disp('Parameter update cancelled. Keeping current PDparas.');
            else
                PDparas.startFrame = round(str2double(answer{1}));
                PDparas.windowSize = round(str2double(answer{2}));
                PDparas.overlap = round(str2double(answer{3}));
            end
        end
    end
    save(fullfile(workingdir, 'PTVparas.mat'), 'PDparas', '-append')
    close all
end
