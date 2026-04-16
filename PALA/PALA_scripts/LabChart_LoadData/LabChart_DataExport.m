%% Setup Path
clc
addpath(genpath('D:\LabChart\adinstruments_sdk_matlab-master'));

%% Pick Labchart File
if exist('temp.mat','file')
    load('temp.mat')
    defaultfilepath = labchartfolder;
else
    defaultfilepath = 'D:\';
end

allfiles = uipickfiles('FilterSpec',defaultfilepath,...
    'Prompt','Select the LabChart Folder',...
    'Output','struct');
labchartfolder = allfiles(1).folder;
currentname = allfiles(1).name;

pre = dir(fullfile(currentname, '*_pre.*'));
exp = dir(fullfile(currentname, '*_exp.*'));

baseline_labchart   = fullfile(pre(1).folder, pre(1).name);
experiment_labchart = fullfile(exp(1).folder, exp(1).name);

save('temp.mat','labchartfolder');

f_baseline  = adi.readFile(baseline_labchart);
f_exp  = adi.readFile(experiment_labchart);

%% Pick Excel File for Recording Time Stamps
if exist('temp.mat','file')
    load('temp.mat')
    defaultfilepath = timestampfolder;
else
    defaultfilepath = 'D:\';
end

allfiles = uipickfiles('FilterSpec',defaultfilepath,...
    'Prompt','Select the time stamp file',...
    'Output','struct');
timestampfolder = allfiles(1).folder;
currentname = allfiles(1).name;

file_timestamp = currentname;

save('temp.mat','timestampfolder','-append');

% Excel reader
xlsPath = file_timestamp;
T = readtable(xlsPath, "PreserveVariableNames", true);
% Handle column names that may contain spaces/brackets:
% find columns by keyword matching (robust to slight name variations)
v = string(T.Properties.VariableNames);
colYr  = v(contains(lower(v),"yr"));
colM   = v(ismember(lower(v),["m","month"]) | strcmpi(v,"m"));
colD   = v(contains(lower(v),"d") & ~contains(lower(v),"id"));   % avoid matching "id"
colHr  = v(contains(lower(v),"hr"));
colMin = v(ismember(lower(v),["mm","min","minute","minutes"]));
colSec = v(strcmpi(v,"s") | contains(lower(v),"sec"));
colRec = v(contains(lower(v),"recording time"));

yr   = T.(colYr(1));
m    = T.(colM(1));
d    = T.(colD(1));
hr   = T.(colHr(1));
mi   = T.(colMin(1));
se   = T.(colSec(1));
recS = T.(colRec(1));

yr(yr < 100) = yr(yr < 100) + 2000;

% Build absolute timestamps (set the timezone as needed: "local" or "UTC")
absTime(:,2) = datetime(yr,m,d,hr,mi,se, "TimeZone","local");

% Remove rows with missing timestamps or missing recording times
ok = all(~isnat(absTime),2) & ~isnan(recS);
absTime = absTime(ok,:);
recS    = recS(ok);

absTime(:,1) = datetime(yr,m,d,hr,mi,se-recS, "TimeZone","local");

%% Syncronize Recordings and Recording Time Stamp
R  = f_exp.records;
nR = numel(R);
% sync = 99;

% Preallocate datetime arrays WITH local timezone
recStartDT = NaT(nR,1);
recEndDT   = NaT(nR,1);
recStartDT.TimeZone = "local";
recEndDT.TimeZone   = "local";

for r = 1:nR
    t0 = R(r).record_start_datetime;  % datetime (may or may not have tz)

    % Force each t0 to be local timezone
    if isempty(t0.TimeZone)
        t0.TimeZone = "local";                  % assign tz (no clock shift)
    else
        t0 = datetime(t0, "TimeZone", "local");  % convert tz (clock shift if needed)
    end

    recStartDT(r) = t0;
%     recEndDT(r) = t0;

    dur = R(r).duration;
    if isduration(dur)
        recEndDT(r) = t0 + dur;
    else
        recEndDT(r) = t0 + seconds(double(dur));
    end
end

% Match the recording 
Tstart = absTime(:,1);
Tend   = absTime(:,2);

nWin = size(absTime,1);
recIdx = zeros(nWin,1);

for k = 1:nWin
    % find the record that contains Tstart
    r = find(Tstart(k) >= recStartDT & Tstart(k) < recEndDT, 1, "first");
    if isempty(r)
        recIdx(k) = 0;   % not in any record
        continue;
    end

    % mark if the window crosses record boundary
    if Tend(k) > recEndDT(r)
        recIdx(k) = -r;  % negative means "crosses record boundary"
    else
        recIdx(k) = r;
    end
end

%% Find Correct Index in each Recording
recStartDT_local = NaT(nR,1);
recStartDT_local.TimeZone = "local";

for r = 1:nR
    t0 = R(r).record_start_datetime;   % may be timezone-less

    if isempty(t0.TimeZone)
        % Assign local timezone (no clock-time shift)
        t0.TimeZone = "local";
    else
        % Convert to local timezone
        t0 = datetime(t0, "TimeZone", "local");
    end

    recStartDT_local(r) = t0;
