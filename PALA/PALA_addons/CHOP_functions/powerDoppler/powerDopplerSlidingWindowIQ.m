function [PowerDopplerVideo, windowStartFrames, windowEndFrames] = powerDopplerSlidingWindowIQ(IQ, PDparas)
    startFrame = round(PDparas.startFrame);
    windowSize = round(PDparas.windowSize);
    overlap = round(PDparas.overlap);

    nFrames = size(IQ, 3);
    if startFrame < 1 || startFrame > nFrames
        error('PDparas.startFrame must be between 1 and the number of frames.');
    end
    if windowSize < 1 || windowSize > nFrames - startFrame + 1
        error('PDparas.windowSize must fit inside the selected frame range.');
    end
    if overlap < 0 || overlap >= windowSize
        error('PDparas.overlap must be between 0 and windowSize - 1.');
    end

    stepSize = windowSize - overlap;
    lastStartFrame = nFrames - windowSize + 1;
    windowStartFrames = startFrame:stepSize:lastStartFrame;
    windowEndFrames = windowStartFrames + windowSize - 1;

    PowerDopplerVideo = zeros(size(IQ, 1), size(IQ, 2), numel(windowStartFrames), 'like', abs(IQ(:,:,1)));
    for iwindow = 1:numel(windowStartFrames)
        frameIdx = windowStartFrames(iwindow):windowEndFrames(iwindow);
        PowerDopplerVideo(:, :, iwindow) = sum(abs(IQ(:, :, frameIdx)).^2, 3);
    end
end
