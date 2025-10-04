%% 提取Event SG中的最后一张，并按照平均朝向进行解码
% 标注trial中的图片，平均朝向，最后一张图片的朝向
% dbstop if error
clear;
MUA_LFP = 1;
Days = [2:4,9,10,12,13,14];
selected_blocks = {'MGv', 'MGnv', 'SG', 'SSGnv', 'blank'};
picloc = 4; % 想要看第几张图片
mean_strategy = 1; % 1代表序列更新，2代表直接平均。
QQ_Event_Temporal_Process(selected_blocks,Days,MUA_LFP,picloc,mean_strategy);

%% Temporal Decoding
clear;
load('EVENT_Temporal_Days2_14_MUA1_SG_pic4.mat');
Mean_left = cat(1,SG(3:8).Data);
Mean_right = cat(1,SG(10:15).Data);
minnum = min(size(Mean_right,1),size(Mean_left,1));
coilselect = [0, 5, 9, 11, 15, 17, 18, 19, 22, 23, 24, 26, 33, 34, 38, 40, 41, 42, 48, 51, 52, 53, 66, 72, 73, 78, 79, 82, 84, 87, 89]+1;
data_reshaped(1,:,:,:) = Mean_left(1:minnum,coilselect,:);
data_reshaped(2,:,:,:) = Mean_right(1:minnum,coilselect,:);
n_shuffles = 5;
[accuracy, p_value] = SVM_Decoding_LR(data_reshaped,n_shuffles);


%% --------------------
function QQ_Event_Temporal_Process(selected_blocks,Days,MUA_LFP,picloc,mean_strategy)
load('D://Ensemble coding//QQdata//QQSessionIdx.mat','SessionIdx');
% Exp_type = {'SSVEP_A','SSVEP_B','Event_A','Event_B'};
all_blocks = {'MGv', 'MGnv', 'SG', 'SSGnv', 'blank'};

% 默认全部Block
if nargin == 0
    selected_blocks = all_blocks;
else

    invalid_blocks = setdiff(selected_blocks, all_blocks);
    if ~isempty(invalid_blocks)
        error('无效的Block名称: %s', strjoin(invalid_blocks, ', '));
    end
end

% 只初始化需要处理的block
if ismember('MGv', selected_blocks)
    % MGv = cell(2,18);
    MGv(1:18) = struct('Block', 'MGv', 'Location', [], 'Pic_Ori', [], 'Pattern', [], 'Data',[], 'Trial', [] ,'Cluster', []);
    for i = 1:18
        MGv(i).Pic_Ori = i;
    end
end
if ismember('MGnv', selected_blocks)
    % MGnv = cell(2,18);
    MGnv(1:18) = struct('Block', 'MGnv', 'Location', [], 'Pic_Ori', [], 'Pattern', [], 'Data',[], 'Trial', [] ,'Cluster', []);
    for i = 1:18
        MGnv(i).Pic_Ori = i;
    end
end
if ismember('SG', selected_blocks)
    % SG = cell(2,18);
    SG(1:18) = struct('Block', 'SG', 'Location', [], 'Pic_Ori', [], 'Pattern', [], 'Data',[], 'Trial', [] ,'Cluster', []);
    for i = 1:18
        SG(i).Pic_Ori = i;
    end
end
if ismember('SSGnv', selected_blocks)
    % SSGnv = cell(13,18);
    SSGnv(1:234) = struct('Block', 'SSGnv', 'Location', [], 'Pic_Ori', [], 'Phase', [] ,'Data',[],'Trial', [], 'Cluster', []);
    idx = 1;
    for location = 1:13

        for i = 1:18
            SSGnv(idx).Location = location;
            SSGnv(idx).Pic_Ori = i;
            idx = idx+1;
        end
    end
end
if ismember('blank', selected_blocks)
    % blank(1) = struct('date', [], 'block', 'blank', 'location', [], 'Pic_Ori', [], 'Phase', [], 'data',[]);
    blank = cell(1,1);
end


