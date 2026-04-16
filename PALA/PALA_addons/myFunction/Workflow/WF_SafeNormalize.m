function normalized = WF_SafeNormalize(values)
normalized = nan(size(values));
if isempty(values) || ~isfinite(values(1)) || values(1) == 0
    return
end
normalized = values ./ values(1);
