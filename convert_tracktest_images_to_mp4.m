% Convert image files in the tracktest folder to an MP4 video.
% Adjust frameRate or outputFile below if needed, then run this script.

clear; clc;

inputDir = 'D:\VSX_Experiments\Pig931-HydroBrain-Baseline-CEUS\tracktest';
outputFile = fullfile(inputDir, 'tracktest.mp4');
frameRate = 20;
quality = 95;

imagePatterns = {'*.png', '*.jpg', '*.jpeg', '*.tif', '*.tiff', '*.bmp'};

files = [];
for iPattern = 1:numel(imagePatterns)
    files = [files; dir(fullfile(inputDir, imagePatterns{iPattern}))]; %#ok<AGROW>
end

if isempty(files)
    error('No image files were found in: %s', inputDir);
end

[~, order] = sort({files.name});
files = files(order);

writer = VideoWriter(outputFile, 'MPEG-4');
writer.FrameRate = frameRate;
writer.Quality = quality;
open(writer);
cleanupObj = onCleanup(@() close(writer));

expectedHeight = [];
expectedWidth = [];

fprintf('Writing %d frames to %s\n', numel(files), outputFile);

for iFile = 1:numel(files)
    imagePath = fullfile(files(iFile).folder, files(iFile).name);
    frame = readImageAsRgb(imagePath);

    if iFile == 1
        expectedHeight = size(frame, 1);
        expectedWidth = size(frame, 2);
    elseif size(frame, 1) ~= expectedHeight || size(frame, 2) ~= expectedWidth
        error(['Image size mismatch at file %s. All frames must have the same ' ...
            'height and width for VideoWriter.'], imagePath);
    end

    writeVideo(writer, frame);

    if mod(iFile, 50) == 0 || iFile == numel(files)
        fprintf('Wrote %d / %d frames\n', iFile, numel(files));
    end
end

fprintf('Done. Video saved to: %s\n', outputFile);

function rgb = readImageAsRgb(imagePath)
    [imageData, colorMap, alpha] = imread(imagePath);

    if ~isempty(colorMap)
        rgb = ind2rgb(imageData, colorMap);
    else
        rgb = imageData;
    end

    if ismatrix(rgb)
        rgb = repmat(rgb, 1, 1, 3);
    elseif size(rgb, 3) > 3
        rgb = rgb(:, :, 1:3);
    end

    rgb = convertToUint8(rgb);

    if ~isempty(alpha)
        alpha = convertToUnitDouble(alpha);
        rgb = uint8(double(rgb) .* alpha + 255 * (1 - alpha));
    end
end

function imageData = convertToUint8(imageData)
    if isa(imageData, 'uint8')
        return;
    elseif isfloat(imageData)
        imageData = uint8(round(255 * min(max(imageData, 0), 1)));
    elseif isinteger(imageData)
        imageData = uint8(round(double(imageData) / double(intmax(class(imageData))) * 255));
    else
        imageData = uint8(imageData);
    end
end

function imageData = convertToUnitDouble(imageData)
    if isfloat(imageData)
        imageData = min(max(double(imageData), 0), 1);
    elseif isinteger(imageData)
        imageData = double(imageData) / double(intmax(class(imageData)));
    else
        imageData = double(imageData);
    end
end
