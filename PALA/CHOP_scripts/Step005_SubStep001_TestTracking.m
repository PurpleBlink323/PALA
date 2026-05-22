for ip = 1:npath
    parasflag = 1;

    workingdir = allimagepath{ip};
    localizationdir = fullfile(workingdir, 'localizationResults');
    filtdir = fullfile(workingdir, 'filtImg');
    tracktestdir = fullfile(workingdir, 'tracktest');
    if ~exist(tracktestdir, 'dir')
        [status, msg] = mkdir(tracktestdir);
        if ~status
            error('Failed to create track test folder: %s\nReason: %s', tracktestdir, msg);
        end
    end

    load([workingdir,'\PTVparas.mat'],'batchnum','Enhparas')
    parasInfo = whos('-file',[workingdir,'\PTVparas.mat']);
    if any(strcmp({parasInfo.name}, 'Locparas'))
        load([workingdir,'\PTVparas.mat'],'Locparas')
        ULM = Locparas.ULM;
    else
        Locparas.Algo = 'gaussian_fit';
        Locparas.ULM = Enhparas.ULM;
        ULM = Enhparas.ULM;
    end

    batchidx = ceil(batchnum/2);
    startidx = 1;
    endidx = ULM.size(3);

    while parasflag == 1
        title1 = 'Update Tracking Parameters';

        prompt = { ...
            'batchidx', ...
            'startidx', ...
            'endidx', ...
            'ULM.max_linking_distance', ...
            'ULM.min_length', ...
            'ULM.max_gap_closing'};

        dims = [1 75];

        definput = { ...
            num2str(batchidx), ...
            num2str(startidx), ...
            num2str(endidx), ...
            num2str(ULM.max_linking_distance), ...
            num2str(ULM.min_length), ...
            num2str(ULM.max_gap_closing)};

        answer = inputdlg(prompt, title1, dims, definput);

        if isempty(answer)
            disp('Parameter update cancelled. Keeping current tracking parameters.');
        else
            batchidx = round(str2double(answer{1}));
            startidx = round(str2double(answer{2}));
            endidx = round(str2double(answer{3}));
            ULM.max_linking_distance = str2double(answer{4});
            ULM.min_length = str2double(answer{5});
            ULM.max_gap_closing = str2double(answer{6});
        end

        batchidx = max(1,min(batchidx,batchnum));
        load(fullfile(localizationdir, sprintf('Loc_%03d.mat', batchidx)), ...
            'MatTracking', 'PData', 'UFbatch');
        startidx = max(1,min(startidx,max(MatTracking(:,4))));
        endidx = max(startidx,min(endidx,max(MatTracking(:,4))));

        TestIndex = MatTracking(:,4) >= startidx & MatTracking(:,4) <= endidx;
        MatTrackingTest = MatTracking(TestIndex,:);
        if isempty(MatTrackingTest)
            warning('No localization points found in selected frame range.')
            Track_raw = {};
            Track_interp = {};
            minTrackingFrame = startidx;
        else
            minTrackingFrame = min(MatTrackingTest(:,4));
            [Track_raw,Track_interp] = PALA_tracking(MatTrackingTest, ULM, PData);
        end

        save(fullfile(tracktestdir, sprintf('TrackTest_%03d_%04d_%04d.mat', batchidx, startidx, endidx)), ...
            'Track_raw', 'Track_interp', 'ULM', 'PData', 'UFbatch', 'startidx', 'endidx', 'batchidx', 'minTrackingFrame', '-v7.3','-nocompression');

        load(fullfile(filtdir, sprintf('IQ_filt_%03d.mat', batchidx)), ...
            'IQ_filt');

        for iframe = startidx:endidx
            img = abs(IQ_filt(:,:,iframe));
            rgbFrame = makeTrackFrame(img, Track_raw, iframe, minTrackingFrame, PData);
            imwrite(rgbFrame, fullfile(tracktestdir, sprintf('batch%03d_frame%04d.png', batchidx, iframe)));
        end

        parasflag = 1-input('Accept current tracking parameters? yes = 1, no = 0: ');
    end

    Trackparas.ULM = ULM;
    Trackparas.TestBatch = batchidx;
    Trackparas.TestFrameRange = [startidx endidx];
    Locparas.ULM = ULM;
    Enhparas.ULM = ULM;
    save(fullfile(workingdir, 'PTVparas.mat'), 'Trackparas', 'Locparas', 'Enhparas', '-append')
    close all
end

function rgbFrame = makeTrackFrame(img, Track_raw, iframe, minTrackingFrame, PData)
img = img - min(img(:));
img = img./max(img(:) + eps);
grayFrame = uint8(img*255);
rgbFrame = repmat(grayFrame,1,1,3);

for itrack = 1:numel(Track_raw)
    track = Track_raw{itrack};
    if size(track,2) < 3
        continue
    end
    trackIndex = track(:,3) <= iframe-minTrackingFrame+1;
    if any(trackIndex)
        locZ = (track(trackIndex,1) - PData.Origin(3))./PData.PDelta(3) + 1;
        locX = (track(trackIndex,2) - PData.Origin(1))./PData.PDelta(1) + 1;
        for ipoint = 2:numel(locX)
            rgbFrame = drawLineOnImage(rgbFrame, locX(ipoint-1), locZ(ipoint-1), locX(ipoint), locZ(ipoint), uint8([255 255 0]));
        end
        rgbFrame = drawCrossOnImage(rgbFrame, locX(end), locZ(end), uint8([0 255 0]), 3);
    end
end
end

function rgbFrame = drawLineOnImage(rgbFrame, x1, y1, x2, y2, color)
nPoints = max(abs(round([x2-x1 y2-y1]))) + 1;
xList = round(linspace(x1,x2,nPoints));
yList = round(linspace(y1,y2,nPoints));
[height,width,~] = size(rgbFrame);
validIndex = xList >= 1 & xList <= width & yList >= 1 & yList <= height;
xList = xList(validIndex);
yList = yList(validIndex);
for ipoint = 1:numel(xList)
    rgbFrame(yList(ipoint),xList(ipoint),:) = reshape(color,1,1,3);
end
end

function rgbFrame = drawCrossOnImage(rgbFrame, x, y, color, markerSize)
x = round(x);
y = round(y);
[height,width,~] = size(rgbFrame);
for offset = -markerSize:markerSize
    xx = x + offset;
    if xx >= 1 && xx <= width && y >= 1 && y <= height
        rgbFrame(y,xx,:) = reshape(color,1,1,3);
    end
    yy = y + offset;
    if x >= 1 && x <= width && yy >= 1 && yy <= height
        rgbFrame(yy,x,:) = reshape(color,1,1,3);
    end
end
end
