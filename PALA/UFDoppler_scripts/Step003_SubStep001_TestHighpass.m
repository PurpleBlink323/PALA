for ip = 1:npath
    parasflag = 1;

    % load 1st batch for testing
    workingdir = allimagepath{ip};
    batchdir = fullfile(workingdir, 'batches');

    load(fullfile(batchdir, sprintf('IQ_batch_%03d.mat', 1)), ...
        'IQbatch', 'UFbatch');

    % default Enhparas.ULM
    ULM.butter.FilterOrder = 4;
    ULM.butter.CutoffFreq = 30;               % Cutoff frequency (Hz) for high-pass filter.
    ULM.butter.samplingFreq = UFbatch.FrameRateUF;    % Sampling frequency (Hz)
    ULM.butter.FilterType = 'high';

    Enhparas.ULM = ULM;
    while parasflag == 1

        IQ_filt = highpassEnhanceIQ(IQbatch, Enhparas);
        sliceViewer(abs(IQ_filt)); %(optional)

        parasflag = 1-input('Accept current Enhparas? yes = 1, no = 0: '); % avoid sliceviewer window conflict
        if parasflag == 1

            title1 = 'Update Enhancement Parameters';

            prompt = {'ULM.butter.CutoffFreq'};

            dims = [1 75];

            definput = {num2str(Enhparas.ULM.butter.CutoffFreq)};

            answer = inputdlg(prompt, title1, dims, definput);

            if isempty(answer)
                disp('Parameter update cancelled. Keeping current Enhparas.');
            else
                Enhparas.ULM.butter.FilterOrder = 4;
                Enhparas.ULM.butter.CutoffFreq = str2double(answer{1});
                Enhparas.ULM.butter.samplingFreq = UFbatch.FrameRateUF;
                Enhparas.ULM.butter.FilterType = 'high';
            end
        end
    end
    save(fullfile(workingdir, 'PTVparas.mat'), 'Enhparas', '-append')
    close all
end
