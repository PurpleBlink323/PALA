function iqStem = WF_DetectIqStem(matoutFileName)
iqStem = erase(matoutFileName, '.mat');
iqStem = erase(iqStem, '_MatOut_multi');
