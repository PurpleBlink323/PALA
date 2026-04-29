function Step002_batch_IQ
%%
clear
close all
clc

% get data path
if exist('temp.mat','file')
    load('temp.mat')
    defaultfilepath = currentfolder;
else
    defaultfilepath = 'D:\VSX_Experiments\';
end
allfiles = uipickfiles('FilterSpec',defaultfilepath,...
    'Prompt','Step002: Select all the cases(folder) to be processed',...
    'Output','struct');
currentfolder = allfiles(1).folder;

allimagepath = {allfiles.name}';
npath = length(allimagepath);

save('temp.mat','currentfolder','allimagepath','npath');
%%
for ip = 1:npath
    %% create IQ mat
    workingdir = allimagepath{ip};
    IQdir = [workingdir filesep 'IQ'];
    IQfiles = dir([IQdir filesep '*.mat']);
    IQmat = matfile([IQfiles(1).folder filesep IQfiles(1).name]); % GEIC59D: 1 mat/1 test

    load([IQfiles(1).folder filesep IQfiles(1).name],'UF')
    load([workingdir,'\PTVparas.mat'],'PData','roi')
    % Define the region of interest (ROI) for extracting IQ data
    y1 = roi.y1; y2 = roi.y2; x1 = roi.x1; x2 = roi.x2;

    %% Save IQ batches
    batchsize = 3000;
    nFrames = UF.NbFrames;
    batchnum = ceil(nFrames / batchsize);
    
    batchdir = fullfile(workingdir, 'batches');
    
    if ~exist(batchdir, 'dir')
        [status, msg] = mkdir(batchdir);
        if ~status
            error('Failed to create batch folder: %s\nReason: %s', batchdir, msg);
        end
    end
    
    for hhh = 1:batchnum
    
        startIdx = (hhh - 1) * batchsize + 1;
        endIdx   = min(hhh * batchsize, nFrames);
    
        fprintf('Saving batch %d/%d: frames %d to %d\n', ...
            hhh, batchnum, startIdx, endIdx);
    
        % Extract ROI IQ batch
        IQbatch = IQmat.IQ(y1:y2, x1:x2, startIdx:endIdx);
    
        % Make a copy of UF for this batch
        UFbatch = UF;
        UFbatch.NbFrames = size(IQbatch, 3);
        UFbatch.startIdx = startIdx;
        UFbatch.endIdx = endIdx;
    
        % Save IQbatch, UFbatch, and PData
        save(fullfile(batchdir, sprintf('IQ_batch_%03d.mat', hhh)), ...
            'IQbatch', 'UFbatch', 'PData', '-v7.3');
    
    end

    %% release memory
    save('temp.mat','ip','-append')
    clear
    close all

    load('temp.mat')
end
disp('All done!')

end