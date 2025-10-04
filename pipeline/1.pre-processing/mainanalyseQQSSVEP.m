%% -------------------------------第二只猴的数据处理---------------------------%
% SSVEP
dbstop if error
clear;

% 信号提取
Days =[1,5:8,11:13,15,17,18];
Days = 8;
MUA_LFP =3;
A_B = 'A';
selected_blocks= {'MGv', 'MGnv', 'SG', 'blank'};
bb = 1;
QQ_SSVEP_Process(selected_blocks,Days,MUA_LFP,A_B,bb);

% Pic信号提取（基于已经提取的trial数据）
% SSVEP_Pic(MUA_LFP,Days)
% clear;
% load('D:\\Ensemble coding\\QQdata\\QQChannelselect.mat','selected_coil_final');
% selected_blocks = {'MGv','MGnv','SG'};
% 
% Colors = [62,181,95;233,173,107;120,158,175;142,50,40]/255;
% savepath = 'DecodingcotentLFP';
% for m = 1:length(selected_blocks)
%     load(sprintf('SSVEP_PIC_DATA%sLFP.mat',selected_blocks{m}));
%     acc_real = [];
%     data = [];
%     n_shuffles = 50;
%     minnum = 3000;
%     for i = 1:108
%         num = size(SSVEP_PIC_DATA{i},1);
%         if num<=minnum
%             minnum = num;
%         end
%     end
%     minnum = floor(minnum/10)*10;
%     dim1 = minnum/10;
%     for i = 1:108
%         data1 = reshape(SSVEP_PIC_DATA{i}(1:minnum,selected_coil_final,:),[dim1,10,30,100]);
%         data1 = squmean(data1,2);
%         SSVEP_PIC_DATA{i} = data1;
%     end
% 
%     n = 1:18;
%     for i = 1:length(n)
%         dd = SSVEP_PIC_DATA(:,n(i));
%         dd = cat(1,dd{:});
%         num = size(dd,1);
% 
%         data(i,:,:,:) = dd(:,selected_coil_final,:);
%     end
%     clear SSVEP_PIC_DATA
% 
%     [chance_level, accuracy, p_value] = SVM_Decoding_LR(data,n_shuffles,selected_blocks{m},savepath);
%     clear data
%     save(sprintf('D:\\Ensemble plot\\QQdecoding\\newSSVEPorientationSVM_day_%sMUA2.mat',selected_blocks{m}),'chance_level','accuracy','p_value');
% end

%%
function QQ_SSVEP_Process(selected_blocks,Days,MUA_LFP,A_B,bb)

%SSVEP_A/B
load('D://Ensemble coding//QQdata//tooldata//QQSessionIdx.mat','SessionIdx');
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

if ismember('blank', selected_blocks)
    % blank(1) = struct('date', [], 'block', 'blank', 'location', [], 'Pic_Ori', [], 'Phase', [], 'data',[]);
    blank = [];
end

