function label = WF_LabelFromPath(pathValue)
[~, label] = fileparts(char(string(pathValue)));
if isempty(label)
    label = char(string(pathValue));
end
