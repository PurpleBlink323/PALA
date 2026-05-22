function [Track_raw,Track_interp,varargout] = PALA_multiULM_v2(IQ,listAlgo,ULM,PData,varargin)
%% [Track_raw,Track_interp,varargout] = PALA_multiULM_v2(IQ,listAlgo,ULM,PData,varargin)
% Test version of PALA_multiULM with localization results saved separately.
%
% Optional inputs:
%       - tracking: 1/0
%       - savingFileName: tracks output file
%       - localizationFileName: localization input/output file
%
% If IQ is empty and localizationFileName is provided, tracking is computed
% from the saved localization file.

tmp = strcmpi(varargin,'tracking');
if any(tmp),tracking = varargin{find(tmp)+1};else, tracking = 1;end

tmp = strcmpi(varargin,'savingfilename');
if any(tmp),savingFileName = varargin{find(tmp)+1};SaveData = true;else, savingFileName = '';SaveData = false;end

tmp = strcmpi(varargin,'localizationfilename');
if any(tmp)
    localizationFileName = varargin{find(tmp)+1};
elseif SaveData
    localizationFileName = getLocalizationFileName(savingFileName);
else
    localizationFileName = '';
end

if isempty(IQ)
    if isempty(localizationFileName)
        error('localizationFileName is required when IQ is empty.')
    end
    locData = load(localizationFileName,'MatTracking','ProTime','ULM','PData','listAlgo','Nalgo');
    MatTracking = locData.MatTracking;
    ProcessingTime = locData.ProTime;
    ULM = locData.ULM;
    PData = locData.PData;
    listAlgo = locData.listAlgo;
    Nalgo = locData.Nalgo;
else
    [MatTracking,ProcessingTime,ULM,Nalgo] = runLocalization(IQ,listAlgo,ULM,PData);
    if ~isempty(localizationFileName)
        saveLocalization(localizationFileName,MatTracking,ProcessingTime,ULM,PData,listAlgo,Nalgo);
    end
end

[Track_raw,Track_interp] = runTracking(MatTracking,listAlgo,ULM,tracking);

if nargout == 3
    varargout{1} = ProcessingTime;
end

if SaveData
    fprintf('saving... ')
    ProTime = ProcessingTime;
    save(savingFileName,'Track_raw','Track_interp','ProTime','ULM','PData','listAlgo','Nalgo','-v6')
end
fprintf('end.\n')
end

function [MatTracking,ProcessingTime,ULM,Nalgo] = runLocalization(IQ,listAlgo,ULM,PData)
if ~isfield(ULM,'parameters')
    ULM.parameters = struct();
end
if ~isfield(ULM.parameters,'NLocalMax')
    ULM.parameters.NLocalMax = 3;
end

ULM.max_linking_distance = ULM.max_linking_distance*PData.PDelta(3);
IQ = abs(IQ);
Nalgo = numel(listAlgo);
ProcessingTime = zeros(Nalgo,1);
MatTracking = cell(1,Nalgo);

fprintf('Localization algo: ')
for ialgo = 1:Nalgo
    fprintf([num2str(ialgo) ' '])
    t0 = tic;
    ULM = setLocalizationMethod(ULM,listAlgo{ialgo});
    MatTracking{ialgo} = ULM_localization2D(IQ,ULM);
    ProcessingTime(ialgo) = toc(t0);
    MatTracking{ialgo}(:,2:3) = (MatTracking{ialgo}(:,2:3) - [1 1]).*PData.PDelta([3 1]) + [PData.Origin(3) PData.Origin(1)];
end
end

function [Track_raw,Track_interp] = runTracking(MatTracking,listAlgo,ULM,tracking)
Nalgo = numel(listAlgo);
Track_raw = cell(1,Nalgo);
Track_interp = cell(1,Nalgo);

fprintf('Tracking algo: ')
for ialgo = 1:Nalgo
    fprintf([num2str(ialgo) ' '])
    if tracking
        [Track_raw{ialgo},Track_interp{ialgo}] = ULM_tracking2D(double(MatTracking{ialgo}),ULM,'pala');
    else
        Track_raw{ialgo} = {single(MatTracking{ialgo})};
        Track_interp{ialgo} = {};
    end
    Track_interp{ialgo} = cellfun(@single,Track_interp{ialgo},'UniformOutput',false);
    Track_raw{ialgo} = cellfun(@single,Track_raw{ialgo},'UniformOutput',false);
end
end

function ULM = setLocalizationMethod(ULM,algo)
switch lower(algo)
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
end

function saveLocalization(localizationFileName,MatTracking,ProcessingTime,ULM,PData,listAlgo,Nalgo)
[savingPath,~,~] = fileparts(localizationFileName);
if ~isempty(savingPath) && ~exist(savingPath,'dir')
    mkdir(savingPath);
end
ProTime = ProcessingTime;
save(localizationFileName,'MatTracking','ProTime','ULM','PData','listAlgo','Nalgo','-v6')
end

function localizationFileName = getLocalizationFileName(savingFileName)
[savingPath,savingName,savingExt] = fileparts(savingFileName);
localizationFileName = fullfile(savingPath,'localization',[savingName savingExt]);
end
