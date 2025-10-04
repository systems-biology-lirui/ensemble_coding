%% -------------------------------第二只猴的数据处理---------------------------%
% SSVEP
dbstop if error
clear;

macaque = 'DG';
% 信号提取
Days = 4:15;
MUA_LFP =2;
A_B = 'A';
selected_blocks= {'MGv','MGnv','SG'};
DG_SSVEP_Process(selected_blocks,Days,MUA_LFP,A_B);



function DG_SSVEP_Process(selected_blocks,Days,MUA_LFP,A_B)

%SSVEP_A/B
session_idx_path = 'D:\\Ensemble coding\\DGdata\\tooldata\\DGSessionIdx.mat';
load(session_idx_path,'SessionIdx');
condition = -1:2:17;
% 只初始化需要处理的block
if ismember('MGv', selected_blocks)
    % MGv = cell(2,18);
    MGv(1:10) = struct('Block', 'MGv', 'Location', [], 'Target_Ori', [], 'Pic_Ori', [], 'Pattern', [], 'Data',[]);
    for i = 1:10
        MGv(i).Target_Ori = condition(i);
    end
end
if ismember('MGnv', selected_blocks)
    % MGnv = cell(2,18);
    MGnv(1:10) = struct('Block', 'MGnv', 'Location', [], 'Target_Ori', [], 'Pic_Ori', [], 'Pattern', [], 'Data',[]);
    for i = 1:10
        MGnv(i).Target_Ori = condition(i);
    end
end
if ismember('SG', selected_blocks)
    % SG = cell(2,18);
    SG(1:10) = struct('Block', 'SG', 'Location', [], 'Target_Ori', [], 'Pic_Ori', [], 'Pattern', [], 'Data',[]);
    for i = 1:10
        SG(i).Target_Ori = condition(i);
    end
end
if ismember('SSGnv', selected_blocks)
    % SSGnv = cell(13,18);
    SSGnv(1:130) = struct('Block', 'SSGnv', 'Location', [], 'Target_Ori', [], 'Pic_Ori', [], 'Pattern', [], 'Data',[]);
    idx = 1;
    for location = 1:13

        for i = 1:10
            SSGnv(idx).Location = location;
            SSGnv(idx).Target_Ori = condition(i);
            idx = idx+1;
        end
    end
end

if ismember('Blank', selected_blocks)
    % blank(1) = struct('date', [], 'block', 'blank', 'location', [], 'Pic_Ori', [], 'Phase', [], 'data',[]);
    Blank = cell(1,1);
end

load('D:\\Ensemble coding\\DGdata\\tooldata\\DG_metadata_SSVEP.mat','Meta_data');
for day = 1:length(Days)
    
    may_block = {'MGv','MGnv','SG','SSGnv','SSGv'};
    [~,searchidx]=ismember(selected_blocks,may_block);
    searchidx = searchidx+2;
    Sessions = [SessionIdx{searchidx,Days(day)}];
    fprintf('Start day%d\n', Days(day)); 


    fprintf(sprintf('Start day%d\n',day));
    for session = 1:length(Sessions)
        fprintf(sprintf('Start Session%d\n',session));
        U = sprintf('u%d',SessionIdx{1,Days(day)});                                        % 天的编号，eg.u088
        load(sprintf('D:\\Ensemble coding\\DGdata\\500hzdata\\DG2-%s-%03d-500hz.mat',U,Sessions(session)));

        % trial重排
        respCode = Datainfo.VSinfo.sMbmInfo.respCode;
        mm = length([SessionIdx{3:(searchidx-1),Days(day)}]);
        if strcmp(A_B,'A')
            idx = find(strcmp({Meta_data{:,3}},U));
            session_factor = Meta_data{idx(session)+mm,1};
        else
            idx = find(strcmp({Meta_data{:,7}},U));
            session_factor = Meta_data{idx(session)+mm,5};
        end
        ReFactor = IdxRearrage(respCode,session_factor);

        % 分组
        if MUA_LFP == 1
            ClusterData = TrialDataRearrange(ReFactor,Datainfo.trial_MUA{1});
        elseif MUA_LFP == 2
            ClusterData = TrialDataRearrange(ReFactor,Datainfo.trial_MUA{2});
        elseif MUA_LFP == 3
            ClusterData = TrialDataRearrange(ReFactor,Datainfo.trial_LFP);
        end
        condition = -1:2:17;
        % session拼接
        for cond = 1:10
            % 拼接 MGv
            if ismember('MGv', selected_blocks)
                if ~isempty(ClusterData.MGv{1,cond})
                    MGv(cond).Data = cat(1, MGv(cond).Data, int16(ClusterData.MGv{1,cond}));
                    MGv(cond).Pic_Ori = cat(1, MGv(cond).Pic_Ori, ClusterData.MGv{2,cond});
                    MGv(cond).Target_Ori = condition(cond);
                    MGv(cond).Pattern = cat(1, MGv(cond).Pattern, ClusterData.MGv{3,cond});
                end
            end
            if ismember('MGnv', selected_blocks)
                % 拼接 MGnv
                if ~isempty(ClusterData.MGnv{1,cond})
                    MGnv(cond).Data = cat(1, MGnv(cond).Data, int16(ClusterData.MGnv{1,cond}));
                    MGnv(cond).Pattern = cat(1, MGnv(cond).Pattern, ClusterData.MGnv{3,cond});
                    MGnv(cond).Pic_Ori = cat(1, MGnv(cond).Pic_Ori, ClusterData.MGnv{2,cond});
                end
            end
            % 拼接 SG
            if ismember('SG', selected_blocks)
                if ~isempty(ClusterData.SG{1,cond})
                    SG(cond).Data = cat(1, SG(cond).Data, int16(ClusterData.SG{1,cond}));
                    SG(cond).Pattern = cat(1, SG(cond).Pattern, ClusterData.SG{3,cond});
                    SG(cond).Pic_Ori = cat(1, SG(cond).Pic_Ori, ClusterData.SG{2,cond});
                end
            end
        end

        % 拼接 SSGnv（13x18 cell）
        if ismember('SSGnv', selected_blocks)
            for loc = 1:13
                for cond = 1:10
                    idx = find([SSGnv.Location] == loc & [SSGnv.Target_Ori] == condition(cond));
                    if ~isempty(ClusterData.SSGnv{1, loc, cond})
                        SSGnv(idx).Data = cat(1, SSGnv(idx).Data, int16(ClusterData.SSGnv{1, loc, cond}));
                        SSGnv(idx).Target_Ori = condition(cond);
                        SSGnv(idx).Pic_Ori = cat(1, SSGnv(idx).Pic_Ori, ClusterData.SSGnv{2,loc,cond});

                    end
                end
            end
        end
        if ismember('blank', selected_blocks)
            % 处理 blank 数据
            if ~isempty(ClusterData.Blank)
                Blank = cat(1, Blank, ClusterData.Blank);
            end
        end
    end
