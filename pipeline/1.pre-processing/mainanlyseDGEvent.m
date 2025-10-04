%% -------------------------------第一只猴的数据处理---------------------------%
% Event

clear;
dbstop if error

% -------------------------- Script Configuration ----------------------- %

Days = 25:29;
MUA_LFP =3;
selected_blocks= {'SSGnv'};
output_data_path = 'D:\Ensemble coding\DGdata\Processed_Event\'; % Define a path for processed data

if ~exist(output_data_path, 'dir')
    mkdir(output_data_path);
end

fprintf('Starting Signal Extraction...\n');
allrepeat=DG_Event_Process(selected_blocks,Days,MUA_LFP);
fprintf('Signal Extraction Complete.\n');


% ----------------------------------信号提出--------------------------------%
function allrepeat=DG_Event_Process(selected_blocks,Days,MUA_LFP)
session_idx_path = 'D:\\Ensemble coding\\DGdata\\tooldata\\DGSessionIdx.mat';
load(session_idx_path,'SessionIdx');
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
    MGv(1:18) = struct('Block', 'MGv', 'Location', [], 'Pic_Ori', [], 'Pattern', [], 'Data',[]);
    for i = 1:18
        MGv(i).Pic_Ori = i;
    end
end
if ismember('MGnv', selected_blocks)
    % MGnv = cell(2,18);
    MGnv(1:18) = struct('Block', 'MGnv', 'Location', [], 'Pic_Ori', [], 'Pattern', [], 'Data',[]);
    for i = 1:18
        MGnv(i).Pic_Ori = i;
    end
end
if ismember('SG', selected_blocks)
    % SG = cell(2,18);
    SG(1:18) = struct('Block', 'SG', 'Location', [], 'Pic_Ori', [], 'Pattern', [], 'Data',[]);
    for i = 1:18
        SG(i).Pic_Ori = i;
    end
end
if ismember('SSGnv', selected_blocks)
    % SSGnv = cell(13,18);
    SSGnv(1:234) = struct('Block', 'SSGnv', 'Location', [], 'Pic_Ori', [], 'Phase', [], 'Data',[]);
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


load('D:\\Ensemble coding\\DGdata\\tooldata\\DG_metadata_Event.mat','Meta_data');
for day = 1:length(Days)
    may_block = {'MGv','MGnv','SG','SSGnv','SSGv'};
    [~,searchidx]=ismember(selected_blocks,may_block);
    searchidx = searchidx+2;
    Sessions = [SessionIdx{searchidx,Days(day)}];
    fprintf('Start day%d\n', Days(day));
    for session = 1:length(Sessions)
        fprintf('Start Session%d\n', Sessions(session));
        U = sprintf('u%d',SessionIdx{1,Days(day)});                                        % 天的编号，eg.u088
        load(sprintf('D:\\Ensemble coding\\DGdata\\500hzdata\\DG2-%s-%03d-500hz.mat',U,Sessions(session)),'Datainfo');
        % trial重排
        % respCode = Datainfo.VSinfo.sMbmInfo.respCode;
        idx = find(strcmp({Meta_data{:,3}},U));
        mm = length([SessionIdx{3:(searchidx-1),Days(day)}]);
        session_factor = Meta_data{idx(session)+mm,1};

        respCode = Datainfo.VSinfo.sMbmInfo.respCode;
        ReFactor = IdxRearrage(respCode,session_factor);

        % 分组
        if MUA_LFP == 1
            [repeatnum,ClusterData] = PicDataRearrange(ReFactor,Datainfo.trial_MUA{1});
        elseif MUA_LFP == 2
            [repeatnum,ClusterData] = PicDataRearrange(ReFactor,Datainfo.trial_MUA{2});
        elseif MUA_LFP == 3
            [repeatnum,ClusterData] = PicDataRearrange(ReFactor,Datainfo.trial_LFP);
        end

        allrepeat{day,session} = repeatnum;
        % session拼接（直接操作独立变量）
        %         for cond = 1:18
        %
        %             % 拼接 MGv
        %             if ~isempty(ClusterData.MGv{1,cond})
        %                 MGv(cond).Data = cat(1, MGv(cond).Data, ClusterData.MGv{1,cond});
        %                 MGv(cond).Pattern = cat(1, MGv(cond).Pattern, ClusterData.MGv{2,cond});
        %                 % MGv{1,cond} = cat(1, MGv{1,cond}, ClusterData.MGv{1,cond});
        %                 % MGv{2,cond} = cat(1, MGv{2,cond}, ClusterData.MGv{2,cond});
        %             end
        %             % 拼接 MGnv
        %             if ~isempty(ClusterData.MGnv{1,cond})
        %                 MGnv(cond).Data = cat(1, MGnv(cond).Data, ClusterData.MGnv{1,cond});
        %                 MGnv(cond).Pattern = cat(1, MGnv(cond).Pattern, ClusterData.MGnv{2,cond});
        %             %     MGnv{1,cond} = cat(1, MGnv{1,cond}, ClusterData.MGnv{1,cond});
        %             %     MGnv{2,cond} = cat(1, MGnv{2,cond}, ClusterData.MGnv{2,cond});
        %             end
        %             % 拼接 SG
        %             if ~isempty(ClusterData.SG{1,cond})
        %                 SG(cond).Data = cat(1, SG(cond).Data, ClusterData.SG{1,cond});
        %                 SG(cond).Pattern = cat(1, SG(cond).Pattern, ClusterData.SG{2,cond});
        %                 % SG{1,cond} = cat(1, SG{1,cond}, ClusterData.SG{1,cond});
        %                 % SG{2,cond} = cat(1, SG{2,cond}, ClusterData.SG{2,cond});
        %             end
        %         end

        % 拼接 SSGnv（13x18 cell）
        for loc = 1:13
            for cond = 1:18
                idx = find([SSGnv.Location] == loc & [SSGnv.Pic_Ori] == cond);
                if ~isempty(ClusterData.SSGnv{loc, cond})
                    SSGnv(idx).Data = cat(1, SSGnv(idx).Data, int16(ClusterData.SSGnv{loc, cond}));
                    % SSGnv{loc,cond} = cat(1, SSGnv{loc,cond}, ClusterData.SSGnv{loc,cond});

                end
            end
        end
        disp(size(SSGnv(217).Data,1));
        % 处理 blank 数据
        %         if ~isempty(ClusterData.blank)
        %             blank = cat(1, blank, ClusterData.blank);
        %         end
    end
