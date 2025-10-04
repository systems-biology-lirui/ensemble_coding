%% 代码是为了得到DG的meta——data，进而可以使用与QQ相同的分析流程。
function DG_EVENT(sessionIdx)
clear;
clc;
dbstop if error
Meta_data = {};
i = 1;
session_idx_path = 'D:\\Ensemble coding\\DGdata\\tooldata\\SessionIdx.mat';
load(session_idx_path);

EVENT_Days = 25:29;
Days = length(EVENT_Days);
trail_picnum = 52;

for d = 1:Days
    day = EVENT_Days(d);
    session_all = [sessionIdx{3:6,day}];
    for session = session_all
        dataPath = sprintf('D:\\Ensemble coding\\DGdata\\DG2-u%d-%03d-500Hz.mat', ...
            sessionIdx{1, day}, session);
        fprintf('start loading %s \n',dataPath);
        loadedData = load(dataPath);
        trial_num = size(loadedData.Datainfo.trial_LFP,1);

        TrialStimID = reshape(loadedData.Datainfo.Seq.StimID, [trail_picnum, trial_num])';
        clear loadedData final_sessions
        final_sessions(1:trial_num) = struct('Location',[],'Condition',[],'Stim_Sequence',[],'Pattern',[],'Pic_Idx',[]);

        if ismember(session,sessionIdx{3,day})
            [final_sessions(1:trial_num).Block] = deal('MGv');
        elseif ismember(session,sessionIdx{4,day})
            [final_sessions(1:trial_num).Block] = deal('MGnv');
        elseif ismember(session,sessionIdx{5,day})
            [final_sessions(1:trial_num).Block] = deal('SG');
        else
            [final_sessions(1:trial_num).Block] = deal('SSGnv');
        end
        final_sessions = getMetadata(final_sessions,TrialStimID);
        Meta_data{i,1} = final_sessions;
        Meta_data{i,2} = '0520';
        Meta_data{i,3} = sprintf('u%d',sessionIdx{1,day});
        Meta_data{i,4} = 'EVENT';
        i = i+1;
    end
end

function final_sessions = getMetadata(final_sessions,TrialStimID)
trial_num = size(TrialStimID,1);
Block = final_sessions(1).Block;
for trial = 1:trial_num
    sequence_pre = TrialStimID(trial,:);
    if strcmp(Block,'MGv')
        ori = floor((sequence_pre - 1) / 18) + 1;
        Pattern = floor((mod(sequence_pre-1, 18)/3))+1;
        location = [];
    elseif strcmp(Block,'MGnv') | strcmp(Block,'SG')
        ori = mod(sequence_pre, 18);
        ori(sequence_pre == 109) = 19;
        ori(ori == 0) = 18;
        Pattern = floor((sequence_pre-1)/18)+1;
        location = [];
    else
        location = floor((sequence_pre - 1) / 108) + 1;
        ori = mod(sequence_pre - (location - 1) * 108, 18);
        ori(sequence_pre == 1405) = 19;
        ori(ori == 0) = 18;
        Pattern = [];
    end

    if unique(ori) == 19
        final_sessions(trial).Block = 'Blank';
    end
    if ~isempty(location)
        location = unique(location);
        if length(location) ~= 1
            final_sessions(trial).Location = setdiff(location,14);
        else
            final_sessions(trial).Location = location;
        end
    end
    final_sessions(trial).Pic_Idx = sequence_pre;
    final_sessions(trial).Stim_Sequence = ori;
    final_sessions(trial).Pattern = Pattern;
end
end

save('DG_metadata_EVENT.mat','Meta_data');
end