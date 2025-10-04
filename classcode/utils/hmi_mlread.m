function [times,events,eye_data,epp_data,header,trialcount,header2] = hmi_mlread(filename)
% Function to convert ML behavioural files into matlab
% Based on mlread, which returns trial and configuration data from bhv2 and h5.
% This step uses a slightly modified version of "mlread.m" called
% Yield the following matrices (each column corresponds to a single trial)
% times: event times
% events: event codes (see hmi_config.m for details)
% eye_data: eye position data (format: x1,y1,x2,y2,etc.)
% epp_data: additional analog data input (not currently used)
% header: lists the header information for each trial (format: cond_no,
% block_no, repeat_no, trial_no, isi_size, code_size, eog_size, epp_size,
% eye_store_rate, kHZ_resolution, expected_response,response,response_error
% trialcount: a scalar value of the number of trials
% header2: currently empty


if ~exist('filename','var') || 2~=exist(filename,'file')
    [n,p] = uigetfile({'*.bhv2;*.h5;*.bhv','MonkeyLogic Datafile (*.bhv2;*.h5;*.bhv)'});
    if isnumeric(n), error('File not selected'); end
    filename = [p n];
end
[~,~,e] = fileparts(filename);
switch lower(e)
    case '.bhv2', fid = mlbhv2(filename,'r');
    case '.h5', fid = mlhdf5(filename,'r');
    case '.bhv', data = bhv_read(filename); return;
    otherwise, error('Unknown file format');
end

MLConfig = [];
TrialRecord = [];
data = fid.read_trial();
if 1<nargout, MLConfig = fid.read('MLConfig'); end
if 2<nargout, TrialRecord = fid.read('TrialRecord'); end
close(fid);


%% 
trialcount = size(data,2);
eye_data = []; % currently empty
epp_data = []; % currently empty
header2 = []; % currently empty

% header
header = zeros(13,trialcount);
header(1,:) = cell2mat({data.Condition}); % block_no
header(2,:) = cell2mat({data.Block}); % block_no
header(4,:) = cell2mat({data.Trial}); % trial_no
header(5,:) = cell2mat({data.TrialError});%error type
header(9,:) = 1000/MLConfig.AISampleRate; % eye_store_rate

% events & times
for n = 1:trialcount,
    temp(n,1)=length(data(n).BehavioralCodes.CodeTimes); % the length of codes in each trial
end
times = zeros(max(temp),trialcount);
events = zeros(max(temp),trialcount);

for n = 1:trialcount,
    events_tmp = data(n).BehavioralCodes.CodeNumbers;
    events(1:length(events_tmp),n) = events_tmp;
    times_tmp = data(n).BehavioralCodes.CodeTimes;
    times(1:length(times_tmp),n) = times_tmp;
    eye_data{n} = data(n).AnalogData.Eye;
end



