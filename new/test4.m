dbstop if error
label = {'MGv'};
macaque = 'QQ';
file_path = sprintf('D:/Ensemble coding/%sdata/Processed_Event/',macaque);
MUA_LFP = 'MUA2';
for i = 1:length(label)
    filename = sprintf('%s_SSVEP_Days32_32_%s_%s.mat',macaque,MUA_LFP,label{i});
    file_idx{i} = fullfile(file_path,filename);
end


% SSVEP_Pic(file_idx,MUA_LFP,label);
SSVEP_Pic_Preallocated(file_idx, MUA_LFP, label)
%% SSVEP_pic
% 需要得到pre_ori,ori,phase
pre_ori = 9;
tuning = [];
for ori = 1:18
    if ~isempty(SSVEP_PIC_DATA{ori,pre_ori})
        tuning(ori,:,:) = squmean(SSVEP_PIC_DATA{ori,pre_ori},1);
    else
        tuning(ori,:,:) = zeros(96,100);
    end
end
figure;
load('D:\Ensemble coding\QQdata\tooldata\QQChannelMap.mat','QQchannelMap');
for i = 1:96
     n = find(QQchannelMap'==i);
     subplot(10,10,n);
     % imagesc(squeeze(tuning(:,i,:)));
     yyaxis left
     imagesc(squmean(comb_trial_signals(i,:,:,:),3)');
     yyaxis right
     plot(squmean(mean(comb_trial_signals(i,:,:,45:55),3),4))
end
%% fitting
% 需要进行拟合，以及残差
% 用1B的进行训练（无论是真实的还是拟合的），用1A进行解码。
% 用1B训练，解码1B会导致基线位置正确率高，这是由于前一张数量不一致，所以识别到前一张图片的时候就能知道后一张图片。
load('D:\Ensemble coding\QQdata\Processed_Event\QQ_SSVEP_Days9_27_LFP_MGv.mat')
% 

%%
tuning = [];
for ori =1:18
    data = cat(1,SSVEP_PIC_DATA{ori,:});
    if ~isempty(data)
        tuning(ori,:,:) = squmean(data,1);
    else
        tuning(ori,:,:) = zeros(96,100);
    end
end
%%

% load('D:\Ensemble coding\DGdata\tooldata\DGChannelMap.mat','DGchannelMap');
load('D:\Ensemble coding\QQdata\tooldata\QQChannelMap.mat','QQchannelMap');
P1_3d_target90 = {};
for location = 1:13
    
    idx = (location-1)*10+1;
    [P1_3d_target90{location},~,f] = SSVEP_fftanalyse(single(SSGv(idx).Data));
end
%%
figure;
    for i = 1:96
        n = find(QQchannelMap'==i);
        subplot(10,10,n);
        %plot(f(1:100),log10(squmean(P1_3d_random(:,i,1:100),1)))
        hold on
        for location = 13
        
        %plot(f(1:100),log10(squmean(P1_3d_target10(:,i,1:100),1)))
        plot(f(1:100),log10(squmean(P1_3d_target90{location}(:,i,1:100),1)))
        %     yyaxis left
        %     imagesc(squeeze(tuning(:,i,:))');
        %     plot(f(1:100),data(i,1:100));
        %     imagesc(squeeze(tuning([1:8,10:18],i,:)));
        %     plot(squmean(tuning([1:14,16:18],i,45:55),3),'LineStyle','-','Marker','o','MarkerFaceColor','blue','LineWidth',1.5);
        %     hold on
        %     yyaxis right
        %     plot(squmean(tuning(:,i,45:55),3),'LineWidth',1.5);
        end
        xline([6.25,25],'--');
        box off
        hold off
    end
%%
figure;
for i = 1:96
    n = find(QQchannelMap'==i);
    subplot(10,10,n);
    hold on
    plot(f(30:100),log10(squmean(P1_3d_random(:,i,30:100),1)),'Color',[0.5,0.5,0.5]);
    plot(f(30:100),log10(squmean(P1_3d_target10(:,i,30:100),1)),'Color',[0.7,0,0],'LineWidth',2);
    plot(f(30:100),log10(squmean(P1_3d_target90(:,i,30:100),1)),'Color',[0,0,0.7],'LineWidth',2);
    xline([12.5,25],'--');
    box off
    hold off
end

%%
accuracy_m = [];
selected_coil_final = [7,9,13,17,18,19,21,22,23,24,25,27,35,38,39,41,51,61,73,74,80,82,84,87,89]+1;
for ori = 1:18
    disp(ori)
    idx = setdiff(1:18,ori);
    data = [];
    minnum = 300;
    for i =1:length(idx)
        if size(SSVEP_PIC_DATA{idx(i),ori},1)<minnum
            minnum = size(SSVEP_PIC_DATA{idx(i),ori},1);
        end
    end
    for i =1:length(idx)
        data(i,:,:,:) = single(int16(SSVEP_PIC_DATA{idx(i),ori}(1:minnum,:,:)));
    end
    [chance_level, accuracy, p_value] = SVM_Decoding_LR(data(:,:,selected_coil_final,:),1,'1','1');
    accuracy_m(ori,:) = accuracy;
end
%% 
selected_coil_final = [7,9,13,17,18,19,21,22,23,24,25,27,35,38,39,41,51,61,73,74,80,82,84,87,89]+1;
sequence.random = random;
sequence.target10 = target10;
sequence.target90 = target90;
load('D:\Ensemble coding\SSVEP_PIC_DATA_1B_QQ_LFP_MGv.mat')
label = {'random','target10','target90'};
for m = 1:3
    data = zeros(96,1640);
    for i = 2:72
        pic = sequence.(label{m})(i);
        prepic = sequence.(label{m})(i-1);
        window  = 120+(((i-1)*20+1):(i+1)*20);
        data(:,window) = data(:,window)+squmean(SSVEP_PIC_DATA{pic,prepic}(:,:,21:60),1);
    end
    data = reshape(data,[1,96,1640]);
    [P1_3d.(label{m}),Phase_3d,f] = SSVEP_fftanalyse(data);
end
figure;
hold on
for m = 1:3
plot(f(1:100),log10(squmean(P1_3d.(label{m})(1,selected_coil_final,1:100),2)));
end
xline([6.25,25],'--');


%%
a = [];
for ori = 1:18
    a(ori) = size(cat(1,SSVEP_PIC_DATA{:,ori}),1);
end
a = min(a);
data = [];
for ori = 1:18
    data1 = [];
    data1 = cat(1,SSVEP_PIC_DATA{:,ori});
    for i = 1:18
        SSVEP_PIC_DATA{i,ori} = [];
    end
    data(ori,:,:,:) =int8(data1(1:a,:,:)); 
end

%%
d = 21;
for location = 1:13
    signal = squmean(mean(P1_3d_target90{location}(:,:,d:d),1),3);
    noise = squmean(mean(P1_3d_target90{location}(:,:,d-1:d+1),1),3);
    matrix_1(location,:) = signal - noise;
end
d = 81;
for location = 1:13
    signal = squmean(mean(P1_3d_target90{location}(:,:,d:d),1),3);
    noise = squmean(mean(P1_3d_target90{location}(:,:,d-1:d+1),1),3);
    matrix_2(location,:) = signal - noise;
end

%% 独立通道拟合
% clearvars -except MGv SSGv SG MGnv
% factor = 1;
% R = {};
% W = {};
% fitting_data = {};
% MGvrandom = squmean(MGv(1).Data,1);
% MGvtarget10 = squmean(MGv(2).Data,1);
% MGvtarget90= squmean(MGv(6).Data,1);
% % MGvrandom = squmean(SSGv(121).Data,1);
% % MGvtarget10 = squmean(SSGv(122).Data,1);
% % MGvtarget90 = squmean(SSGv(126).Data,1);
% for location = 1:12
%     idx = (location-1)*10+1;
%     SSGvrandom(:,:,location) = squmean(SSGv(idx).Data,1);
%     SSGvtarget10(:,:,location) = squmean(SSGv(idx+1).Data,1);
%     SSGvtarget90(:,:,location) = squmean(SSGv(idx+5).Data,1);
% end
% [R{1},W{1},fitting_data{1}] = trial_fitting(MGvrandom,SSGvrandom,factor);
% [R{2},W{2},fitting_data{2}] = trial_fitting(MGvtarget10,SSGvtarget10,factor);
% [R{3},W{3},fitting_data{3}] = trial_fitting(MGvtarget90,SSGvtarget90,factor);

%% 拟合优度直方图
% figure('Position',[100,0,400,1300]);
% subplot(4,1,1)
% label = {'Random', 'Target10', 'Target90'};
% hold on;
% h = gobjects(1, 3);
% color = [0.5,0.5,0.5;
%     0.7,0,0;
%     0.2,0.2,0.7];
% for i = 1:3
%     h(i) = histogram(R{i}, 0.3:0.05:0.8, 'FaceColor', color(i,:), 'FaceAlpha', 0.6);
% end
% lgd = legend(h, {'Random', 'Target10', 'Target90'});
% lgd.AutoUpdate = 'off';
% for i = 1:3
%     xline(mean(R{i}), '--', 'Color', color(i,:), ...
%         'HandleVisibility', 'off', 'LineWidth', 2);
% end
% hold off;
% subtitle('拟合优度直方图')
% % 权重热图
% for i = 1:3
%     subplot(4,1,i+1)
%     if factor == 0
%         imagesc(W{i}(:,2:end));
%     elseif factor ==1
%         imagesc(W{i});
%     end
% 
%     caxis([-1,1]);
%     subtitle(sprintf('%s权重',label{i}))
% end
% sgtitle('lsqlin & location12')
%% 绘制SSGv
% figure;
% locationidx = [18,12,8,14,23,17,11,7,3,9,15,19,13];
% for i = 1:13
%     disp(i);
%     subplot(5,5,locationidx(i));
%     hold on
%     idx = (i-1)*10+1;
% 
%     [P1_3d_random,~,f] = SSVEP_fftanalyse(double(SSGv(idx+1).Data));
% 
%     plot(1:20,log10(squmean(mean(P1_3d_random(:,:,11:30),1),2)),'color',[0.7,0,0],'LineWidth',2);
%     plot(26:45,log10(squmean(mean(P1_3d_random(:,:,71:90),1),2)),'color',[0.7,0,0],'LineWidth',2);
% 
%     [P1_3d_random,~,~] = SSVEP_fftanalyse(double(SSGv(idx+5).Data));
%     plot(1:20,log10(squmean(mean(P1_3d_random(:,:,11:30),1),2)),'color',[0.2,0.1,0.7],'LineWidth',2);
%     plot(26:45,log10(squmean(mean(P1_3d_random(:,:,71:90),1),2)),'color',[0.2,0.1,0.7],'LineWidth',2);    
% 
%     [P1_3d_random,~,~] = SSVEP_fftanalyse(double(SSGv(idx).Data));
%     plot(1:20,log10(squmean(mean(P1_3d_random(:,:,11:30),1),2)),'color',[0.5,0.5,0.5],'LineWidth',1.5);
%     plot(26:45,log10(squmean(mean(P1_3d_random(:,:,71:90),1),2)),'color',[0.5,0.5,0.5],'LineWidth',1.5);
%     xticks([0:10:20,25:10:45])
%     xticklabels({'3.1','5.9','9.0','21.9','24.7','27.8'});
%     xline([11,36],'--');
%     box off;
%     hold off
%     subtitle(sprintf('Location%d',i))
% end
%% 绘制其余条件频谱图
% figure;
% hold on
% data = reshape(fitting_data{1},[1,96,1640]);
% [P1_3d_random,~,~] = SSVEP_fftanalyse(double(data));
% plot(1:20,log10(squmean(mean(P1_3d_random(:,:,11:30),1),2)),'color',[0.5,0.5,0.5],'LineWidth',2);
% plot(26:45,log10(squmean(mean(P1_3d_random(:,:,71:90),1),2)),'color',[0.5,0.5,0.5],'LineWidth',2);
% 
% data = reshape(fitting_data{2},[1,96,1640]);
% [P1_3d_random,~,~] = SSVEP_fftanalyse(double(data));
% plot(1:20,log10(squmean(mean(P1_3d_random(:,:,11:30),1),2)),'color',[0.7,0,0],'LineWidth',2);
% plot(26:45,log10(squmean(mean(P1_3d_random(:,:,71:90),1),2)),'color',[0.7,0,0],'LineWidth',2);
% 
% data = reshape(fitting_data{3},[1,96,1640]);
% [P1_3d_random,~,~] = SSVEP_fftanalyse(double(data));
% plot(1:20,log10(squmean(mean(P1_3d_random(:,:,11:30),1),2)),'color',[0.2,0.1,0.7],'LineWidth',2);
% plot(26:45,log10(squmean(mean(P1_3d_random(:,:,71:90),1),2)),'color',[0.2,0.1,0.7],'LineWidth',2);
% xticks([0:10:20,25:10:45])
% xticklabels({'3.1','5.9','9.0','21.9','24.7','27.8'});
% xline([11,36],'--');
% box off;
% hold off
% title('fitting MGv')
%% 不改变顺序的图片拟合
% MGvrandom = squmean(MGv(1).Data,1);
% SSGvrandom = [];
% R = {};
% W = {};
% fitting_data = {};
% winbin = 20;
% loc1 = 1:12;
% for loc = 1:length(loc1)
%     location = loc1(loc);
%     idx = (location-1)*10+1;
%     SSGvrandom(:,:,loc) = squmean(SSGv(idx).Data,1);
% %     SSGvtarget10(:,:,location) = squmean(SSGv(idx+1).Data,1);
% %     SSGvtarget90(:,:,location) = squmean(SSGv(idx+5).Data,1);
% end
% for pic = 1:72
%     timewin =  ((pic-1)*20+101):(pic*20+80+winbin);
%     MGv_pic_data = MGvrandom(:,timewin);
%     SSGv_pic_data = SSGvrandom(:,timewin,:);
%     [R{pic},W{pic},fitting_data{pic}] = trial_fitting(MGv_pic_data,SSGv_pic_data,1);
% end
% figure;
% a = cat(2,R{:});
% a = mean(a(selected_coil_final,:),2);
% histogram(a);

%% 提取图片的图片拟合
% clearvars -except MGv SSGv
var_names = {'random','target10','target90'};
R = {};
W = {};
fitting_data = {};
factor = 0;

    for ori = 1:18
        MGv1 = squmean(MGnv(ori).Data,1);
        idx = ori:18:234;
        SSGv1 = squmean(cat(4,SSGnv(idx).Data),1);
        [R{ori},W{ori},fitting_data{ori}] = trial_fitting(MGv1,SSGv1(:,:,1:13),factor);
    end

% SSGv= cell(18,13);
% for i = 1:18
%     for l = 1:13
%         SSGv{i,l} = squmean(SSVEP_PIC_DATA{i,l},1);
%     end
% end
% MGv = cell(18,1);
% for i = 1:18
%     MGv{i} = cat(1,SSVEP_PIC_DATA{i,:});
% end
%% 绘制pic拟合的权重与拟合优度
% figure('Position',[100,0,300,1300]);
% selected_coil_final = [7,9,13,17,18,19,21,22,23,24,25,27,35,38,39,41,51,61,73,74,80,82,84,87,89]+1;
% subplot(4,1,1)
% label = {'Random', 'Target10', 'Target90'};
% color = [0.5,0.5,0.5;
%     0.7,0,0;
%     0.2,0.2,0.7];
% for i = 1:3
%     hold on 
%     a = [];
%     myCell = R(i,:);
%     a = mean(cat(3, myCell{~cellfun(@isempty, myCell)}), 3);
%     histogram(a,0:0.05:0.5,'FaceColor',color(i,:));
%     xline(mean(a),'--','Color',color(i,:))
% end
% 
% set(gca, 'LineWidth', 2);
% set(gca,'FontWeight','bold','FontSize',12)
% subtitle('R')
% box off
% for i = 1:3
% subplot(4,1,i+1)
% imagesc(W{i,1}(:,2:end));
% set(gca,'FontWeight','bold','FontSize',12)
% box off
% subtitle(sprintf('%s',label{i}))
% if i == 3
%     xlabel('Location')
% end
% end
% 
% sgtitle('fitlm & location12','FontSize', 16,'FontWeight','bold')
%% 信号绘制
% figure('Position',[100,100,200,700])
% for i = 1:15
%     subplot(15,1,i);
%     if i == 1
%         
%         meanMGv = mean(cat(3,MGv{:}),3);
%         plot(mean(meanMGv(selected_coil_final,:),1),'Color',[0.2,0.2,0.2],'LineWidth',1.5);
%     elseif i == 2
% 
%         meanfitting = mean(cat(3,fitting_data{:}),3);
%         plot(mean(meanfitting(selected_coil_final,:),1),'Color',[0.2,0.2,0.2],'LineWidth',1.5);
%     else
% 
%         meanSSGv = mean(cat(3,SSGv{:,i-2}),3);
%         plot(mean(meanSSGv(selected_coil_final,:),1),'Color',[0.2,0.2,0.2],'LineWidth',1.5);
%     end
%     box off
%     set(gca, 'YColor', 'none');
%     set(gca, 'LineWidth', 2);
%     set(gca,'FontWeight','bold')
% 
%     if i < 15
%         set(gca, 'XColor', 'none');
%     end
% end


%% Exp1b的解码 - 优化版本

% 
% trial_counts = cellfun(@(x) size(x, 1), SSVEP_PIC_DATA);
% max_trials = max(trial_counts);
% 
% first_non_empty_idx = find(~cellfun('isempty', SSVEP_PIC_DATA), 1, 'first');
% if isempty(first_non_empty_idx)
%     error('SSVEP_PIC_DATA 中所有cell都为空，无法继续处理。');
% end
% 
% [~, num_channels, num_timepoints] = size(SSVEP_PIC_DATA{first_non_empty_idx});
% 
% data_type = class(SSVEP_PIC_DATA{first_non_empty_idx});
% 
% data = zeros(18, max_trials, num_channels, num_timepoints, data_type);
% 
% 
% for ori = 1:18
%     % 获取当前方向的原始数据
%     
% %     % 如果当前cell为空，则跳过，对应data中的切片将保持为零
% %     if isempty(original_data_chunk)
% %         continue;
% %     end
%     original_data_chunk = SSVEP_PIC_DATA{ori};
%     current_trials = trial_counts(ori);
%     
% 
%     data(ori, 1:current_trials, :, :) = original_data_chunk;
%     
% 
%     num_to_add = max_trials - current_trials;
%     if num_to_add > 0
% 
%         random_indices = randi(current_trials, [num_to_add, 1]);
%         
% 
%         trials_to_add = original_data_chunk(random_indices, :, :);
%         
% 
%         data(ori, (current_trials + 1):max_trials, :, :) = trials_to_add;
%     end
% end
% 
% 
% clear SSVEP_PIC_DATA;
% [chance_level, accuracy, p_value] = SVM_Decoding_LR(data(:,:,selected_coil_final,:), 1, '1', '1');

%%
% accuracy = [];
% for location = 1:13
%     data = [];
%     for ori = 1:18
%         data(ori,:,:,:) = single(SSGnv(ori+(location-1)*18).Data);
%         SSGnv(ori+(location-1)*18).Data = [];
%     end
%     [chance_level, accuracy(location,:), p_value] = SVM_Decoding_LR(data,1,'1','1');
% end
%% --- 拟合后解码

% 假设 SSVEP_PIC_DATA 和 W_lsqlin 已经存在
% SSVEP_PIC_DATA: 12x18 cell, 每个 cell 是 [532, num_channels, num_timepoints]
% W_lsqlin:       1x18 cell, 每个 cell 是 [num_channels, 12]
minnum = 532;
% 获取维度信息 (从第一个非空cell)
first_non_empty_idx = find(~cellfun('isempty', SSVEP_PIC_DATA));
if isempty(first_non_empty_idx)
    error('SSVEP_PIC_DATA is empty.');
end
[num_trials, num_channels, num_timepoints] = size(SSVEP_PIC_DATA{first_non_empty_idx(1)});

num_orientations = 18;
num_locations = 12;


% --- 1. 预分配内存 ---
% 创建一个 12x18 的元胞数组
SSVEP_PIC_DATA_lsqlinedMGv = cell(18, 12);

% 遍历并初始化每个元胞
for ori = 1:num_orientations
    for loc = 1:num_locations
        if ~isempty(SSVEP_PIC_DATA{ori, loc})
            % 为每个cell创建一个与原始数据同样大小的全零矩阵
            SSVEP_PIC_DATA_lsqlinedMGv{ori, loc} = zeros(532, num_channels, num_timepoints, 'single');
        end
    end
end
fprintf('Memory pre-allocated for a %d x %d cell array.\n', num_locations, num_orientations);


% --- 2. 向量化重构核心计算 ---
% 我们将用两层循环遍历 ori 和 location，但内层的 trial 循环将被消除

fprintf('Starting vectorized computation...\n');
tic; % 开始计时

% 外层循环遍历18个 orientation
for ori = 1:num_orientations
    
    % 获取当前ori对应的权重矩阵 (所有location的权重都在里面)
    % weights_for_ori 的维度是 [channels, locations]
    weights_for_ori = W_lsqlin{1, ori};
    
    % 第二层循环遍历12个 location
    for loc = 1:num_locations
        
        % 如果当前 {loc, ori} 没有数据，则跳过
        if isempty(SSVEP_PIC_DATA{ori, loc})
            continue;
        end
        
        % --- 数据准备 ---
        % data: [trials, channels, time]
        data = SSVEP_PIC_DATA{ori, loc}(1:532,:,:);
        
        % 从权重矩阵中提取当前location对应的权重列向量
        % weights_vector 的维度是 [channels, 1]
        weights_vector = weights_for_ori(:, loc);
        
        % --- 向量化`trial`循环 ---
        % 我们需要用 weights_vector 去乘以 data 矩阵
        % data: [trials, channels, time]
        % weights_vector: [channels, 1]
        
        % 利用广播机制，我们需要将权重向量reshape成可以和data矩阵进行元素级乘法的形状
        % 将 [channels, 1] 变成 [1, channels, 1]
        reshaped_weights = reshape(weights_vector, [1, num_channels, 1]);
        
        % --- 执行计算 ---
        % 这一行代码代替了你的 trial 循环！
        % 它一次性对所有trial和所有timepoint进行加权
        SSVEP_PIC_DATA_lsqlinedMGv{ori, loc} = single(data) .* reshaped_weights;
    end
end

toc; % 结束计时
fprintf('Computation finished.\n');
for ori = 1:18
    matrix1 = cat(4,SSVEP_PIC_DATA_lsqlinedMGv{ori,:});
    lsqlin_MGv{ori} = sum(matrix1,4);
end
save('lsqlin_MGv.mat','lsqlin_MGv');
