function selectedPath = WF_ResolveSelectedFolder(selection)
selectedPath = '';
if isfield(selection, 'folder') && isfield(selection, 'name')
    combinedPath = fullfile(selection.folder, selection.name);
    if isfolder(combinedPath)
        selectedPath = combinedPath;
    elseif isfolder(selection.name)
        selectedPath = selection.name;
    elseif isfolder(selection.folder)
        selectedPath = selection.folder;
    end
elseif isfield(selection, 'name') && isfolder(selection.name)
    selectedPath = selection.name;
end

if isempty(selectedPath)
    error('Could not resolve the selected folder.');
end
