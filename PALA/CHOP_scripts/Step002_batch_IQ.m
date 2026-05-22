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
    batchsize = 1000;
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
    
        batchfile = fullfile(batchdir, sprintf('IQ_batch_%03d.mat', hhh));
        expectedSize = [y2-y1+1, x2-x1+1, endIdx-startIdx+1];
        if isValidIQBatch(batchfile, expectedSize, startIdx, endIdx)
            fprintf('Skipping existing batch %d/%d: frames %d to %d\n', ...
                hhh, batchnum, startIdx, endIdx);
            continue
        end
    
        fprintf('Saving batch %d/%d: frames %d to %d\n', ...
            hhh, batchnum, startIdx, endIdx);
    
        % Extract ROI IQ batch
        IQbatch = IQmat.IQ(y1:y2, x1:x2, startIdx:endIdx);
    
        % Make a copy of UF for this batch
        UFbatch = UF;
        UFbatch.NbFrames = size(IQbatch, 3);
        UFbatch.startIdx = startIdx;
        UFbatch.endIdx = endIdx;
    
        % Save to a temporary file first so interrupted writes do not corrupt
        % an existing usable batch.
        tempbatchfile = fullfile(batchdir, sprintf('IQ_batch_%03d.tmp.mat', hhh));
        save(tempbatchfile, 'IQbatch', 'UFbatch', 'PData', '-v7.3', '-nocompression');
        if ~isValidIQBatch(tempbatchfile, expectedSize, startIdx, endIdx)
            error('Failed to validate temporary batch file: %s', tempbatchfile);
        end
        [status, msg] = movefile(tempbatchfile, batchfile, 'f');
        if ~status
            error('Failed to move temporary batch file to: %s\nReason: %s', batchfile, msg);
        end
    
    end
    save([workingdir,'\PTVparas.mat'],'batchnum','-append')

    %% release memory
    save('temp.mat','ip','-append')
    clear
    close all

    load('temp.mat')
end
disp('All done!')

end

function isValid = isValidIQBatch(batchfile, expectedSize, startIdx, endIdx)
isValid = false;
if ~exist(batchfile, 'file')
    return
end

try
    vars = whos('-file', batchfile);
    names = {vars.name};
    iqIdx = strcmp(names, 'IQbatch');
    if ~any(iqIdx) || ~isequal(vars(iqIdx).size, expectedSize)
        return
    end
    if ~any(strcmp(names, 'UFbatch')) || ~any(strcmp(names, 'PData'))
        return
    end

    loaded = load(batchfile, 'UFbatch');
    if ~isfield(loaded, 'UFbatch') || ...
            ~isfield(loaded.UFbatch, 'startIdx') || ...
            ~isfield(loaded.UFbatch, 'endIdx') || ...
            loaded.UFbatch.startIdx ~= startIdx || ...
            loaded.UFbatch.endIdx ~= endIdx || ...
            loaded.UFbatch.NbFrames ~= expectedSize(3)
        return
    end

    isValid = true;
catch
    isValid = false;
end
end
