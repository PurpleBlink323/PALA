function [MatTracking] = PALA_localization(IQ,Algo,ULM,PData,varargin)
if ~isfield(ULM,'parameters')% Create an empty structure for parameters hosting
    ULM.parameters = struct();
end
if ~isfield(ULM.parameters,'NLocalMax')
    ULM.parameters.NLocalMax = 3; % safeguard
end

% Convert the max_linking_distance into a appropriate scaling, the same as MatTracking
ULM.max_linking_distance = ULM.max_linking_distance*PData.PDelta(3);

%% Start localization for each compared algorithms.
IQ = abs(IQ);

switch lower(Algo)
    case {'wa','weighted_average'}
        ULM.LocMethod = 'wa';

    case {'radial','radial_vivo','radial_silicio'}
        ULM.LocMethod = 'radial';

    case {'radial_sg'}
        ULM.LocMethod = 'radial_sg';

    case 'interp_cubic'
        ULM.LocMethod = 'interp';
        ULM.parameters.InterpMethod = 'cubic';

    case 'interp_lanczos'
        ULM.LocMethod = 'interp';
        ULM.parameters.InterpMethod = 'lanczos3';

    case {'interp_spline'}
        ULM.LocMethod = 'interp';
        ULM.parameters.InterpMethod = 'spline';

    case 'gaussian_fit'
        ULM.LocMethod = 'curvefitting';

    case {'interp_bilinear','no_localization','no_shift'}
        ULM.LocMethod = 'nolocalization';
    otherwise
        error('Wrong method selected')
end
    [MatTracking] = ULM_localization2D(IQ,ULM);
    % MatTracking is the table that stores particles' values and positions
    % convert MatTracking from pixel to \lambda
    MatTracking(:,2:3) = (MatTracking(:,2:3) - [1 1]).*PData.PDelta([3 1]) + [PData.Origin(3) PData.Origin(1)]; % good origin
end
