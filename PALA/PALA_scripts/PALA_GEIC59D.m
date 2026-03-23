%% PALA_VivoBrain.m : Post Processing - filtering, localization and tracking for multi algorithms for IN VIVO BRAIN
% Performs ULM on rat brain data.
% IQ are loaded, filtered and processed with localization algorithms.
% For each algorithm, bubbles are detected, localized and tracks.
%
% Created by Arthur Chavignon 25/02/2020 
%
% DATE 2020.12.17 - VERSION 1.1
% AUTHORS: Arthur Chavignon, Baptiste Heiles, Vincent Hingot. CNRS, Sorbonne Universite, INSERM.
% Laboratoire d'Imagerie Biomedicale, Team PPM. 15 rue de l'Ecole de Medecine, 75006, Paris
% Code Available under Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (see https://creativecommons.org/licenses/by-nc-sa/4.0/)
% ACADEMIC REFERENCES TO BE CITED
% Details of the code in the article by Heiles, Chavignon, Hingot, Lopez, Teston and Couture.  
% Performance benchmarking of microbubble-localization algorithms for ultrasound localization microscopy, Nature Biomedical Engineering, 2021.
% General description of super-resolution in: Couture et al., Ultrasound
% localization microscopy and super-resolution: A state of the art, IEEE UFFC 2018
% DATE 2026.02.18 - Version 2.1
% EDITORS: Yibo Wu
% Specified the workflow for CHOP hydrocephalus experiment
run(fullfile(pwd, 'PALA_SetUpPaths.m'))
[listAlgoName,ListColor,ListMarker,ListShortName] = PALA_GetFormat;

%% Selected sample file for loading setup and roi
fprintf('Running PALA_GEIC59D.m\n');t_start =tic;

% GUI select workingdir
workingdir = uigetdir('D:\VSX_Experiments\');
if isequal(workingdir, 0)
    error('No folder selected.');
end
IQroot = fullfile(workingdir, 'IQ');
IQfiles = dir(fullfile(IQroot, '*.mat'));
if isempty(IQfiles)
    error('No .mat file found in %s', IQroot);
elseif numel(IQfiles) > 1
    error('More than one .mat file found in %s', IQroot);
end
filename = IQfiles(1).name;

mydatapath = [workingdir filesep 'IQ' filesep filename]; % add ' num2str(hhh,'%.3d')
trackspath = [workingdir filesep 'Tracks' filesep filename]; mkdir(fileparts(trackspath))
savingpath = [workingdir filesep 'Results' filesep filename]; mkdir(fileparts(savingpath))
IQmat = matfile([IQfiles(1).folder filesep IQfiles(1).name]);

%% Load first 100 frame for Setup (Only run 1 time for 1 experiment)
load([IQfiles(1).folder filesep IQfiles(1).name],'UF','PData');
batchsize = 3000;
batchnum = UF.NbFrames/batchsize;
IQ_batch = IQmat.IQ(:,:,1:batchsize);

% pick ROI here (optional)
I = mean(abs(IQ_batch(:,:,1:500)),3);
figure; imagesc(I); axis image; colormap gray;
caxis([0,quantile(I(:),0.99)]);
title('Draw rectangle, then double-click inside to finalize');

h = drawrectangle;
wait(h); 

pos = round(h.Position);
x1 = max(1, pos(1)); 
y1 = max(1, pos(2));
x2 = min(size(I,2), x1 + pos(3) - 1);
y2 = min(size(I,1), y1 + pos(4) - 1);

% Default ROI (Optional)
x1 = 293; x2 = 821; y1 = 154; y2 = 601;

% Modify parameters
PData(1).Size(1) = y2-y1+1;
PData(1).Size(2)  = x2-x1+1;

UF.NbFrames = size(IQ_batch,3);
PData.Origin = [0 PData.Size(2)/2*PData.PDelta(2) 0];
framerate = UF.FrameRateUF;

SpeedOfSound = 1540;
umperwvl = SpeedOfSound / UF.TxFreq;
dpixwvl  = roundn(80/umperwvl, -2); % hard coding here for 80um grid size
PData(1).PDelta = [dpixwvl, 0, dpixwvl];

%% ULM parameters
res = 5;
ULM = struct('numberOfParticles', 200,...% Number of particles per frame. (30-100)
    'res',res,...                        % Resolution factor. Typically 10 for images at lambda/10.
    'SVD_cutoff',[0.025*UF.NbFrames UF.NbFrames],...    % svd filtering
    'max_linking_distance',2,...        % Maximum linking distance between two frames to reject pairing, in pixels units (UF.scale(1)). (2-4 pixel).
    'min_length', 10,...                % Minimum length of the tracks. (5-20)
    'fwhm',[5 5],...                  % Size of the mask for localization. (3x3 for pixel at lambda, 5x5 at lambda/2). [fmwhz fmwhx]
    'max_gap_closing', 0,...            % Allowed gap in microbubbles pairing. (0)
    'size',[PData.Size(1),PData.Size(2),UF.NbFrames],...
    'scale',[1 1 1/framerate],...       % Scale [z x t]
    'numberOfFramesProcessed',UF.NbFrames,... % Number of processed frames
    'interp_factor',1/res,...            % interpfactor
    'sigmaLCN', 12 ...
    );
% ULM.butter.CuttofFreq = [20 300]*400/1000;       % Cut off frequency (Hz) for additional filter. Typically [20 300] at 1kHz.
ULM.butter.CuttofFreq = [5, 100];
ULM.butter.samplingFreq = framerate;         % Sampling frequency (Hz)
%bandpass
[but_b,but_a] = butter(2,ULM.butter.CuttofFreq/(ULM.butter.samplingFreq/2),'bandpass');
%lowpass    
% Wn = ULM.butter.CuttofFreq(2) / (ULM.butter.samplingFreq/2); 
% [but_b,but_a] = butter(2, Wn, 'low');

ULM.parameters.NLocalMax = 7;           % Safeguard on the number of maxLocal in the fwhm*fwhm grid (3 for fwhm=3, 7 for fwhm=5)
res = ULM.res;

lx = PData.Origin(1) + [0:PData.Size(2)-1].*PData.PDelta(1);
lz = PData.Origin(3) + [0:PData.Size(1)-1].*PData.PDelta(3);
% listAlgo = {'no_shift','wa','interp_cubic','interp_lanczos','interp_spline','gaussian_fit','radial'};
listAlgo = {'gaussian_fit'};
Nalgo = numel(listAlgo);

%% Test SVD
bulles = SVDfilter(IQ_batch(y1:y2,x1:x2,:),[200, 3000]);
% bulles = filter(but_b,but_a,bulles,[],3);
bulles(~isfinite(bulles))=0;
bulles_enh = myEngImg(bulles,ULM.sigmaLCN);

figure; sliceViewer(bulles_enh); %(optional)

% need to complete: 1. save setup parameters 2. UI pick files

%% Do Localization and tracking to each batach
fprintf('--- ULM PROCESSING --- \n\n')
clear Track_tot Track_tot_interp ProcessingTime bulles IQ dB
t1=tic;
for hhh = 1:batchnum % can be run with for loop
    fprintf('Processing bloc %d/%d\n',hhh,batchnum);
    tmp = IQmat.IQ(:,:,1+batchsize*(hhh-1):batchsize*hhh);
    IQ_filt = SVDfilter(tmp(y1:y2,x1:x2,:),ULM.SVD_cutoff);tmp = [];
    IQ_filt(~isfinite(IQ_filt))=0;
    IQ_filt = myEngImg(IQ_filt,ULM.sigmaLCN);

    % Data will be written in a '.mat' file to avoid RAM overdose
    [~,~] = PALA_multiULM(IQ_filt,listAlgo,ULM,PData,'savingfilename',[trackspath 'Tracks' num2str(hhh,'%.3d') '.mat']);
%     [~,~] = PALA_multiULM(IQ_enh,listAlgo,ULM,PData,'savingfilename',[trackspath 'Tracks' num2str(1,'%.3d') '.mat']);
%         [Track_raw,Track_interp,ProTime] = PALA_multiULM(IQ_filt,listAlgo,ULM,PData);
%     save([trackspath 'Tracks' num2str(hhh,'%.3d')],'Track_raw','Track_interp','ProTime','ULM','UF','PData','-v6')
end
t2=toc(t1);
fprintf('ULM done in %d hours %.1f minutes. (for all localization algorithms) \n', floor(t2/60/60), rem(t2/60,60));


%% Create MatOuts     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for each algorithm, create the MatOut density with interpolated tracks for visual analysis, and with non interpolated tracks for aliasing index calculation.
fprintf('--- CREATING MATOUTS --- \n\n')
MatOutSat = [];NbrOfLoc = zeros(Nalgo,1);ProcessingTime = zeros(batchnum,Nalgo);
MatOut = cell(Nalgo,1);MatOut(:)={0};MatOutNoInterp = MatOut;MatOut_vel = MatOut;

hwait = waitbar(0,'Bluiding intensity renderings','Name','Building matouts');
for hhh=1:min(batchnum,999) % Generate MatOut density matrix
% for hhh = 1:1
    load([trackspath 'Tracks' num2str(hhh,'%.3d')],'Track_raw','Track_interp','ProTime')
    waitbar(hhh/batchnum,hwait);
    aa = -PData(1).Origin([3 1])+[1 1]*1;  % get origin
    bb = [1./PData(1).PDelta([3 1])*ULM.res];  % fix the size of pixel
    aa(3) = 0;bb(3) = 1; % for velocity
    for ialgo = 1:Nalgo
        % MatOut and MatOutVel rendering with interpolated tracks
        Track_matout = Track_interp{ialgo};
        Track_matout = cellfun(@(x) (x(:,[1 2 3])+aa).*bb,Track_matout,'UniformOutput',0);
        [MatOut_i,MatOut_vel_i] = ULM_Track2MatOut(Track_matout,ULM.res*[PData(1).Size(1) PData(1).Size(2)]+[1 1]*1,'mode','2D_velmean'); %pos in superpix [z x]
        clear Track_matout
        MatOut_vel{ialgo} = MatOut_vel{ialgo}.*MatOut{ialgo}+MatOut_vel_i.*MatOut_i; % weighted summation
        MatOut{ialgo} = MatOut{ialgo}+MatOut_i;
        MatOut_vel{ialgo}(MatOut{ialgo}>0) = MatOut_vel{ialgo}(MatOut{ialgo}>0)./MatOut{ialgo}(MatOut{ialgo}>0); % average velocity
        MatOutSat(hhh,ialgo) = nnz(MatOut{ialgo}>0); % compute saturation curve
        
        % MatOut without interpolation, for gridding index
        Track_matout = Track_raw{ialgo};
        Track_matout = cellfun(@(x) (x(:,[1 2])+aa(1:2)).*bb(1:2),Track_matout,'UniformOutput',0);
        MatOut_i = ULM_Track2MatOut(Track_matout,ULM.res*[PData(1).Size(1) PData(1).Size(2)]+[1 1]*1); %pos in superpix [z x]
        MatOutNoInterp{ialgo} = MatOutNoInterp{ialgo}+MatOut_i;
        Track_count = cat(1,Track_matout{:});clear Track_matout
        NbrOfLoc(ialgo) = NbrOfLoc(ialgo)+size(Track_count,1);
    end
    ProcessingTime(hhh,:) = ProTime;
end
clear Track_raw Track_interp Track_count Track_matout MatOut_i
save([savingpath 'MatOut_multi'],'MatOut','MatOut_vel','MatOutSat','NbrOfLoc','ULM','listAlgo','Nalgo','PData','UF');
save([savingpath 'MatOut_multi_nointerp'],'MatOutNoInterp','MatOutSat','NbrOfLoc','ULM','listAlgo','PData','Nalgo','UF','ProcessingTime');
close(hwait);clear hwait
%% Display MatOut Intensity
figure(90),clf
% a = tight_subplot(2,ceil(numel(listAlgo)/2));
for ialgo=1:numel(listAlgo)
%     axes(a(ialgo))
    imagesc(MatOut{ialgo}.^(1/3))
    axis image, colormap hot,caxis([0 3])
end

%% Display MatOut Velocimetry
wv = 1540/UF.TxFreq*1e-3/10; % [mm]
figure(91), clf
for ialgo = 1:numel(listAlgo)
    V = MatOut_vel{ialgo} .* wv;
    imagesc(V)
    axis image
    caxis([0 max(V(:))])
    cmap = jet(256);
    cmap(1,:) = [0 0 0];  
    colormap(cmap)
    cb = colorbar;
    cb.Label.String = 'cm/s';
    cb.Label.FontSize = 12;
end

