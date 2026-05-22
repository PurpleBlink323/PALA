function [Track_raw,Track_interp] = PALA_tracking(MatTracking,ULM,PData,varargin)
if ~isfield(ULM,'parameters')% Create an empty structure for parameters hosting
    ULM.parameters = struct();
end

% Convert the max_linking_distance into a appropriate scaling, the same as MatTracking
ULM.max_linking_distance = ULM.max_linking_distance*PData.PDelta(3);

%% Tracking algorithm
[Track_raw,Track_interp] = ULM_tracking2D(double(MatTracking),ULM,'pala');

Track_interp = cellfun(@single,Track_interp,'UniformOutput',false);
Track_raw = cellfun(@single,Track_raw,'UniformOutput',false);

end
