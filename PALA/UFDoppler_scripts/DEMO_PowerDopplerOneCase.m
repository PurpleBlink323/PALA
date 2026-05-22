%% DEMO_PowerDopplerOneCase
% Select one processed case and calculate the power Doppler image as:
%   PowerDoppler = sum(abs(IQ).^2, 3)

clear
close all
clc

if exist('temp.mat','file')
    load('temp.mat')
    defaultfilepath = currentfolder;
else
    defaultfilepath = 'D:\VSX_Experiments\';
end

casefile = uipickfiles('FilterSpec',defaultfilepath,...
    'Prompt','DEMO: Select one processed case folder',...
    'NumFiles',1,...
    'Output','struct');

if isequal(casefile, 0)
    disp('No case selected.')
    return
end

workingdir = casefile(1).name;
currentfolder = casefile(1).folder;
save('temp.mat','currentfolder','-append')

filtdir = fullfile(workingdir, 'filtImg');
if exist(filtdir, 'dir')
    datadir = filtdir;
    filepattern = 'IQ_filt_*.mat';
    iqvar = 'IQ_filt';
else
    datadir = fullfile(workingdir, 'batches');
    filepattern = 'IQ_batch_*.mat';
    iqvar = 'IQbatch';
end

iqfiles = dir(fullfile(datadir, filepattern));
if isempty(iqfiles)
    error('No IQ files found in: %s', datadir);
end

firstInfo = whos('-file', fullfile(iqfiles(1).folder, iqfiles(1).name), iqvar);
nFramesPerFile = zeros(numel(iqfiles), 1);
nFramesPerFile(1) = firstInfo.size(3);
for ifile = 2:numel(iqfiles)
    fileInfo = whos('-file', fullfile(iqfiles(ifile).folder, iqfiles(ifile).name), iqvar);
    if ~isequal(fileInfo.size(1:2), firstInfo.size(1:2))
        error('IQ frame size mismatch in: %s', iqfiles(ifile).name);
    end
    nFramesPerFile(ifile) = fileInfo.size(3);
end

totalFrames = sum(nFramesPerFile);
firstData = load(fullfile(iqfiles(1).folder, iqfiles(1).name), iqvar);
IQ = firstData.(iqvar);
IQUsed = zeros(firstInfo.size(1), firstInfo.size(2), totalFrames, 'like', IQ);
clear firstData IQ

frameStart = 1;
for ifile = 1:numel(iqfiles)
    fprintf('Loading file %d/%d: %s\n', ifile, numel(iqfiles), iqfiles(ifile).name);
    data = load(fullfile(iqfiles(ifile).folder, iqfiles(ifile).name), iqvar);
    IQ = data.(iqvar);

    frameEnd = frameStart + nFramesPerFile(ifile) - 1;
    IQUsed(:, :, frameStart:frameEnd) = IQ;
    frameStart = frameEnd + 1;
end

sliceViewer(abs(IQUsed)); %(optional)

%% Select the starting frame used for power Doppler
startFrame = min(41, totalFrames); % exclude the first 40 frames by default
parasflag = 1;
while parasflag == 1
    PowerDoppler = sum(abs(IQUsed(:, :, startFrame:end)).^2, 3);

    PowerDopplerDisplay = PowerDoppler.^(1/3);
    PowerDopplerDisplay = PowerDopplerDisplay - min(PowerDopplerDisplay(:));
    PowerDopplerDisplay = PowerDopplerDisplay ./ max(PowerDopplerDisplay(:) + eps);

    figure
    imagesc(PowerDopplerDisplay)
    axis image off
    colormap hot
    colorbar
    title(sprintf('Power Doppler, frames %d-%d', startFrame, totalFrames))

    parasflag = 1-input('Accept current startFrame? yes = 1, no = 0: ');
    if parasflag == 1
        title1 = 'Update Power Doppler Parameters';
        prompt = {'startFrame'};
        dims = [1 75];
        definput = {num2str(startFrame)};
        answer = inputdlg(prompt, title1, dims, definput);

        if isempty(answer)
            disp('Parameter update cancelled. Keeping current startFrame.');
        else
            newStartFrame = round(str2double(answer{1}));
            if isnan(newStartFrame) || newStartFrame < 1 || newStartFrame > totalFrames
                warning('startFrame must be between 1 and %d. Keeping current startFrame.', totalFrames);
            else
                startFrame = newStartFrame;
            end
        end
    end
end

resultsdir = fullfile(workingdir, 'PowerDopplerDemo');
if ~exist(resultsdir, 'dir')
    [status, msg] = mkdir(resultsdir);
    if ~status
        error('Failed to create results folder: %s\nReason: %s', resultsdir, msg);
    end
end

save(fullfile(resultsdir, 'PowerDoppler.mat'), 'PowerDoppler', 'startFrame', ...
    'totalFrames', 'datadir', 'iqvar', '-v7.3');

imwrite(uint16(PowerDopplerDisplay * 65535), fullfile(resultsdir, 'PowerDoppler.tif'));

figure
imagesc(PowerDopplerDisplay)
axis image off
colormap hot
colorbar
title('Power Doppler')

disp(['Saved power Doppler results to: ' resultsdir])
