function resultsPath = WF_ResolveResultsFolder(selectedPath)
selectedPath = char(string(selectedPath));
candidate = fullfile(selectedPath, 'Results');
if isfolder(candidate)
    resultsPath = candidate;
    return
end

if ~isempty(dir(fullfile(selectedPath, '*_multi.mat')))
    resultsPath = selectedPath;
    return
end

error('Expected a Results folder or *_multi.mat file under %s.', selectedPath);