end

MUAcondition = {'MUA1','MUA2','LFP'};
for i = 1:length(selected_blocks)
    block = selected_blocks{i};
    if exist(block, 'var') && ~isempty(eval(block))
        save(sprintf('DG_EVENT_Days%d_%d_%s_%s.mat', Days(1), Days(end),MUAcondition{MUA_LFP}, block), block,'-v7.3');
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
function [repeatnum,ClusterData] = PicDataRearrange(ReFactor,trialdata)
repeatnum(1:18) = struct('MGv',zeros(1,1),'MGnv',zeros(1,1),'SG',zeros(1,1));
ClusterData = struct(...
    'MGv',  {cell(2, 18)}, ...   % 1x11 cell
    'MGnv', {cell(2, 18)}, ...   % 1x11 cell
    'SG',   {cell(2, 18)}, ...   % 1x11 cell
    'SSGnv',{cell(13, 18)}, ...   % 13x11 cell
    'blank',[]);

beforesti = 100;
pictime = 20;
timewindow = -19:80;

for trial =1:length(ReFactor)
    % disp(trial);
    if iscell(ReFactor(trial).Block)
        currentBlock = ReFactor(trial).Block{1};
    else
        currentBlock = ReFactor(trial).Block;
    end

    % if strcmp(currentBlock,'SSGnv')
    %     loc = ReFactor(trial).location;
    %     for pic = [1,14,27,40]
    %         ori = ReFactor(trial).stim_sequence(pic);
    %
    %         window = beforesti+(pic-1)*pictime+timewindow;
    %         currentData = single(trialdata(trial,1:96,window));
    %
    %         baseline = mean(single(trialdata(trial,1:96,window(1:pictime))),3);
    %         filtered_data = currentData - baseline;
    %         ClusterData.SSGnv{loc,ori} = cat(1,ClusterData.SSGnv{loc,ori},filtered_data);
    %     end
    if strcmp(currentBlock,'Blank')
        ClusterData.blank = cat(1,ClusterData.blank,single(trialdata(trial,1:96,1:end)));
    elseif strcmp(currentBlock,'SSGnv')
        for pic = [1,14,27,40]
            ori = ReFactor(trial).Stim_Sequence(pic);
            location = ReFactor(trial).Location;
            % repeatnum(ori).(currentBlock) = repeatnum(ori).(currentBlock)+1;
            % pattern = ReFactor(trial).Pattern(pic);

            window = beforesti+(pic-1)*pictime+timewindow;
            currentData = single(trialdata(trial,1:96,window));

            baseline = mean(single(trialdata(trial,1:96,window(1:pictime))),3);
            filtered_data = int16(currentData - baseline);
            ClusterData.(currentBlock){location,ori} = cat(1,ClusterData.(currentBlock){location,ori},filtered_data);
            % ClusterData.(currentBlock){2,ori} = cat(1,ClusterData.(currentBlock){2,ori},pattern);
        end
    else
        for pic = [1,14,27,40]
            ori = ReFactor(trial).Stim_Sequence(pic);
            % repeatnum(ori).(currentBlock) = repeatnum(ori).(currentBlock)+1;
            pattern = ReFactor(trial).Pattern(pic);

            window = beforesti+(pic-1)*pictime+timewindow;
            currentData = single(trialdata(trial,1:96,window));

            baseline = mean(single(trialdata(trial,1:96,window(1:pictime))),3);
            filtered_data = int16(currentData - baseline);
            ClusterData.(currentBlock){1,ori} = cat(1,ClusterData.(currentBlock){1,ori},filtered_data);
            ClusterData.(currentBlock){2,ori} = cat(1,ClusterData.(currentBlock){2,ori},pattern);
        end
    end
end

end


