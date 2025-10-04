%% -------------------------------第二只猴的数据处理---------------------------%
% Event

clear;
dbstop if error

% -------------------------- Script Configuration ----------------------- %

% Days = [2:4,9:14];
% MUA_LFP =2;
% selected_blocks= {'MGv', 'MGnv', 'SG', 'SSGnv', 'blank'};
% output_data_path = 'D:\Ensemble coding\QQdata\Processed\'; % Define a path for processed data
% input_raw_data_path = 'D:\Ensemble coding\QQdata\'; % Base path for raw data
% stim_info_path = 'D:\Ensemble coding\sti\GSQdataEventAll.mat'; % Path to stimulus info
% session_idx_path = 'D:\Ensemble coding\QQdata\QQSessionIdx.mat'; % Path to session index
% 
% if ~exist(output_data_path, 'dir')
%     mkdir(output_data_path);
% end
% 
% fprintf('Starting Signal Extraction...\n');
% allrepeat=QQ_Event_Process(selected_blocks,Days,MUA_LFP);
% fprintf('Signal Extraction Complete.\n');

%------------------------------- Decoding --------------------------------%

Days = [2:4,9:14];
MUA_LFP_flag ='MUA2';
selected_blocks= {'MGv', 'MGnv', 'SG'};

fprintf('Starting Decoding Process...\n');
QQ_Event_Decoding(selected_blocks,MUA_LFP_flag,Days);   
fprintf('Decoding Process Complete.\n');

% -------------------------------Decoding plot ---------------------------%
% decoding_output_path = 'D:\Ensemble plot\QQdecoding\';
% Days = [2,18];
% MUA_LFP_decode_str = 'MUA2';
% Chance_Level = 1/6;
% % Accuracy_files = {fullfile(decoding_output_path, sprintf('orientationSVM%d_%dday_MGv%s.mat', Days(1), Days(end), MUA_LFP_decode_str)),...
% %                   fullfile(decoding_output_path, sprintf('orientationSVM%d_%dday_MGnv%s.mat', Days(1), Days(end), MUA_LFP_decode_str)),...
% %                   fullfile(decoding_output_path, sprintf('orientationSVM%d_%dday_SG%s.mat', Days(1), Days(end), MUA_LFP_decode_str))};
% Accuracy_files = {fullfile(decoding_output_path, sprintf('PatternSVM%d_%dday_MGv%s.mat', Days(1), Days(end), MUA_LFP_decode_str))};
% Colors = [62,181,95;233,173,107;120,158,175;142,50,40]/255;
% fprintf('Starting Decoding Plotting...\n');
% % Ensure SVM_Decoding_Plot function is available and handles potential file-not-found errors.
% try
%     SVM_Decoding_Plot(Accuracy_files, Colors, Chance_Level);
%     fprintf('Decoding Plotting Complete.\n');
% catch ME
%     fprintf('Error during plotting: %s\n', ME.message);
% end

% ----------------------------------信号提出--------------------------------%
function allrepeat=QQ_Event_Process(selected_blocks,Days,MUA_LFP)
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
        % respCode = Datainfo.VSinfo.sMbmInfo.respCode;
        idx = find(strcmp({final_sessions{:,2}},SessionIdx{3,Days(day)}));
        session_factor = final_sessions{idx(realSession(session)),1};

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
        for cond = 1:18
            
            % 拼接 MGv
            if ~isempty(ClusterData.MGv{1,cond})
                MGv(cond).Data = cat(1, MGv(cond).Data, ClusterData.MGv{1,cond});
                MGv(cond).Pattern = cat(1, MGv(cond).Pattern, ClusterData.MGv{2,cond});
                % MGv{1,cond} = cat(1, MGv{1,cond}, ClusterData.MGv{1,cond});
                % MGv{2,cond} = cat(1, MGv{2,cond}, ClusterData.MGv{2,cond});
            end
            % 拼接 MGnv
            if ~isempty(ClusterData.MGnv{1,cond})
                MGnv(cond).Data = cat(1, MGnv(cond).Data, ClusterData.MGnv{1,cond});
                MGnv(cond).Pattern = cat(1, MGnv(cond).Pattern, ClusterData.MGnv{2,cond});
            %     MGnv{1,cond} = cat(1, MGnv{1,cond}, ClusterData.MGnv{1,cond});
            %     MGnv{2,cond} = cat(1, MGnv{2,cond}, ClusterData.MGnv{2,cond});
            end
            % 拼接 SG
            if ~isempty(ClusterData.SG{1,cond})
                SG(cond).Data = cat(1, SG(cond).Data, ClusterData.SG{1,cond});
                SG(cond).Pattern = cat(1, SG(cond).Pattern, ClusterData.SG{2,cond});
                % SG{1,cond} = cat(1, SG{1,cond}, ClusterData.SG{1,cond});
                % SG{2,cond} = cat(1, SG{2,cond}, ClusterData.SG{2,cond});
            end
        end

        % 拼接 SSGnv（13x18 cell）
        for loc = 1:13
            for cond = 1:18
                idx = find([SSGnv.Location] == loc & [SSGnv.Pic_Ori] == cond);
                if ~isempty(ClusterData.SSGnv{loc, cond})
                    SSGnv(idx).Data = cat(1, SSGnv(idx).Data, ClusterData.SSGnv{loc, cond});
                    % SSGnv{loc,cond} = cat(1, SSGnv{loc,cond}, ClusterData.SSGnv{loc,cond});
                    
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
        save(sprintf('EVENT_Days%d_%d_%s_%s.mat', Days(1), Days(end),MUAcondition{MUA_LFP}, block), block,'-v7.3');
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
    disp(trial);
    currentBlock = ReFactor(trial).block;
    
    if strcmp(currentBlock,'SSGnv')
        loc = ReFactor(trial).location;
        for pic = [1,14,27,40]
            ori = ReFactor(trial).stim_sequence(pic);
            
            window = beforesti+(pic-1)*pictime+timewindow;
            currentData = single(trialdata(trial,1:96,window));
            
            baseline = mean(single(trialdata(trial,1:96,window(1:pictime))),3);
            filtered_data = currentData - baseline;
            ClusterData.SSGnv{loc,ori} = cat(1,ClusterData.SSGnv{loc,ori},filtered_data);
        end
    elseif strcmp(currentBlock,'blank')
        ClusterData.blank = cat(1,ClusterData.blank,single(trialdata(trial,1:96,1:end)));
    else
        for pic = [1,14,27,40]
            ori = ReFactor(trial).stim_sequence(pic);
            repeatnum(ori).(currentBlock) = repeatnum(ori).(currentBlock)+1;
            pattern = ReFactor(trial).pattern(pic);
            
            window = beforesti+(pic-1)*pictime+timewindow;
            currentData = single(trialdata(trial,1:96,window));
            
            baseline = mean(single(trialdata(trial,1:96,window(1:pictime))),3);
            filtered_data = currentData - baseline;
            ClusterData.(currentBlock){1,ori} = cat(1,ClusterData.(currentBlock){1,ori},filtered_data);
            ClusterData.(currentBlock){2,ori} = cat(1,ClusterData.(currentBlock){2,ori},pattern);
        end
    end
