function experimentDirs = WF_ResolveExperimentDirs(experimentDirs, defaultRoot)
if isempty(experimentDirs)
    allfiles = uipickfiles( ...
        'FilterSpec', char(string(defaultRoot)), ...
        'Prompt', 'Select experiment folders', ...
        'Output', 'struct');
    if isempty(allfiles)
        error('No experiment folders selected.');
    end

    experimentDirs = cell(numel(allfiles), 1);
    for i = 1:numel(allfiles)
        experimentDirs{i} = WF_ResolveSelectedFolder(allfiles(i));
    end
elseif ischar(experimentDirs) || isstring(experimentDirs)
    experimentDirs = cellstr(string(experimentDirs(:)));
elseif iscell(experimentDirs)
    experimentDirs = cellfun(@(x) char(string(x)), experimentDirs(:), 'UniformOutput', false);
else
    error('Unsupported experimentDirs input.');
end
