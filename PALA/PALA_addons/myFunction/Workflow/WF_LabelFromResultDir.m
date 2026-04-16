function label = WF_LabelFromResultDir(resultDir)
experimentDir = fileparts(char(string(resultDir)));
[~, label] = fileparts(experimentDir);
if isempty(label)
    [~, label] = fileparts(char(string(resultDir)));
end