end

end


%-------------------------------- Ori decoding--------------------------------------%
function QQ_Event_Decoding(selected_blocks,MUA_LFP,Days)
% m = load('D:\\Ensemble coding\\QQdata\\QQSNR.mat');
% [~,coilidx] = sort(m.SNR,'descend');
% coilselect = coilidx(1:coilnum);

% coilselect = [0, 5, 9, 11, 15, 17, 18, 19, 22, 23, 24, 26, 33, 34, 38, 40, 41, 42, 48, 51, 52, 53, 66, 72, 73, 78, 79, 82, 84, 87, 89]+1;
coilselect =[7, 9, 13, 14, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 30, 38, 42, 45, 51, 53, 61, 62, 66, 73, 76, 82, 83, 84, 86, 87, 89]+1;
% 分类数量
clusternum = 18;
n_shuffles = 50;

% decoding，每个pre下进行一次
for i = 1:length(selected_blocks)
    savepath = 'DecodingcontentEvent_Ori';
    predata = load(sprintf('D:\\EVENT_Days%d_%d_%s_%s.mat',Days(1),Days(end),MUA_LFP,selected_blocks{i}));
    
    if i == 1
        patterndata = predata.(selected_blocks{i})(5).Data;
    end
    
    tic;

    % 提取数据
    data_cell = arrayfun(@(ori) predata.(selected_blocks{i})(ori).Data, 1:clusternum, 'UniformOutput', false);
    patternidx = arrayfun(@(ori) predata.(selected_blocks{i})(ori).Pattern, 1:clusternum, 'UniformOutput', false);

    % 计算最小trial数（取200和实际最小值的较小者）
    minnum = 200;
    minnum = min([minnum, cellfun(@(x) size(x,1), data_cell)]);
    clear predata
    
    data_reshaped = single(zeros(18,minnum,length(coilselect),size(data_cell{1},3)));
    for ori = 1:18
        data_reshaped(ori,:,:,:) = data_cell{ori}(1:minnum,coilselect,:);
    end
    
    clear data_cell
    [chance_level, accuracy, p_value] = SVM_Decoding_LR(data_reshaped,n_shuffles,selected_blocks{i},savepath);

    save(sprintf('D:\\Ensemble plot\\QQdecoding\\orientationSVM%d_%dday_%s%s.mat',Days(1),Days(end),selected_blocks{i},MUA_LFP),'accuracy','p_value','chance_level');
    %save(sprintf('D:\\Ensembe plot\\QQdecoding\\orientationSVM2_9day_%s%s_model.mat',selected_blocks{i},MUA_LFP),'accuracymodel','shufflemodel','-v7.3');

    clear shuffle_acc accuracy data_reshaped accuracymodel shufflemodel
    fprintf(sprintf('complete_ori%s',selected_blocks{i}));
    toc;


    %----------------------pattern decoding---------------------%
    % if i == 1
    %     tic;
    %     savepath = 'DecodingcontentEvent_Pattern';
    %     % 最小重复次数
    %     minnum = min(cellfun(@(x) sum(patternidx{5} == x), num2cell(1:6)));
    %     data_reshaped = zeros(6,minnum,length(coilselect),size(patterndata,3));
    %     % 提取数据并拼接
    %     for pattern = 1:6
    %         idx = find(patternidx{5} == pattern);
    %         data_reshaped(pattern,:,:,:) = patterndata(idx(1:minnum),coilselect,:);
    %     end
    % 
    %     clear patterndata
    % 
    %     % 线性SVM解码
    %     [chance_level, accuracy, p_value] = SVM_Decoding_LR(data_reshaped,n_shuffles,selected_blocks{i},savepath);
    %     fprintf(sprintf('complete_pattern%s',selected_blocks{i}));
    %     save(sprintf('D:\\Ensemble plot\\QQdecoding\\PatternSVM%d_%dday_%s%s.mat',Days(1),Days(end),selected_blocks{i},MUA_LFP),'accuracy','p_value','chance_level');
    %     % save(sprintf('D:\\Ensembe plot\\QQdecoding\\PatternSVM2_9day_%s%s_model.mat',selected_blocks{i},MUA_LFP),'accuracymodel','shufflemodel','-v7.3');
    %     toc;
    % 
    % end
end
end


