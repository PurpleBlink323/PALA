function rgbImage = maskedRIToRGB(RIMasked, cmap)
    if nargin < 2
        cmap = blueGreenRedColormap(256);
    end

    nColors = size(cmap, 1);
    validMask = isfinite(RIMasked);
    scaledRI = min(max(RIMasked, 0), 1);
    scaledRI(~validMask) = 0;

    colorIndex = round(scaledRI * (nColors - 1)) + 1;
    rgbImage = ind2rgb(colorIndex, cmap);

    for ichannel = 1:3
        channel = rgbImage(:, :, ichannel);
        channel(~validMask) = 0;
        rgbImage(:, :, ichannel) = channel;
    end
end
