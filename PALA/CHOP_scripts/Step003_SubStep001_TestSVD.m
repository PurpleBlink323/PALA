for ip = 1:npath
    parasflag = 1;

    % load 1st batch for testing
    workingdir = allimagepath{ip};
    batchdir = fullfile(workingdir, 'batches');

    load(fullfile(batchdir, sprintf('IQ_batch_%03d.mat', 1)), ...
        'IQbatch', 'UFbatch', 'PData');

    % default Enhparas.ULM
    res = 5;
    ULM = struct('numberOfParticles', 200,...% Number of particles per frame. (30-100)
        'res',res,...                        % Resolution factor. Typically 10 for images at lambda/10.
        'SVD_cutoff',[0.025*UFbatch.NbFrames UFbatch.NbFrames],...    % svd filtering
        'max_linking_distance',2,...        % Maximum linking distance between two frames to reject pairing, in pixels units (UF.scale(1)). (2-4 pixel).
        'min_length', 10,...                % Minimum length of the tracks. (5-20)
        'fwhm',[5 5],...                  % Size of the mask for localization. (3x3 for pixel at lambda, 5x5 at lambda/2). [fmwhz fmwhx]
        'max_gap_closing', 0,...            % Allowed gap in microbubbles pairing. (0)
        'size',[PData.Size(1),PData.Size(2),UFbatch.NbFrames],...
        'scale',[1 1 1/UFbatch.FrameRateUF],...       % Scale [z x t]
        'numberOfFramesProcessed',UFbatch.NbFrames,... % Number of processed frames
        'interp_factor',1/res,...            % interpfactor
        'sigmaLCN', 12 ...
        );
    ULM.butter.CutoffFreq = [5, 100];
    ULM.butter.samplingFreq = UFbatch.FrameRateUF;         % Sampling frequency (Hz)
    ULM.parameters.NLocalMax = 7;           % Safeguard on the number of maxLocal in the fwhm*fwhm grid (3 for fwhm=3, 7 for fwhm=5)

    Enhparas.ULM = ULM;
    while parasflag == 1
    
        IQ_filt = svdEnhanceIQ(IQbatch, Enhparas);
        sliceViewer(abs(IQ_filt)); %(optional)
    
        parasflag = 1-input('Accept current Enhparas? yes = 1, no = 0: '); % avoid sliceviewer window conflict
        if parasflag == 1
    
            title1 = 'Update Enhancement Parameters';
    
            prompt = { ...
                'ULM.SVD_cutoff low', ...
                'ULM.SVD_cutoff high', ...
                'ULM.sigmaLCN',...
                'ULM.butter.CutoffFreq'};
    
            dims = [1 75];
    
            definput = { ...
                num2str(Enhparas.ULM.SVD_cutoff(1)), ...
                num2str(Enhparas.ULM.SVD_cutoff(2)), ...
                num2str(Enhparas.ULM.sigmaLCN), ...
                num2str(Enhparas.ULM.butter.CutoffFreq)};
    
            answer = inputdlg(prompt, title1, dims, definput);
    
            if isempty(answer)
                disp('Parameter update cancelled. Keeping current Enhparas.');
            else
                Enhparas.ULM.SVD_cutoff = [ ...
                    str2double(answer{1}), ...
                    str2double(answer{2})];
   
                Enhparas.ULM.sigmaLCN = str2double(answer{3});
                Enhparas.ULM.butter.CutoffFreq = str2double(answer{4});
    
                ULM = Enhparas.ULM;
            end
        end
    end
    save(fullfile(workingdir, 'PTVparas.mat'), 'Enhparas', '-append')
    close all
end