load('D:\\Ensemble coding\\sti\\GSQdataEventAll.mat','final_sessions');
for day = 1:length(Days)

    realSession = SessionIdx{11,Days(day)};            % 实际做的session,eg.session1
    Sessions = SessionIdx{12,Days(day)};               % 文件的编号,eg.000

    fprintf('Start day%d\n', Days(day));
    for session = 1:length(Sessions)
        fprintf('Start Session%d\n', Sessions(session));
        U = SessionIdx{1,Days(day)};                   % 天的编号，eg.u088
        load(sprintf('D:\\Ensemble coding\\QQdata\\QQ2-%s-%03d-500hz.mat',U,Sessions(session)));

        % trial重排
        respCode = Datainfo.VSinfo.sMbmInfo.respCode;
        idx = find(strcmp({final_sessions{:,2}},SessionIdx{3,Days(day)}));
        session_factor = final_sessions{idx(realSession(session)),1};
        ReFactor = IdxRearrage(respCode,session_factor);
        % 分组
        if MUA_LFP == 1
            [repeatnum,ClusterData] = PicDataTemporalRearrange(ReFactor,Datainfo.trial_MUA{1},picloc,mean_strategy);
        elseif MUA_LFP == 2
            [repeatnum,ClusterData] = PicDataTemporalRearrange(ReFactor,Datainfo.trial_MUA{2},picloc,mean_strategy);
        elseif MUA_LFP == 3
            [repeatnum,ClusterData] = PicDataTemporalRearrange(ReFactor,Datainfo.trial_LFP,picloc,mean_strategy);
        end

        allrepeat{session} = repeatnum;
        % session拼接（直接操作独立变量）
        for cond = 1:18

            % 拼接 MGv
            if ~isempty(ClusterData.MGv{1,cond})
                MGv(cond).Data = cat(1, MGv(cond).Data, ClusterData.MGv{1,cond});
                MGv(cond).Pattern = cat(1, MGv(cond).Pattern, ClusterData.MGv{2,cond});
                MGv(cond).Trial = cat(1, MGv(cond).Trial, ClusterData.MGv{3,cond});
                % MGv{1,cond} = cat(1, MGv{1,cond}, ClusterData.MGv{1,cond});
                % MGv{2,cond} = cat(1, MGv{2,cond}, ClusterData.MGv{2,cond});
            end
            % 拼接 MGnv
            if ~isempty(ClusterData.MGnv{1,cond})
                MGnv(cond).Data = cat(1, MGnv(cond).Data, ClusterData.MGnv{1,cond});
                MGnv(cond).Pattern = cat(1, MGnv(cond).Pattern, ClusterData.MGnv{2,cond});
                MGnv(cond).Trial = cat(1, MGnv(cond).Trial, ClusterData.MGnv{3,cond});
                %     MGnv{1,cond} = cat(1, MGnv{1,cond}, ClusterData.MGnv{1,cond});
                %     MGnv{2,cond} = cat(1, MGnv{2,cond}, ClusterData.MGnv{2,cond});
            end
            % 拼接 SG
            if ~isempty(ClusterData.SG{1,cond})
                SG(cond).Data = cat(1, SG(cond).Data, ClusterData.SG{1,cond});
                SG(cond).Pattern = cat(1, SG(cond).Pattern, ClusterData.SG{2,cond});
                SG(cond).Trial = cat(1, SG(cond).Trial, ClusterData.SG{3,cond});
                % SG{1,cond} = cat(1, SG{1,cond}, ClusterData.SG{1,cond});
                % SG{2,cond} = cat(1, SG{2,cond}, ClusterData.SG{2,cond});
            end
        end

        % 拼接 SSGnv（13x18 cell）
        for loc = 1:13
            for cond = 1:18
                idx = find([SSGnv.Location] == loc & [SSGnv.Pic_Ori] == cond);
                if ~isempty(ClusterData.SSGnv{1, loc, cond})
                    SSGnv(idx).Data = cat(1, SSGnv(idx).Data, ClusterData.SSGnv{1, loc, cond});
                    % SSGnv{loc,cond} = cat(1, SSGnv{loc,cond}, ClusterData.SSGnv{loc,cond});
                    SSGnv(idx).Trial = cat(1, SSGnv(idx).Trial, ClusterData.SSGnv{2, loc, cond});

                end
            end
        end

        % 处理 blank 数据
        if ~isempty(ClusterData.blank)
            blank = cat(1, blank, ClusterData.blank);
        end
    end
