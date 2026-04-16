function physiology = PALA_LoadLabChartPreExp(varargin)
%PALA_LOADLABCHARTPREEXP Load pre/exp LabChart physiology data for CHOP runs.
%   physiology = PALA_LoadLabChartPreExp() interactively selects a LabChart
%   folder and a timestamp file, then returns aligned physiology signals and
%   summary metrics for each timestamp window.
%
%   physiology = PALA_LoadLabChartPreExp('ExpectedWindows', N) additionally
%   validates that the number of aligned windows equals N.

parser = inputParser;
parser.addParameter('LabChartFolder', '', @(x) ischar(x) || isstring(x));
parser.addParameter('TimestampFile', '', @(x) ischar(x) || isstring(x));
parser.addParameter('DefaultRoot', 'D:\', @(x) ischar(x) || isstring(x));
parser.addParameter('ExpectedWindows', [], @(x) isempty(x) || (isscalar(x) && isnumeric(x)));
parser.parse(varargin{:});
opts = parser.Results;

scriptDir = fileparts(mfilename('fullpath'));
sdkRoot = iFindSdkRoot(scriptDir);
addpath(genpath(sdkRoot));

labChartFolder = char(string(opts.LabChartFolder));
if isempty(labChartFolder)
    labChartFolder = uigetdir(char(string(opts.DefaultRoot)), 'Select the LabChart folder');
    if isequal(labChartFolder, 0)
        error('No LabChart folder selected.');
    end
end
if ~isfolder(labChartFolder)
    error('LabChart folder does not exist: %s', labChartFolder);
end

pre = dir(fullfile(labChartFolder, '*_pre.*'));
pre = pre(~[pre.isdir]);
exp = dir(fullfile(labChartFolder, '*_exp.*'));
exp = exp(~[exp.isdir]);
if isempty(pre)
    error('Cannot find *_pre file in folder: %s', labChartFolder);
end
if isempty(exp)
    error('Cannot find *_exp file in folder: %s', labChartFolder);
end

baselineLabChart = fullfile(pre(1).folder, pre(1).name);
experimentLabChart = fullfile(exp(1).folder, exp(1).name);

timestampFile = char(string(opts.TimestampFile));
if isempty(timestampFile)
    [timestampName, timestampPath] = uigetfile( ...
        {'*.xlsx;*.xls;*.csv', 'Timestamp files (*.xlsx,*.xls,*.csv)'}, ...
        'Select the time stamp file', ...
        char(string(opts.DefaultRoot)));
    if isequal(timestampName, 0)
        error('No timestamp file selected.');
    end
    timestampFile = fullfile(timestampPath, timestampName);
end
if ~isfile(timestampFile)
    error('Timestamp file does not exist: %s', timestampFile);
end

f_baseline = adi.readFile(baselineLabChart);
f_exp = adi.readFile(experimentLabChart);

R_pre = f_baseline.records;
R_exp = f_exp.records;
nPre = numel(R_pre);
nExp = numel(R_exp);
R_all = [R_pre(:); R_exp(:)];
nR = numel(R_all);
recSource = [ones(nPre, 1); 2 * ones(nExp, 1)];
recLocalIdx = [(1:nPre)'; (1:nExp)'];

T = readtable(timestampFile, 'PreserveVariableNames', true);
v = string(T.Properties.VariableNames);
colYr = iFindTableColumn(v, @(s) contains(s, "yr"));
colM = iFindTableColumn(v, @(s) ismember(s, ["m", "month"]));
colD = iFindTableColumn(v, @(s) contains(s, "d") & ~contains(s, "id"));
colHr = iFindTableColumn(v, @(s) contains(s, "hr"));
colMin = iFindTableColumn(v, @(s) ismember(s, ["mm", "min", "minute", "minutes"]));
colSec = iFindTableColumn(v, @(s) strcmp(s, "s") | contains(s, "sec"));
colRec = iFindTableColumn(v, @(s) contains(s, "recording time"));

yr = iToNumericColumn(T.(colYr));
m = iToNumericColumn(T.(colM));
d = iToNumericColumn(T.(colD));
hr = iToNumericColumn(T.(colHr));
mi = iToNumericColumn(T.(colMin));
se = iToNumericColumn(T.(colSec));
recS = iToNumericColumn(T.(colRec));
yr(yr < 100) = yr(yr < 100) + 2000;

absEnd = datetime(yr, m, d, hr, mi, se, 'TimeZone', 'local');
ok = ~isnat(absEnd) & ~isnan(recS);
absEnd = absEnd(ok);
recS = recS(ok);
absStart = absEnd - seconds(recS);
absTime = [absStart, absEnd];
nWin = size(absTime, 1);

if nWin == 0
    error('No valid timestamp windows were found in %s.', timestampFile);
end
if ~isempty(opts.ExpectedWindows) && nWin ~= opts.ExpectedWindows
    error('Timestamp file defines %d windows, but %d were expected.', nWin, opts.ExpectedWindows);
end

recStartDT = NaT(nR, 1);
recEndDT = NaT(nR, 1);
recStartDT.TimeZone = 'local';
recEndDT.TimeZone = 'local';
for r = 1:nR
    t0 = R_all(r).record_start_datetime;
    if isempty(t0.TimeZone)
        t0.TimeZone = 'local';
    else
        t0 = datetime(t0, 'TimeZone', 'local');
    end
    recStartDT(r) = t0;

    dur = R_all(r).duration;
    if isduration(dur)
        recEndDT(r) = t0 + dur;
    else
        recEndDT(r) = t0 + seconds(double(dur));
    end
end

Tstart = absTime(:, 1);
Tend = absTime(:, 2);
recIdx = zeros(nWin, 1);
for k = 1:nWin
    r = find(Tstart(k) >= recStartDT & Tstart(k) < recEndDT, 1, 'first');
    if isempty(r)
        continue;
    end
    if Tend(k) > recEndDT(r)
        recIdx(k) = -r;
    else
        recIdx(k) = r;
    end
end

iTick0 = zeros(nWin, 1);
iTick1 = zeros(nWin, 1);
for k = 1:nWin
    r = recIdx(k);
    if r <= 0
        continue;
    end

    dt0 = seconds(Tstart(k) - recStartDT(r));
    dt1 = seconds(Tend(k) - recStartDT(r));
    td = R_all(r).tick_dt;
    if isduration(td)
        tick_dt = seconds(td);
    else
        tick_dt = double(td);
    end

    nTicks = double(R_all(r).n_ticks);
    i0 = floor(dt0 / tick_dt) + 1;
    i1 = floor(dt1 / tick_dt) + 1;
    i0 = max(1, min(nTicks, i0));
    i1 = max(1, min(nTicks, i1));
    if i1 < i0
        i1 = i0;
    end
    iTick0(k) = i0;
    iTick1(k) = i1;
end

channelList = { ...
    'Rectal Temp', 'Pleth', 'AoP', 'RaP', 'EKG', 'ICP EVD', 'ICP Millar/AoP2', ...
    'SpO2', 'EtCO2', 'Flow', 'Airway Pressure', 'PbtO2', 'Temp (Licox)', ...
    'PbtO2 Raumedic', 'ICP Raumedic' ...
    };

Data = struct();
validWin = find(recIdx > 0 & iTick0 > 0 & iTick1 > 0);
uRec = unique(recIdx(validWin));

for c = 1:numel(channelList)
    chName = channelList{c};
    field = matlab.lang.makeValidName(chName);

    ch_pre = [];
    ch_exp = [];
    found_pre = true;
    found_exp = true;

    try
        ch_pre = f_baseline.getChannelByName(chName, 'partial_match', false);
    catch
        found_pre = false;
    end

    try
        ch_exp = f_exp.getChannelByName(chName, 'partial_match', false);
    catch
        found_exp = false;
    end

    if ~found_pre && ~found_exp
        fprintf('[WARN] Channel not found in both files: %s\n', chName);
        continue;
    end

    if found_exp
        ch_meta = ch_exp;
    else
        ch_meta = ch_pre;
    end

    fs_ch = double(ch_meta.fs(1));
    Data.(field).name = chName;
    Data.(field).units = ch_meta.units;
    Data.(field).fs = fs_ch;
    Data.(field).segments = cell(nWin, 1);
    Data.(field).recIdx = recIdx;
    Data.(field).recSource = recSource;

    for r = uRec(:).'
        src = recSource(r);
        rLocal = recLocalIdx(r);

        if src == 1
            if ~found_pre
                continue;
            end
            ch = ch_pre;
        else
            if ~found_exp
                continue;
            end
            ch = ch_exp;
        end

        x = ch.getData(rLocal);
        n = numel(x);
        tick_fs = double(R_all(r).tick_fs);
        ratio = fs_ch / tick_fs;

        rows = validWin(recIdx(validWin) == r);
        for k = rows(:).'
            s0 = floor((iTick0(k) - 1) * ratio) + 1;
            s1 = floor((iTick1(k) - 1) * ratio) + 1;
            s0 = max(1, min(n, s0));
            s1 = max(1, min(n, s1));
            if s1 < s0
                s1 = s0;
            end

            Data.(field).segments{k} = x(s0:s1);
        end
    end

    fprintf('[OK] Loaded: %s\n', chName);
end

fields = string(fieldnames(Data));
if isempty(fields)
    error('No LabChart channels were loaded.');
end

nC = numel(fields);
MeanMat = nan(nWin, nC);
VarNames = strings(1, nC);
PrettyNames = strings(1, nC);
for c = 1:nC
    f = fields(c);
    if isfield(Data.(f), 'name')
        chName = string(Data.(f).name);
    else
        chName = f;
    end
    PrettyNames(c) = chName;
    VarNames(c) = matlab.lang.makeValidName(chName);

    segs = Data.(f).segments;
    for k = 1:nWin
        x = segs{k};
        if isempty(x)
            MeanMat(k, c) = NaN;
        else
            MeanMat(k, c) = mean(double(x(:)), 'omitnan');
        end
    end
end
MeanTable = array2table(MeanMat, 'VariableNames', cellstr(VarNames));

aopField = matlab.lang.makeValidName('AoP');
AoP_Systolic = nan(nWin, 1);
AoP_Diastolic = nan(nWin, 1);
PulsePressure = nan(nWin, 1);
if isfield(Data, aopField)
    aopSegs = Data.(aopField).segments;
    fsAoP = double(Data.(aopField).fs);
    for k = 1:nWin
        x = aopSegs{k};
        if isempty(x)
            continue;
        end

        x = double(x(:));
        x = x(isfinite(x));
        if isempty(x)
            continue;
        end

        xs = smoothdata(x, 'movmedian', 5);
        minPeakDist = max(1, round(0.3 * fsAoP));
        [pks, ~] = findpeaks(xs, 'MinPeakDistance', minPeakDist);
        [vlysNeg, ~] = findpeaks(-xs, 'MinPeakDistance', minPeakDist);
        vlys = -vlysNeg;

        if ~isempty(pks)
            AoP_Systolic(k) = median(pks);
        end
        if ~isempty(vlys)
            AoP_Diastolic(k) = median(vlys);
        end

        if isfinite(AoP_Systolic(k)) && isfinite(AoP_Diastolic(k))
            PulsePressure(k) = AoP_Systolic(k) - AoP_Diastolic(k);
        end
    end
end

MeanTable.AoP_Systolic = AoP_Systolic;
MeanTable.AoP_Diastolic = AoP_Diastolic;
MeanTable.AoP_PulsePressure = PulsePressure;

[ICP, icpChannelName] = iResolveICP(MeanTable);

physiology = struct();
physiology.LabChartFolder = labChartFolder;
physiology.TimestampFile = timestampFile;
physiology.MeanTable = MeanTable;
physiology.PrettyNames = PrettyNames;
physiology.Data = Data;
physiology.AoP_Systolic = AoP_Systolic;
physiology.AoP_Diastolic = AoP_Diastolic;
physiology.PulsePressure = PulsePressure;
physiology.ICP = ICP;
physiology.ICPChannelName = icpChannelName;
physiology.WindowCount = nWin;
physiology.WindowIndex = (1:nWin).';
windowTable = table((1:nWin).', AoP_Systolic, AoP_Diastolic, PulsePressure, ICP, ...
    'VariableNames', {'WindowIndex', 'AoP_Systolic', 'AoP_Diastolic', 'PulsePressure', 'ICP'});
if ~isempty(MeanTable)
    meanTableExtra = MeanTable(:, ~ismember(MeanTable.Properties.VariableNames, windowTable.Properties.VariableNames));
    windowTable = [windowTable meanTableExtra];
end
physiology.WindowTable = windowTable;
physiology.AbsoluteTime = absTime;
physiology.RecordIndex = recIdx;
physiology.RecordSource = recSource;
physiology.RecordLocalIndex = recLocalIdx;
physiology.TickStart = iTick0;
physiology.TickEnd = iTick1;
physiology.ValidWindowMask = recIdx > 0 & iTick0 > 0 & iTick1 > 0;
end

function sdkRoot = iFindSdkRoot(scriptDir)
sdkCandidates = { ...
    fullfile(scriptDir, 'adinstruments_sdk_matlab-master', 'adinstruments_sdk_matlab-master'), ...
    fullfile(scriptDir, 'adinstruments_sdk_matlab-master') ...
    };
for i = 1:numel(sdkCandidates)
    candidate = sdkCandidates{i};
    if isfolder(fullfile(candidate, '+adi'))
        sdkRoot = candidate;
        return
    end
end
error('Could not locate the ADInstruments MATLAB SDK under %s.', scriptDir);
end

function varName = iFindTableColumn(variableNames, matcher)
mask = matcher(lower(variableNames));
idx = find(mask, 1, 'first');
if isempty(idx)
    error('Could not find a required timestamp column in the selected file.');
end
varName = variableNames(idx);
end

function x = iToNumericColumn(value)
if isnumeric(value)
    x = double(value);
    return
end
if isduration(value)
    x = seconds(value);
    return
end
if iscell(value)
    value = string(value);
end
if isstring(value) || ischar(value)
    x = str2double(string(value));
    return
end
error('Unsupported timestamp column type: %s', class(value));
end

function [icpValues, icpChannelName] = iResolveICP(meanTable)
preferredChannels = {'ICP EVD', 'ICP Millar/AoP2', 'ICP Raumedic'};
icpValues = [];
icpChannelName = '';

for i = 1:numel(preferredChannels)
    field = matlab.lang.makeValidName(preferredChannels{i});
    if ismember(field, meanTable.Properties.VariableNames)
        icpValues = meanTable.(field);
        icpChannelName = preferredChannels{i};
        return
    end
end

fallbackIdx = find(contains(lower(meanTable.Properties.VariableNames), 'icp'), 1, 'first');
if ~isempty(fallbackIdx)
    icpField = meanTable.Properties.VariableNames{fallbackIdx};
    icpValues = meanTable.(icpField);
    icpChannelName = icpField;
end
end
