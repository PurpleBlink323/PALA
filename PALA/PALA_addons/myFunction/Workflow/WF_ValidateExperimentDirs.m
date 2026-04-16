function [experimentDirs, labels] = WF_ValidateExperimentDirs(experimentDirs)
labels = cell(numel(experimentDirs), 1);
for i = 1:numel(experimentDirs)
    experimentDirs{i} = char(string(experimentDirs{i}));
    if ~isfolder(experimentDirs{i})
        error('Experiment folder does not exist: %s', experimentDirs{i});
    end

    iqDir = fullfile(experimentDirs{i}, 'IQ');
    if ~isfolder(iqDir)
        error('Experiment %s does not contain an IQ folder.', experimentDirs{i});
    end

    iqFiles = dir(fullfile(iqDir, '*.mat'));
    iqFiles = iqFiles(~[iqFiles.isdir]);
    if numel(iqFiles) ~= 1
        error('Experiment %s must contain exactly one IQ .mat file.', experimentDirs{i});
    end

    [~, labels{i}] = fileparts(experimentDirs{i});
end