end

if strcmp(A_B,'B')
    SSGv = SSGnv;
    selected_blocks = {'MGv', 'MGnv', 'SG', 'SSGv', 'Blank'};
end
MUAcondition = {'MUA1','MUA2','LFP'};
for i = 1:length(selected_blocks)
    block = selected_blocks{i};
    if exist(block, 'var') && ~isempty(eval(block))
        save(sprintf('D:\\Ensemble coding\\DGdata\\Processed_Event\\DG_SSVEP%s_Days%d_%d_%s_%s.mat', A_B, Days(1), Days(end),MUAcondition{MUA_LFP}, block), block,'-v7.3');
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

%---------------------------数据的重排--------------------------------------%
function ClusterData = TrialDataRearrange(ReFactor,trialdata)

% 添加带阻滤波器的设计
% fs = 500; % 采样频率
% f1 = 95;  % 带阻下限频率
% f2 = 105; % 带阻上限频率
% order = 4; % 滤波器的阶数
% [b, a] = butter(order, [f1, f2]/(fs/2), 'stop');

ClusterData = struct(...
    'MGv',  {cell(3, 10)}, ...   % 1x11 cell
    'MGnv', {cell(3, 10)}, ...   % 1x11 cell
    'SG',   {cell(3, 10)}, ...   % 1x11 cell
    'SSGnv',{cell(2, 13, 10)}, ...   % 13x11 cell
    'Blank',[]);


uniqueChars = unique({ReFactor.Block});  % 返回 {'A', 'B', 'C', 'D'}

charIndices = cell(1, length(uniqueChars));

for i = 1:length(uniqueChars)
    charIndices{i} = find(strcmp({ReFactor.Block}, uniqueChars{i}));
end


for i = 1:length(uniqueChars)
    currentBlock = uniqueChars{i};
    currentBlockidx = ReFactor(charIndices{i});
    if strcmp(currentBlock,'SSGnv')
        for loc = 1:13
            condition = -1:2:17;
            for condi = 1:length(-1:2:17)
                idx = [currentBlockidx.Location] == loc & [currentBlockidx.Condition] == condition(condi);
                idx = charIndices{i}(idx);
                data = squeeze(trialdata(idx, 1:96, 1:1640));
                if length(size(data))~=3
                    data = reshape(data,[1,size(data)]);
                end
                filteredData = data - mean(data(:,:,1:100),3);

                ClusterData.SSGnv{1, loc, condi} = filteredData;
    
                ClusterData.SSGnv{2, loc,condi} = cat(1,ReFactor(idx).Stim_Sequence);
            end
        end
    elseif strcmp(currentBlock,'SSGv')
        for loc = 1:13
            condition = -1:2:17;
            for condi = 1:length(-1:2:17)
                idx = [currentBlockidx.location] == loc & [currentBlockidx.condition] == condition(condi);
                idx = charIndices{i}(idx);
                data = squeeze(trialdata(idx, 1:96, 1:1640));
                filteredData = data - mean(data(:,:,1:100),3);
                ClusterData.SSGnv{1, loc, condi} = filteredData;
    
                ClusterData.SSGnv{2, loc,condi} = cat(1,ReFactor(idx).Stim_Sequence);
            end
        end

    elseif strcmp(currentBlock,'Blank')
        idx = charIndices{1};
        ClusterData.Blank = cat(1,ClusterData.Blank,single(trialdata(idx,1:96,1:end)));
    elseif strcmp(currentBlock,'MGv') || strcmp(currentBlock,'MGnv') || strcmp(currentBlock,'SG') 
        condition = -1:2:17;
        for condi = 1:length(condition)
            idx1 = [currentBlockidx.Condition] == condition(condi);
            idx = charIndices{i}(idx1);
            data = trialdata(idx, 1:96, 1:1640);
            filteredData = data - mean(data(:,:,1:100),3);
            % filteredData = filtfilt(b, a, single(data)')'; % 滤波
            % filteredData = reshape(filteredData,[1,96,1640]);
            ClusterData.(currentBlock){1,condi} = single(filteredData);
            ClusterData.(currentBlock){2,condi} = cat(1,ReFactor(idx).Stim_Sequence);
            ClusterData.(currentBlock){3,condi} = cat(1,ReFactor(idx).Pattern);
        end
    end


end
end


