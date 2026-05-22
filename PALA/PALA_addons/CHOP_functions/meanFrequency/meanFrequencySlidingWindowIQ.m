function [MeanFrequencyArray, windowStartFrames, windowEndFrames, frequencyAxis] = meanFrequencySlidingWindowIQ(IQ, MFparas)
    firstSlice = round(MFparas.firstSlice);
    windowSize = round(MFparas.windowSize);
    overlapSize = round(MFparas.overlapSize);
    samplingFreq = MFparas.samplingFreq;

    nFrames = size(IQ, 3);
    if ~isscalar(firstSlice) || ~isfinite(firstSlice) || firstSlice < 1 || firstSlice > nFrames
        error('MFparas.firstSlice must be between 1 and the number of frames.');
    end
    if ~isscalar(windowSize) || ~isfinite(windowSize) || windowSize < 1 || windowSize > nFrames - firstSlice + 1
        error('MFparas.windowSize must fit inside the selected frame range.');
    end
    if ~isscalar(overlapSize) || ~isfinite(overlapSize) || overlapSize < 0 || overlapSize >= windowSize
        error('MFparas.overlapSize must be between 0 and windowSize - 1.');
    end
    if ~isscalar(samplingFreq) || ~isfinite(samplingFreq) || samplingFreq <= 0
        error('MFparas.samplingFreq must be a positive scalar in Hz.');
    end

    stepSize = windowSize - overlapSize;
    lastStartFrame = nFrames - windowSize + 1;
    windowStartFrames = firstSlice:stepSize:lastStartFrame;
    windowEndFrames = windowStartFrames + windowSize - 1;

    frequencyAxis = ((-floor(windowSize/2)):(ceil(windowSize/2)-1)) * (samplingFreq/windowSize);
    frequencyWeights = reshape(frequencyAxis, 1, 1, []);
    hannWindow = reshape(hann(windowSize, 'periodic'), 1, 1, []);

    MeanFrequencyArray = zeros(size(IQ, 1), size(IQ, 2), numel(windowStartFrames), ...
        'like', abs(IQ(:, :, 1)));

    for iwindow = 1:numel(windowStartFrames)
        frameIdx = windowStartFrames(iwindow):windowEndFrames(iwindow);
        windowedIQ = IQ(:, :, frameIdx) .* hannWindow;
        PSD = abs(fftshift(fft(windowedIQ, [], 3), 3)).^2;

        denominator = sum(PSD, 3);
        numerator = sum(PSD .* frequencyWeights, 3);

        meanFrequency = numerator ./ denominator;
        meanFrequency(denominator <= 0) = 0;
        meanFrequency(~isfinite(meanFrequency)) = 0;
        MeanFrequencyArray(:, :, iwindow) = meanFrequency;
    end
end
