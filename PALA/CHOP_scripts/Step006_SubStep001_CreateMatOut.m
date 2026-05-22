for ip = 1:npath
    workingdir = allimagepath{ip};
    trackingdir = fullfile(workingdir, 'trackingResults');
    resultsdir = fullfile(workingdir, 'Results');
    if ~exist(resultsdir, 'dir')
        [status, msg] = mkdir(resultsdir);
        if ~status
            error('Failed to create results folder: %s\nReason: %s', resultsdir, msg);
        end
    end

    load([workingdir,'\PTVparas.mat'],'batchnum')

    fprintf('--- CREATING MATOUTS: path %d/%d --- \n\n', ip, npath)
    MatOutSat = zeros(batchnum,1);
    NbrOfLoc = 0;
    MatOut = 0;
    MatOutNoInterp = 0;
    MatOut_vel = 0;

    hwait = waitbar(0,'Building intensity renderings','Name','Building matouts');
    for hhh = 1:batchnum
        waitbar(hhh/batchnum,hwait);
        fprintf('Processing path %d/%d, batch %d/%d...\n', ...
            ip, npath, hhh, batchnum);

        load(fullfile(trackingdir, sprintf('Tracks_%03d.mat', hhh)), ...
            'Track_raw', 'Track_interp', 'Trackparas', 'Locparas', 'PData', 'UFbatch');

        ULM = Trackparas.ULM;
        aa = -PData(1).Origin([3 1])+[1 1]*1;  % get origin
        bb = 1./PData(1).PDelta([3 1])*ULM.res;  % fix the size of pixel
        aa(3) = 0;bb(3) = 1; % for velocity
        sizeOut = ULM.res*[PData(1).Size(1) PData(1).Size(2)]+[1 1]*1;

        % MatOut and MatOutVel rendering with interpolated tracks
        Track_matout = Track_interp;
        Track_matout = cellfun(@(x) (x(:,[1 2 3])+aa).*bb,Track_matout,'UniformOutput',0);
        [MatOut_i,MatOut_vel_i] = ULM_Track2MatOut(Track_matout,sizeOut,'mode','2D_velmean'); % pos in superpix [z x]
        clear Track_matout
        MatOut_vel = MatOut_vel.*MatOut+MatOut_vel_i.*MatOut_i; % weighted summation
        MatOut = MatOut+MatOut_i;
        MatOut_vel(MatOut>0) = MatOut_vel(MatOut>0)./MatOut(MatOut>0); % average velocity
        MatOutSat(hhh,1) = nnz(MatOut>0); % compute saturation curve

        % MatOut without interpolation, for gridding index
        Track_matout = Track_raw;
        Track_matout = cellfun(@(x) (x(:,[1 2])+aa(1:2)).*bb(1:2),Track_matout,'UniformOutput',0);
        MatOut_i = ULM_Track2MatOut(Track_matout,sizeOut); % pos in superpix [z x]
        MatOutNoInterp = MatOutNoInterp+MatOut_i;
        if isempty(Track_matout)
            Track_count = [];
        else
            Track_count = cat(1,Track_matout{:});
        end
        clear Track_matout
        NbrOfLoc = NbrOfLoc+size(Track_count,1);
    end
    close(hwait);clear hwait
    clear Track_raw Track_interp Track_count Track_matout MatOut_i MatOut_vel_i

    save(fullfile(resultsdir, 'MatOut'), ...
        'MatOut', 'MatOut_vel', 'MatOutSat', 'NbrOfLoc', 'ULM', 'Trackparas', 'Locparas', 'PData', 'UFbatch', '-v7.3','-nocompression');
    save(fullfile(resultsdir, 'MatOut_nointerp'), ...
        'MatOutNoInterp', 'MatOutSat', 'NbrOfLoc', 'ULM', 'Trackparas', 'Locparas', 'PData', 'UFbatch', '-v7.3','-nocompression');
end