load('D:\\Ensemble coding\\QQdata\\tooldata\\QQ_metadata_SSVEP.mat','Meta_data');
for day = 1:length(Days)

    if strcmp(A_B,'A')
        realSession = SessionIdx{5,Days(day)};                              % 实际做的session
        Sessions = SessionIdx{6,Days(day)};                                 % 文件的编号
    else
        realSession = SessionIdx{8,Days(day)};
        Sessions = SessionIdx{9,Days(day)};
    end


    fprintf(sprintf('Start day%d\n',day));
    for session = 1:length(Sessions)
        fprintf(sprintf('Start Session%d\n',session));
        U = SessionIdx{1,Days(day)};                                        % 天的编号，eg.u088
        load(sprintf('D:\\Ensemble coding\\QQdata\\QQ2-%s-%03d-500hz.mat',U,Sessions(session)));

        % trial重排
        respCode = Datainfo.VSinfo.sMbmInfo.respCode;

        if strcmp(A_B,'A')
            idx = find(strcmp({Meta_data{:,2}},SessionIdx{3,Days(day)}));
            session_factor = Meta_data{idx(realSession(session)),1};
        else
            idx = find(strcmp({Meta_data{:,6}},SessionIdx{3,Days(day)}));
            session_factor = Meta_data{idx(realSession(session)),5};
        end
        ReFactor = IdxRearrage(respCode,session_factor);

        blank_idx(bb,:) = find(strcmp({ReFactor.Block},'blank'));
        bb=bb+1;
        disp(bb)
        % 分组
        % if MUA_LFP == 1
        %     ClusterData = TrialDataRearrange(ReFactor,Datainfo.trial_MUA{1});
        % elseif MUA_LFP == 2
        %     ClusterData = TrialDataRearrange(ReFactor,Datainfo.trial_MUA{2});
        % elseif MUA_LFP == 3
        %     ClusterData = TrialDataRearrange(ReFactor,Datainfo.trial_LFP);
        % end
        % condition = -1:2:17;
        % % session拼接
        % for cond = 1:10
        %     % 拼接 MGv
        %     if ~isempty(ClusterData.MGv{1,cond})
        %         MGv(cond).Data = cat(1, MGv(cond).Data, ClusterData.MGv{1,cond});
        %         MGv(cond).Pic_Ori = cat(1, MGv(cond).Pic_Ori, ClusterData.MGv{2,cond});
        %         MGv(cond).Target_Ori = condition(cond);
        %         MGv(cond).Pattern = cat(1, MGv(cond).Pattern, ClusterData.MGv{3,cond});
        %         % MGv{1,cond} = cat(1, MGv{1,cond}, ClusterData.MGv{1,cond});
        %         % MGv{2,cond} = cat(1, MGv{2,cond}, ClusterData.MGv{2,cond});
        %     end
        %     % 拼接 MGnv
        %     if ~isempty(ClusterData.MGnv{1,cond})
        %         MGnv(cond).Data = cat(1, MGnv(cond).Data, ClusterData.MGnv{1,cond});
        %         MGnv(cond).Pattern = cat(1, MGnv(cond).Pattern, ClusterData.MGnv{3,cond});
        %         MGnv(cond).Pic_Ori = cat(1, MGnv(cond).Pic_Ori, ClusterData.MGnv{2,cond});
        %         %     MGnv{1,cond} = cat(1, MGnv{1,cond}, ClusterData.MGnv{1,cond});
        %         %     MGnv{2,cond} = cat(1, MGnv{2,cond}, ClusterData.MGnv{2,cond});
        %     end
        %     % 拼接 SG
        %     if ~isempty(ClusterData.SG{1,cond})
        %         SG(cond).Data = cat(1, SG(cond).Data, ClusterData.SG{1,cond});
        %         SG(cond).Pattern = cat(1, SG(cond).Pattern, ClusterData.SG{3,cond});
        %         SG(cond).Pic_Ori = cat(1, SG(cond).Pic_Ori, ClusterData.SG{2,cond});
        %         % SG{1,cond} = cat(1, SG{1,cond}, ClusterData.SG{1,cond});
        %         % SG{2,cond} = cat(1, SG{2,cond}, ClusterData.SG{2,cond});
        %     end
        % end
        % 
        % % 拼接 SSGnv（13x18 cell）
        % % for loc = 1:13
        % %     for cond = 1:10
        % %         idx = find([SSGnv.Location] == loc & [SSGnv.Target_Ori] == condition(cond));
        % %         if ~isempty(ClusterData.SSGnv{1, loc, cond})
        % %             SSGnv(idx).Data = cat(1, SSGnv(idx).Data, ClusterData.SSGnv{1, loc, cond});
        % %             SSGnv(idx).Target_Ori = condition(cond);
        % %             SSGnv(idx).Pic_Ori = cat(1, SSGnv(cond).Pic_Ori, ClusterData.SSGnv{2,loc,cond});
        % %             % SSGnv{loc,cond} = cat(1, SSGnv{loc,cond}, ClusterData.SSGnv{loc,cond});
        % % 
        % %         end
        % %     end
        % % end
        % 
        % % 处理 blank 数据
        % if ~isempty(ClusterData.blank)
        %     blank = cat(1, blank, ClusterData.blank);
        % end
    end
