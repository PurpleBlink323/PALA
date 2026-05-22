function Step004_localizationTracking
%%
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
    'Prompt','Step003: Select all the cases(folder) to be processed',...
    'Output','struct');
currentfolder = allfiles(1).folder;

allimagepath = {allfiles.name}';
npath = length(allimagepath);

save('temp.mat','currentfolder','allimagepath','npath');

for ip = 1:npath
    t1=tic;
    workingdir = allimagepath{ip};
    filtdir = fullfile(workingdir, 'filtImg');
    trackdir = fullfile(workingdir, 'tracks');
    if ~exist(trackdir, 'dir')
        [status, msg] = mkdir(trackdir);
        if ~status
            error('Failed to create tracks folder: %s\nReason: %s', trackdir, msg);
        end
    end
    
    load([workingdir,'\PTVparas.mat'],'batchnum','Enhparas')
    for hhh = 1:batchnum
     fprintf('Processing path %d/%d, batch %d/%d...\n', ...
        ip, npath, hhh, batchnum);
     %% Load filtered images
     load(fullfile(filtdir, sprintf('IQ_filt_%03d.mat', hhh)), ...
        'IQ_filt', 'PData');
     [~,~] = PALA_multiULM(IQ_filt,{'gaussian_fit'},Enhparas.ULM,PData,'savingfilename',[trackdir filesep 'Tracks' num2str(hhh,'%.3d') '.mat']);
    end
    t2=toc(t1);
    fprintf('ULM done in %d hours %.1f minutes. (for all localization algorithms) \n', floor(t2/60/60), rem(t2/60,60));
end
end