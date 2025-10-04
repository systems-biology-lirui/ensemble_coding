%% 代码是为了得到DG的meta——data，进而可以使用与QQ相同的分析流程。
function DG_SSVEPB(sessionIdx)
clear;
clc;
dbstop if error
load('DG_metadata.mat');
i = 1;
session_idx_path = 'D:\\Ensemble coding\\DGdata\\tooldata\\SessionIdx.mat';
load(session_idx_path);

SSVEPB_Days = 16:23;
Days = length(SSVEPB_Days);
trail_picnum = 72;

for d = 1:Days
    day = SSVEPB_Days(d);
    session_all = [sessionIdx{[3,8],day}];
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
        else
            [final_sessions(1:trial_num).Block] = deal('SSGv');
        end
        final_sessions = getMetadata(final_sessions,TrialStimID);
        Meta_data{i,5} = final_sessions;
        Meta_data{i,6} = '0520';
        Meta_data{i,7} = sprintf('u%d',sessionIdx{1,day});
        Meta_data{i,8} = 'SSVEP_B';
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
    else
        location = process_ECpatch_location(sequence_pre);
        location = unique(location);
        ori = process_ECpatch_ori(sequence_pre);
        Pattern = [];
    end


    % trial标签
    if isscalar(unique(ori(4:4:72)))
        if unique(ori) ~= 19
            final_sessions(trial).Condition = ori(4);
        else
            final_sessions(trial).Condition = 0;
            final_sessions(trial).Block = 'Blank';
        end
    else
        final_sessions(trial).Condition = -1;
    end
    
    if location==14
        final_sessions(trial).Block = 'SG';
    elseif location == 15
        final_sessions(trial).Block = 'Blank';
    end

    final_sessions(trial).Location = location;
    final_sessions(trial).Pic_Idx = sequence_pre;
    final_sessions(trial).Stim_Sequence = ori;
    final_sessions(trial).Pattern = Pattern;
end
end


function location = process_ECpatch_location(StimID)
    % 处理ECpatch的Location
    location = StimID;
    location(location < 3889) = mod(location(location < 3889), 12);
    location(location == 0) = 12;
    location(location == 3889) = 15; %blank
    location(location > 3889 & location < 3998) = 13;
    location(location > 3997) = 14;
end

function ori = process_ECpatch_ori(StimID)
    % 处理ECpatch的图片朝向
    ori = StimID;
    ori(ori < 3889) = floor((ori(ori < 3889) - 1) / 216) + 1;
    ori(ori == 3889) = 19;
    ori(ori > 3889 & ori < 3998) = mod((ori(ori > 3889 & ori < 3998) - 3889), 18);
    ori(ori > 3997) = mod((ori(ori > 3997) - 3997), 18);
    ori(ori == 0) = 18;
end

save('DG_metadata.mat','Meta_data');
end