end

if strcmp(A_B,'B')
    SSGv = SSGnv;
    selected_blocks = {'MGv', 'MGnv', 'SG', 'SSGv', 'blank'};
end
MUAcondition = {'MUA1','MUA2','LFP'};
for i = 1:length(selected_blocks)
    block = selected_blocks{i};
    if exist(block, 'var') && ~isempty(eval(block))
        save(sprintf('SSVEP%s_Days%d_%d_%s_%s.mat', A_B, Days(1), Days(end),MUAcondition{MUA_LFP}, block), block,'-v7.3');
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
    'blank',[]);

uniqueChars = unique({ReFactor.Block});  % 返回 {'A', 'B', 'C', 'D'}

charIndices = cell(1, length(uniqueChars));

for i = 1:length(uniqueChars)
    charIndices{i} = find(strcmp({ReFactor.Block}, uniqueChars{i}));
end


for i = 1:length(uniqueChars)
    currentBlock = uniqueChars{i};
    currentBlockidx = ReFactor(charIndices{i});
    % if strcmp(currentBlock,'SSGnv')
    %     for loc = 1:13
    %         condition = -1:2:17;
    %         for condi = 1:length(-1:2:17)
    %             idx = [currentBlockidx.location] == loc & [currentBlockidx.condition] == condition(condi);
    %             idx = charIndices{i}(idx);
    %             data = squeeze(trialdata(idx, 1:96, 1:1640));
    %             filteredData = data - mean(data(:,:,1:100));
    %             % if any(isnan(data(:))) || any(isinf(data(:)))
    %             % disp(min(data(:)));
    %             % disp(max(data(:)));
    %             % end
    %             % filteredData = filtfilt(b, a, single(data)')'; % 滤波
    %             % filteredData = reshape(filteredData,[1,96,1640]);
    %             ClusterData.SSGnv{1, loc, condi} = filteredData;
    % 
    %             ClusterData.SSGnv{2, loc,condi} = [ReFactor(idx).stim_sequence];
    %         end
    %     end
    % elseif strcmp(currentBlock,'SSGv')
    %     for loc = 1:13
    %         condition = -1:2:17;
    %         for condi = 1:length(-1:2:17)
    %             idx = [currentBlockidx.location] == loc & [currentBlockidx.condition] == condition(condi);
    %             idx = charIndices{i}(idx);
    %             data = squeeze(trialdata(idx, 1:96, 1:1640));
    %             filteredData = data - mean(data(:,:,1:100),3);
    %             % if any(isnan(data(:))) || any(isinf(data(:)))
    %             %     disp(min(data(:)));
    %             %     disp(max(data(:)));
    %             % end
    %             % filteredData = filtfilt(b, a, single(data)')'; % 滤波
    %             % filteredData = reshape(filteredData,[1,96,1640]);
    %             ClusterData.SSGnv{1, loc, condi} = filteredData;
    % 
    %             ClusterData.SSGnv{2, loc,condi} = [ReFactor(idx).stim_sequence];
    %         end
    %     end

    if strcmp(currentBlock,'blank')
        idx = charIndices{i};
        ClusterData.blank = cat(1,ClusterData.blank,single(trialdata(idx,1:96,1:1640)));
    elseif strcmp(currentBlock,'MGv') | strcmp(currentBlock,'MGnv') | strcmp(currentBlock,'SG') 
        condition = -1:2:17;
        for condi = 1:length(condition)
            idx = [currentBlockidx.Condition] == condition(condi);
            idx = charIndices{i}(idx);
            data = trialdata(idx, 1:96, 1:1640);
            filteredData = data - mean(data(:,:,1:100),3);
            % filteredData = filtfilt(b, a, single(data)')'; % 滤波
            % filteredData = reshape(filteredData,[1,96,1640]);
            ClusterData.(currentBlock){1,condi} = single(filteredData);
            ClusterData.(currentBlock){2,condi} = [ReFactor(idx).Stim_Sequence];
            ClusterData.(currentBlock){3,condi} = [ReFactor(idx).Pattern];
        end
    end


end
end


