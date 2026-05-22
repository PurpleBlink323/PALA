baselineDir = allimagepath{1};
baselineResultsDir = fullfile(baselineDir, 'Results');
vascularMapDir = fullfile(baselineResultsDir, 'vascularMaps');
bloodVelocityMapDir = fullfile(baselineResultsDir, 'bloodVelocityMaps');

if ~exist(vascularMapDir, 'dir')
    [status, msg] = mkdir(vascularMapDir);
    if ~status
        error('Failed to create vascular map folder: %s\nReason: %s', vascularMapDir, msg);
    end
end
if ~exist(bloodVelocityMapDir, 'dir')
    [status, msg] = mkdir(bloodVelocityMapDir);
    if ~status
        error('Failed to create blood velocity map folder: %s\nReason: %s', bloodVelocityMapDir, msg);
    end
end

for ip = 1:npath
    workingdir = allimagepath{ip};
    [~,caseName] = fileparts(workingdir);
    caseName = matlab.lang.makeValidName(caseName);
    resultsdir = fullfile(workingdir, 'Results');

    fprintf('Collecting maps from path %d/%d: %s\n', ip, npath, workingdir);

    sourceFile = fullfile(resultsdir, 'vascular_map.tif');
    if exist(sourceFile, 'file')
        copyfile(sourceFile, fullfile(vascularMapDir, [caseName '_vascular_map.tif']));
    else
        warning('Missing vascular map: %s', sourceFile)
    end

    sourceFile = fullfile(resultsdir, 'blood_velocity_map.tif');
    if exist(sourceFile, 'file')
        copyfile(sourceFile, fullfile(bloodVelocityMapDir, [caseName '_blood_velocity_map.tif']));
    else
        warning('Missing blood velocity map: %s', sourceFile)
    end
end
