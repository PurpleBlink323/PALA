function [mapValue, cppValue] = WF_ComputeMapCpp(sysValue, diaValue, icpValue)
mapValue = nan;
cppValue = nan;
if isfinite(sysValue) && isfinite(diaValue)
    mapValue = (sysValue + 2 * diaValue) / 3;
end
if isfinite(mapValue) && isfinite(icpValue)
    cppValue = mapValue - icpValue;
end
