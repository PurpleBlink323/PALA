function Step001_crop_IQ
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
    'Prompt','Step001: Select all the cases(folder) to be processed',...
    'Output','struct');
currentfolder = allfiles(1).folder;

allimagepath = {allfiles.name}';
npath = length(allimagepath);

save('temp.mat','currentfolder','allimagepath','npath');

% UI for input paras(plan)
redoflag = 0; % Initialize redoflag for ROI selection
%%
for ip = 1:npath
    %% create IQ mat
    workingdir = allimagepath{ip};
    IQdir = [workingdir filesep 'IQ'];
    IQfiles = dir([IQdir filesep '*.mat']);
    IQmat = matfile([IQfiles(1).folder filesep IQfiles(1).name]); % GEIC59D: 1 mat/1 test
    
    load([IQfiles(1).folder filesep IQfiles(1).name],'UF','PData'); % IQ paras
    batchsize = 100;
    IQ_batch = IQmat.IQ(:,:,501:500+batchsize);

    %% select ROI
    if (ip == 1) ||(redoflag == 1)
        I = mean(abs(IQ_batch),3);
        figure; imagesc(I); axis image; colormap gray;
        clim([0,quantile(I(:),0.99)]);
        title('Draw rectangle, then double-click inside to finalize');
        
        h = drawrectangle;
        wait(h); 
        
        pos = round(h.Position);
        x1 = max(1, pos(1)); 
        y1 = max(1, pos(2));
        x2 = min(size(I,2), x1 + pos(3) - 1);
        y2 = min(size(I,1), y1 + pos(4) - 1);
    end
    % Modify parameters
    PData(1).Size(1) = y2-y1+1;
    PData(1).Size(2)  = x2-x1+1;
    PData.Origin = [0 PData.Size(2)/2*PData.PDelta(2) 0];
    
    SpeedOfSound = 1540;
    umperwvl = SpeedOfSound / UF.TxFreq;
    dpixwvl  = roundn(80/umperwvl, -2); % hard coding here for 80um grid size
    PData(1).PDelta = [dpixwvl, 0, dpixwvl];
    roi.x1 = x1; roi.y1 = y1; roi.x2 = x2; roi.y2 = y2;

    %% save PTVParas
    save([workingdir,'\PTVparas.mat'],'PData','roi')

    %% release memory
    save('temp.mat','ip','-append')
    clear
    close all

    load('temp.mat')
end
disp('All done!')

end