end

nWin = numel(recIdx);
iTick0 = zeros(nWin,1);
iTick1 = zeros(nWin,1);

for k = 1:nWin
    r = recIdx(k);
    if r <= 0
        iTick0(k)=0; iTick1(k)=0;
        continue;
    end

    dt0 = seconds(Tstart(k) - recStartDT_local(r));
    dt1 = seconds(Tend(k)   - recStartDT_local(r));

    % tick_dt can be duration or numeric
    td = R(r).tick_dt;
    if isduration(td)
        tick_dt = seconds(td);
    else
        tick_dt = double(td);
    end

    nTicks = double(R(r).n_ticks);

    i0 = floor(dt0/tick_dt) + 1;
    i1 = floor(dt1/tick_dt) + 1;

    i0 = max(1, min(nTicks, i0));
    i1 = max(1, min(nTicks, i1));
    if i1 < i0, i1 = i0; end

    iTick0(k) = i0;
    iTick1(k) = i1;
end

% -------------------- Workspace cleanup --------------------
clear allfiles currentname pre exp v colYr colM colD colHr colMin colSec colRec
clear yr m d hr mi se recS ok abs2recSec
clear k r t0 dur nR
clear i0 i1

%% Read Channel Data
ChannelList = { ...
    'Rectal Temp','Pleth','AoP','RaP','EKG','ICP EVD','ICP Millar/AoP2', ...
    'SpO2','EtCO2','Flow','Airway Pressure','PbtO2','Temp (Licox)', ...
    'PbtO2 Raumedic','ICP Raumedic'...
};

Data = struct();

validWin = find(recIdx > 0 & iTick0 > 0 & iTick1 > 0);
uRec = unique(recIdx(validWin));

for c = 1:numel(ChannelList)
    chName = ChannelList{c};

    % Get channel (skip if not found)
    try
        ch = f_exp.getChannelByName(chName,'partial_match', false);
    catch
        fprintf('[WARN] Channel not found: %s\n', chName);
        continue;
    end

    fs_ch = double(ch.fs);

    % Create a valid struct field name
    field = matlab.lang.makeValidName(chName);

    Data.(field).name = chName;
    Data.(field).units = ch.units;
    Data.(field).fs = fs_ch;
    Data.(field).segments = cell(nWin,1);
    Data.(field).recIdx = recIdx;

    % Map tick index -> sample index (per record), then slice
    for r = uRec(:).'
        x = ch.getData(r);
        n = numel(x);

        tick_fs = double(R(r).tick_fs);   % record tick rate
        ratio   = fs_ch / tick_fs;        % sample-per-tick ratio

        rows = validWin(recIdx(validWin) == r);
        for k = rows(:).'
            s0 = floor((iTick0(k)-1) * ratio) + 1;
            s1 = floor((iTick1(k)-1) * ratio) + 1;

            % Clamp
            s0 = max(1, min(n, s0));
            s1 = max(1, min(n, s1));
            if s1 < s0, s1 = s0; end

            Data.(field).segments{k} = x(s0:s1);
        end
    end

    fprintf('[OK] Loaded: %s\n', chName);
end

%% Processing on Each Segment
% Data: struct, Data.(field).segments is a cell array (nWin x 1)

fields = string(fieldnames(Data));
nC = numel(fields);

% infer number of windows from the first channel
nWin = numel(Data.(fields(1)).segments);

MeanMat = nan(nWin, nC);
VarNames = strings(1, nC);   % table variable names (must be valid identifiers)
PrettyNames = strings(1, nC);% original channel names for reference

for c = 1:nC
    f = fields(c);

    % Original channel name (stored earlier as Data.(field).name)
    if isfield(Data.(f), "name")
        chName = string(Data.(f).name);
    else
        chName = f; % fallback
    end
    PrettyNames(c) = chName;

    % Make a valid table variable name
    VarNames(c) = matlab.lang.makeValidName(chName);

    segs = Data.(f).segments;
    for k = 1:nWin
        x = segs{k};
        if isempty(x)
            MeanMat(k,c) = NaN;
        else
            MeanMat(k,c) = mean(double(x(:)), 'omitnan');
        end
    end
end

MeanTable = array2table(MeanMat, "VariableNames", cellstr(VarNames));

%% Pulse Pressure from AoP segments (simple max-min)
aopField = matlab.lang.makeValidName('AoP');

if ~isfield(Data, aopField)
    error('AoP channel not found in Data.');
end

aopSegs = Data.(aopField).segments;
nWin = numel(aopSegs);

PulsePressure = nan(nWin,1);
AoP_Systolic  = nan(nWin,1);
AoP_Diastolic = nan(nWin,1);

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

    AoP_Systolic(k)  = max(x);
    AoP_Diastolic(k) = min(x);
    PulsePressure(k) = AoP_Systolic(k) - AoP_Diastolic(k);
end

MeanTable.AoP_Systolic = AoP_Systolic;
MeanTable.AoP_Diastolic = AoP_Diastolic;
MeanTable.AoP_PulsePressure = PulsePressure;