end
MUAcondition = {'MUA1','MUA2','LFP'};
for i = 1:length(selected_blocks)
    block = selected_blocks{i};
    if exist(block, 'var') && ~isempty(eval(block))
        save(sprintf('EVENT_Temporal_Days%d_%d_%s_%s_pic%d.mat', Days(1), Days(end),MUAcondition{MUA_LFP}, block, picloc), block,'-v7.3');
    end
end
end
%--------------------------- 序列的重排-------------------------------------%
function ReFactor = IdxRearrage(respCode,session_factor)

for i = 1:length(respCode)
    if respCode(i) ~= 1
        session_factor(end+1) = session_factor(i);

    end
end
idx = respCode ~= 1;
session_factor(idx) = [];
ReFactor = session_factor;
end


% -----------------------数据提出------------------------------------------%
function [repeatnum,ClusterData] = PicDataTemporalRearrange(ReFactor,trialdata,picloc,mean_strategy)
repeatnum(1:18) = struct('MGv',zeros(1,1),'MGnv',zeros(1,1),'SG',zeros(1,1));
ClusterData = struct(...
    'MGv',  {cell(3, 18)}, ...   % 1x11 cell
    'MGnv', {cell(3, 18)}, ...   % 1x11 cell
    'SG',   {cell(3, 18)}, ...   % 1x11 cell
    'SSGnv',{cell(2, 13, 18)}, ...   % 13x11 cell
    'blank',[]);

idx1 = 1:13:40;
pic = idx1(picloc);
for trial =1:length(ReFactor)
    disp(trial);
    
    currentBlock = ReFactor(trial).block;
    if ~strcmp(currentBlock,'blank')
        ori = ReFactor(trial).stim_sequence(1:13:40);
        

        % 计算平均
        if mean_strategy ==1
            meanori = cumulative_average(ori);
        else
            meanori = (ori(1)+ori(2)+ori(3)+ori(4))/4;
        end
        meanori = floor(meanori);

        % 提出数据
        window = 100+(pic-1)*20+(-19:80);
        currentData = single(trialdata(trial,1:96,window));
    end
    
    % 90hz 低通(会非常的慢)
    % filtered_data = single(zeros(1,96,length(window)));
    % for channel = 1:96
    %     filtered_data(1,channel,:) = lowpass(squeeze(currentData(1,channel,:)), 90, 500, ...
    %         'ImpulseResponse', 'auto', ...
    %         'Steepness', 0.85);
    % end
    % clear currentData
    filtered_data = currentData;
    % 分组
    if strcmp(currentBlock,'SSGnv')
        
        loc = ReFactor(trial).location;
        ClusterData.SSGnv{1, loc,meanori} = cat(1,ClusterData.SSGnv{1,loc,meanori},filtered_data);
        ClusterData.SSGnv{2, loc,meanori} = cat(1,ClusterData.SSGnv{2,loc,meanori},ori);

    elseif strcmp(currentBlock,'blank')
        ClusterData.blank = cat(1,ClusterData.blank,single(trialdata(trial,1:96,1:end)));
    else
        pattern = ReFactor(trial).pattern(1:13:40);
        ClusterData.(currentBlock){1,meanori} = cat(1,ClusterData.(currentBlock){1,meanori},filtered_data);
        ClusterData.(currentBlock){2,meanori} = cat(1,ClusterData.(currentBlock){2,meanori},pattern);
        ClusterData.(currentBlock){3,meanori} = cat(1,ClusterData.(currentBlock){3,meanori},ori);
    end
end

end

function meanori = cumulative_average(orisequence)
meanori = orisequence(1);
for i = 1:length(orisequence)
    meanori = (meanori+orisequence(i))/2;
end
end