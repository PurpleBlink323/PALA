function [vesselMask, powerDopplerDisplay, localThresholdMap, RIparas] = createVesselMaskFromPowerDoppler(PowerDoppler, RIparas)
    if nargin < 2 || ~isstruct(RIparas)
        RIparas = struct();
    end

    powerDopplerDisplay = PowerDoppler.^(1/3);
    powerDopplerDisplay = powerDopplerDisplay - min(powerDopplerDisplay(:));
    powerDopplerDisplay = powerDopplerDisplay ./ max(powerDopplerDisplay(:) + eps);

    finitePixels = powerDopplerDisplay(isfinite(powerDopplerDisplay));
    if isempty(finitePixels) || max(finitePixels) <= 0
        localThresholdMap = zeros(size(powerDopplerDisplay));
        vesselMask = false(size(powerDopplerDisplay));
        return
    end

    if ~isfield(RIparas, 'adaptiveSensitivity') || ...
            ~isscalar(RIparas.adaptiveSensitivity) || ~isfinite(RIparas.adaptiveSensitivity)
        RIparas.adaptiveSensitivity = 0.5;
    end
    RIparas.adaptiveSensitivity = min(max(RIparas.adaptiveSensitivity, 0), 1);

    if ~isfield(RIparas, 'adaptiveNeighborhoodSize') || ...
            ~isscalar(RIparas.adaptiveNeighborhoodSize) || ~isfinite(RIparas.adaptiveNeighborhoodSize)
        RIparas.adaptiveNeighborhoodSize = 2 * floor(min(size(powerDopplerDisplay))/16) + 1;
    end
    RIparas.adaptiveNeighborhoodSize = makeValidAdaptiveWindow( ...
        RIparas.adaptiveNeighborhoodSize, size(powerDopplerDisplay));

    localThresholdMap = adaptthresh(powerDopplerDisplay, RIparas.adaptiveSensitivity, ...
        'ForegroundPolarity', 'bright', ...
        'NeighborhoodSize', RIparas.adaptiveNeighborhoodSize, ...
        'Statistic', 'gaussian');
    vesselMask = imbinarize(powerDopplerDisplay, localThresholdMap);
end

function neighborhoodSize = makeValidAdaptiveWindow(neighborhoodSize, imageSize)
    neighborhoodSize = max(3, round(neighborhoodSize));
    if mod(neighborhoodSize, 2) == 0
        neighborhoodSize = neighborhoodSize + 1;
    end

    maxNeighborhoodSize = 2 * floor((min(imageSize(1:2)) - 1)/2) + 1;
    maxNeighborhoodSize = max(1, maxNeighborhoodSize);
    if neighborhoodSize > maxNeighborhoodSize
        neighborhoodSize = maxNeighborhoodSize;
    end
end
