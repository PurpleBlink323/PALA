for ip = 1:npath
    workingdir = allimagepath{ip};
    resultsdir = fullfile(workingdir, 'Results');

    fprintf('--- CREATING VASCULAR AND BLOOD VELOCITY MAPS: path %d/%d --- \n\n', ip, npath)
    load(fullfile(resultsdir, 'MatOut.mat'), ...
        'MatOut', 'MatOut_vel', 'MatOutSat', 'NbrOfLoc', 'ULM', 'Trackparas', 'Locparas', 'PData', 'UFbatch');

    IntPower = 1/3;
    SigmaGauss = 0;

    MatOut = MatOut{1}; MatOut_vel = MatOut_vel{1};
    vascularMap = MatOut.^IntPower;
    if SigmaGauss > 0
        vascularMap = imgaussfilt(vascularMap,SigmaGauss);
    end
    vascularCaxis = [0 max(vascularMap(:))*0.8];
    if vascularCaxis(2) <= 0
        vascularCaxis(2) = 1;
    end
    vascularMapRGB = ind2rgb(gray2ind(min(vascularMap,vascularCaxis(2))./vascularCaxis(2),128),hot(128));

    validVelocity = MatOut_vel(isfinite(MatOut_vel) & MatOut_vel > 0);
    if isempty(validVelocity)
        vmax_disp = 1;
    else
        vmax_disp = ceil(quantile(validVelocity,.98)/10)*10;
        if vmax_disp <= 0
            vmax_disp = max(validVelocity(:));
        end
    end

    clbsize = [min(180,size(MatOut_vel,1)),min(50,size(MatOut_vel,2))];
    velocityMap = MatOut_vel/vmax_disp;
    velocityMap(~isfinite(velocityMap)) = 0;
    velocityMap(velocityMap > 1) = 1;
    velocityMap(velocityMap < 0) = 0;
    velocityMap(1:clbsize(1),1:clbsize(2)) = repmat(linspace(1,0,clbsize(1))',1,clbsize(2));
    velocityMap = velocityMap.^(1/1.5);
    velocityMapRGB = ind2rgb(gray2ind(velocityMap,256),jet(256));

    MatShadow = MatOut;
    maxShadow = max(MatShadow(:));
    if maxShadow > 0
        MatShadow = MatShadow./(maxShadow*.3);
    end
    MatShadow(MatShadow > 1) = 1;
    MatShadow(1:clbsize(1),1:clbsize(2)) = repmat(linspace(0,1,clbsize(2)),clbsize(1),1);
    velocityMapRGB = velocityMapRGB.*(MatShadow.^IntPower);
    velocityMapRGB = brighten(velocityMapRGB,.4);

    imwrite(vascularMapRGB, fullfile(resultsdir, 'vascular_map.png'));
    imwrite(vascularMapRGB, fullfile(resultsdir, 'vascular_map.tif'));
    imwrite(velocityMapRGB, fullfile(resultsdir, 'blood_velocity_map.png'));
    imwrite(velocityMapRGB, fullfile(resultsdir, 'blood_velocity_map.tif'));

%     save(fullfile(resultsdir, 'Maps'), ...
%         'vascularMap', 'vascularMapRGB', 'vascularCaxis', ...
%         'velocityMap', 'velocityMapRGB', 'vmax_disp', ...
%         'MatOutSat', 'NbrOfLoc', 'ULM', 'Trackparas', 'Locparas', 'PData', 'UFbatch', ...
%         '-v7.3','-nocompression');
end
