%% Yge_data pre
labels = {'MGv','MGnv','SG','centerSSGnv'};
Yge_labels = {'EC1','EC0','SC','SSC'};
macaque = {'DG','QQ','QQ'};
Yge_macaque = {'SCECEC0SSC_Dataset3-FigureMap.mat','NorSCECEC0SSC_Dataset3-FigureMap.mat','SmallSize_SCECEC0SSC_Dataset3-FigureMap.mat'};
Days = [25,29; 2,27; 39,42];
for mac = 2
    
    load(sprintf('D:/ensemble_coding/middata/Yge_data/%s',Yge_macaque{mac}),'FigureOriMap');
    FigureOriMap.EC1 = FigureOriMap.EC(:,1:3:324,:,:);

    for i = 4
        fprintf('start %s %s',macaque{mac},labels{i});
        predata = struct();
        for ori = 1:18
            if i == 1
                idx = (1:6) + (ori-1)*6;
            else
                idx = ori:18:108;
            end
            if i ~= 4
                pre0 = FigureOriMap.(Yge_labels{i})(:,idx,:,:);

            else
                if mac == 2
                    pre0 = squeeze(FigureOriMap.(Yge_labels{i})(:,13,idx,:,:));
                else
                    pre0 = squeeze(FigureOriMap.(Yge_labels{i})(13,:,idx,:,:));
                end

            end
            [trial_num,~,time_point,channel_num] = size(pre0);
            pre0 = permute(pre0,[1,2,4,3]);
            predata.(labels{i})(ori).Data = reshape(pre0,[trial_num*6,channel_num,time_point]);


        end
        data_date = Days(mac,:);
        file_path = sprintf('D:/ensemble_coding/%sdata/Processed_Event/',macaque{mac});
        filename = sprintf('%s_EVENT_Days%d_%d_MUA2_%s_Yge.mat',macaque{mac},data_date(1),data_date(2),labels{i});
        full_path = fullfile(file_path,filename);
        save(full_path,'-struct','predata',labels{i})
    end
end
%% Decoding1
a = {'DG','QQ','QQ'};
b = {'DG','QQ_old','QQ_new'};
c = {'LFP','MUA2'};
d = [25,29; 2,27; 39,42];
label = {'MGv','MGnv','SG','centerSSGnv'};
load('D:\ensemble_coding\middata\SNR\sel_channel_Yge_all.mat','C');

for fangan = 1:2
    if fangan == 1
        e = {'1.8','2.1','2.4'};
        f = 'ThreSNR';
    else
        e = {'40%','60%','80%'};
        f = 'ThreNum';
    end

    for tren = 1:3
        % load(sprintf('D:/ensemble_coding/middata/decoding/Yge_data/decoding_result_Yge_all%s_Ygedata.mat',e{tren}),"decoding_result");
        for macaque_idx = 1:3
            macaque = a{macaque_idx};
            file_path = sprintf('D:/ensemble_coding/%sdata/Processed_Event/',macaque);
            for data_idx = 2
                mua_lfp = c{data_idx};
                channels = C.(f).UseChan{macaque_idx}{2}{tren};
                if macaque_idx == 3
                    channels = setdiff(channels,[95,96]);
                end
                % subtitles = {'channelsnum = 20','channelsnum = 45','channelsnum = 20','channelsnum = 45'};

                for i = 1:length(label)
                    data_date = d(macaque_idx,:);
                    filename = sprintf('%s_EVENT_Days%d_%d_%s_%s_Yge.mat',macaque,data_date(1),data_date(2),mua_lfp,label{i});
                    file_idx{i} = fullfile(file_path,filename);
                end
                for i = 1:4
                    fprintf(label{i})
                    predata = load(file_idx{i});
                    minnum = 1000;
                    for ori = 1:18
                        ori_num = size(predata.(label{i})(ori).Data,1);
                        if ori_num<minnum
                            minnum = ori_num;
                        end
                    end
                    time_point = size(predata.(label{i})(ori).Data,3);
                    data = zeros(18,minnum,length(channels),time_point,'single');
                    for ori = 1:18
                        data(ori,:,:,:) = predata.(label{i})(ori).Data(1:minnum,channels,:);
                    end

                    [acc1, p_value, perm_accuracies_mean,detailed_results,linear_weight] = SVM_Decoding_LR(data, 1, 5,5);
                    decoding_result.acc_all.(b{macaque_idx}){i,data_idx} = acc1;
                    decoding_result.p.(b{macaque_idx}){i,data_idx} = p_value;
                    decoding_result.shuffle.(b{macaque_idx}){i,data_idx} = perm_accuracies_mean;
                    decoding_result.details.(b{macaque_idx}){i,data_idx} = detailed_results;
                    decoding_result.linear.(b{macaque_idx}){i,data_idx} = linear_weight;
                end
            end
        end
        save(sprintf('D:/ensemble_coding/middata/decoding/Yge_data/decoding_result_Yge_all%s_Ygedata.mat',e{tren}),"decoding_result",'-v7.3');
    end
end
%% Decoding Plot
tren_labels = {'1.8';'2.1';'2.4';'40%';'60%';'80%'};
for tren = 1
    tren_label = tren_labels{tren};
    load(sprintf('D:/ensemble_coding/middata/decoding/Yge_data/decoding_result_Yge_all%s_Ygedata.mat',tren_label));
    figure('Position',[0,0,800,800]);
    b = {'DG','QQ_old','QQ_new'};
    c = {'LFP','MUA2'};
    for macaque_idx = 1:3
        for data_idx = 2
            mua_lfp = c{data_idx};
            % subplot(3,2,(macaque_idx-1)*2+data_idx);
            subplot(3,1,macaque_idx);
            hold on
            Colors = lines(4);
            for i = 1:4

                accuracy = cell2mat(decoding_result.details.(b{macaque_idx}){i,data_idx}.real_acc_dist)';
                Chance_Level = cell2mat(decoding_result.details.(b{macaque_idx}){i,data_idx}.perm_acc_dist)';
                [n_timepoints,n_shuffle] = size(Chance_Level);

                % 绘制Accuracy()
                plot(1:n_timepoints,mean(accuracy,2),'LineWidth',1.5,'Color',Colors(i,:));
                plot(1:n_timepoints,mean(Chance_Level,2),'LineWidth',1.5,'Color',[0.5,0.5,0.5]);

                % 绘制标准误
                accuracy_mean = mean(accuracy,2)';
                accuracy_std = std(accuracy,0,2)';
                x = 1:n_timepoints;
                fill([x fliplr(x)], [accuracy_mean+accuracy_std fliplr(accuracy_mean-accuracy_std)],...
                    Colors(i,:), 'EdgeColor', 'none', 'FaceAlpha', 0.3);


                chance_mean = mean(Chance_Level,2)';
                chance_std = std(Chance_Level,0,2)';
                fill([x fliplr(x)], [chance_mean+chance_std fliplr(chance_mean-chance_std)],...
                    [0.5,0.5,0.5], 'EdgeColor', 'none', 'FaceAlpha', 0.1);

                p_value = decoding_result.p.(b{macaque_idx}){i,data_idx};

                % 绘制显著点
                m = find(p_value<=0.005);
                y_marker_pos = 1/18-0.01*i;
                stem(m, repmat(y_marker_pos, size(m)), '.', 'MarkerFaceColor', 'k', ...
                    'MarkerSize', 5, 'LineWidth', 1, 'Clipping', 'off','LineStyle','none','MarkerEdgeColor',Colors(i,:));

            end
            subtitle(sprintf('%s %s',b{macaque_idx},c{data_idx}));

            ax = gca;
            ax.LineWidth = 2;
            ax.FontSize = 12;
            ax.FontWeight = 'bold';
            ax.XAxis.FontSize = 12;
            ax.YAxis.FontSize = 12;
            ax.XAxis.FontWeight = 'bold';

            xticks(0:10:100);
            xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160'});
        end
    end
    sgtitle(sprintf('Event Decoding%s',tren_label))
    saveas(gcf, sprintf('Event Decoding%s.png',tren_label), 'png');
    close all
end

%% 汇总
tren_labels = {'1.8';'2.1';'2.4';'40%';'60%';'80%'};
macaque = {'DG','QQ_old','QQ_new'};
labels = {'MGv','MGnv','SG','centerSSGnv'};
accuracy= [];
p_value = [];
for tren = 1:6
    disp(tren)
    tren_label = tren_labels{tren};
    result = load(sprintf('D:/ensemble_coding/middata/decoding/LR_data/decoding_result_Yge_all%s.mat',tren_label));
    for mac = 1:3
        for i = 1:4
            label = labels{i};
            accuracy(tren,mac,i,:) = result.decoding_result.acc_all.(macaque{mac}){i,2};
            p_value(tren,mac,i,:) = result.decoding_result.p.(macaque{mac}){i,2};
        end
    end
end
%% 评估正确率幅值
% 假设你的数据已经加载到工作区
% acc: (6 x N_macaque x N_label x N_time)
% p_value: (6 x N_macaque x N_label x N_time)
macaques = {'DG','QQ old','QQ new'};
labels = {'MGv','MGnv','SG','centerSSGnv'};
% ------------------------- 示例数据生成 -------------------------
% 实际使用时请注释掉这部分，使用你的真实数据
N_tren = 6;
N_macaque = 3;
N_label = 4;
N_time = 126;


time_points = 1:N_time;

% ------------------------- 颜色定义 -------------------------

% 定义两种主要的颜色（R, G, B 格式，范围 0 到 1）
COLOR1 = [0.1, 0.4, 0.8]; % 深蓝色
COLOR2 = [0.8, 0.1, 0.1]; % 红色

% 创建六个颜色：前三个是COLOR1的不同变化，后三个是COLOR2的不同变化

% 使用 'brightness' 或 'intensity' 的变化来模拟“透明度”
% MATLAB 的 line plot 不直接支持 alpha/透明度作为 CData 变量，
% 但可以通过改变颜色亮度来达到相似的视觉效果。

% 亮度因子（用于调整颜色）: 1 (亮) 到 0.5 (暗)
brightness_factors = [1.0, 0.75, 0.5];

% 初始化颜色矩阵 (6 x 3)
custom_colors = zeros(N_tren, 3);

% 第一组颜色 (tren 1-3)
for i = 1:3
    % 调整亮度 (使用 HSB 转换可以更精确，但直接缩放RGB也常用)
    % 简单方法：将颜色和白色混合
    factor = brightness_factors(i);
    custom_colors(i, :) = factor * COLOR1 + (1 - factor) * [1, 1, 1];
    % 确保颜色值在 [0, 1] 范围内
    custom_colors(i, :) = min(max(custom_colors(i, :), 0), 1);
end

% 第二组颜色 (tren 4-6)
for i = 1:3
    factor = brightness_factors(i);
    custom_colors(i+3, :) = factor * COLOR2 + (1 - factor) * [1, 1, 1];
    custom_colors(i+3, :) = min(max(custom_colors(i+3, :), 0), 1);
end

% ------------------------- 可视化 -------------------------

% 定义图布局: (N_macaque 行, N_label 列)
figure('Position', [100, 100, 1200, 800]);

for m = 1:N_macaque % 行数：macaque
    for l = 1:N_label % 列数：label
        
        % 计算子图索引
        subplot(N_macaque, N_label, (m-1) * N_label + l);
        
        hold on;
        
        % 遍历 tren (6个颜色)
        for t = 1:N_tren
            
            % 提取当前 tren, macaque, label 的时间序列数据
            current_acc_data = squeeze(accuracy(t, m, l, :));
            
            % 获取对应的颜色
            line_color = custom_colors(t, :);
            
            % 绘制线图
            plot(time_points, current_acc_data, ...
                 'Color', line_color, ...
                 'LineWidth', 1.5);
             
            % 示例：如果需要标记显著性 (p_value < 0.05)
            % significant_times = time_points(squeeze(p_value(t, m, l, :)) < 0.05);
            % scatter(significant_times, current_acc_data(significant_times), 10, ...
            %         line_color, 'filled');
        end
        
        hold off;
        
        % 设置子图标题和轴标签
        title(sprintf('%s, %s', macaques{m}, labels{l}), 'FontSize', 8);
        
        % 仅在最左列设置Y轴标签
        if l == 1
            ylabel('ACC Value');
        else
            set(gca, 'YTickLabel', []); % 隐藏非首列的Y轴刻度标签
        end
        
        % 仅在最底行设置X轴标签
        if m == N_macaque
            xlabel('Time Points');
        else
            set(gca, 'XTickLabel', []); % 隐藏非底行的X轴刻度标签
        end
        
        % 调整轴范围
        % 根据数据的整体范围调整 YLim，以便于比较
        Y_min = min(accuracy(:)) - 0.05;
        Y_max = max(accuracy(:)) + 0.05;
        ylim([Y_min, Y_max]);
    end
end

% 整体调整图表布局
sgtitle('ACC 结果矩阵的可视化 (Tren颜色变化)', 'FontSize', 14, 'FontWeight', 'bold');

% 添加图例 (可选，但推荐)
% 选取一个子图作为图例的参考
% h = subplot(N_macaque, N_label, 1);
% tren_names = arrayfun(@(i) sprintf('Tren %d', i), 1:N_tren, 'UniformOutput', false);
% legend(h.Children, tren_names, 'Location', 'bestoutside', 'Orientation', 'vertical', 'FontSize', 8);


%% 评估latency
% ------------------------- 1. 数据提炼 -------------------------
N_tren = 6;
N_macaque = 3;
N_label = 4;
labels = {'MGv','MGnv','SG','centerSSGnv'};
macaque = {'DG','QQ old','QQ new'};

% 初始化矩阵来存储最早显著时间点 (First Significant Time Index)
% 维度: (N_tren, N_macaque, N_label)
FST = zeros(N_tren, N_macaque, N_label);

% 显著性阈值
P_THRESHOLD = 0.001; 

for t = 1:N_tren
    for m = 1:N_macaque
        for l = 1:N_label
            
            % 提取当前 p_value 时间序列
            current_p_series = squeeze(p_value(t, m, l, 33:end));
            
            % 找到所有小于阈值的时间点的索引
            significant_indices = find(current_p_series < P_THRESHOLD, 1, 'first');
            
            if isempty(significant_indices)
                % 如果没有时间点小于阈值，则设定一个最大值或 NaN
                % 假设 N_time 是时间点总数，我们使用 N_time + 1 表示未达到显著
                N_time = size(p_value, 4);
                FST(t, m, l) = N_time + 1; 
            else
                % 记录第一个显著的时间索引
                FST(t, m, l) = significant_indices;
            end
        end
    end
end
FST = (FST+13)*2;

% ------------------------- 2. 绘图设置 -------------------------

tren_labels = {'1.8';'2.1';'2.4';'40%';'60%';'80%'};

figure('Position', [100, 100, 1000, 700]);
sgtitle(sprintf('最早显著解码时间点 (P < %.3f)', P_THRESHOLD), 'FontSize', 16);

% 为 Macaque 定义颜色 (3种颜色)
mac_colors = [
    0.0, 0.4, 0.8;  % 蓝色 (DG)
    0.8, 0.4, 0.0;  % 橙色 (QQ_old)
    0.2, 0.6, 0.2   % 绿色 (QQ_new)
];

% 定义 X 轴的刻度位置 (1, 2, 3, 4)
x_ticks = 1:N_label; 

for t = 1:N_tren % 遍历 tren (子图)
    
    subplot(2, 3, t); % 2行, 3列的布局
    hold on;
    
    % 遍历 macaque (绘制3条线)
    for m = 1:N_macaque
        
        % 提取当前 tren 和 macaque 的 4个 label 的 FST 数据
        data_to_plot = squeeze(FST(t, m, :)); 
        
        % 绘制线图和标记点
        plot(x_ticks, data_to_plot, ...
             'Color', mac_colors(m, :), ...
             'LineWidth', 2, ...
             'Marker', 'o', ...
             'MarkerSize', 6, ...
             'DisplayName', macaque{m});
    end
    
    hold off;
    
    % 设置轴和标题
    title(sprintf('Tren: %s', tren_labels{t}));
    
    % 设置 X 轴刻度和标签
    xticks(x_ticks);
    xticklabels(labels);
    
    % 统一 Y 轴范围
    max_time = max(FST(:));
    ylim([0, max_time + 5]); % 稍微留出一点空间
    
    % 添加 Y 轴标签
    if mod(t, 3) == 1 % 仅在左侧子图添加 YLabe
        ylabel('最早显著时间点 (Time Index)');
    end
    
    % 添加图例 (只在第一个子图添加，避免重复)
    if t == 1
        legend('Location', 'northwest');
    end
    
    grid on;
end
%% Pattern1 test Pattern其他
load('D:\ensemble_coding\middata\Yge_data\SCECEC0SSC_Dataset3-FigureMap.mat')
EC1 = FigureOriMap.EC(:,1:3:324,:,:);
for ori = 1:18
    idx = (1:6)+(ori-1)*6;
    data(ori,:,:,:,:) = EC1(:,idx,:,:);
end
channels = sel_channel.DG;
for ori = 1:18
    data0 = squeeze(data(ori,:,:,:,channels));
    data0 = permute(data0,[2,1,4,3]);
    [acc1{ori}, p_value{ori}, perm_accuracies_mean{ori},detailed_results{ori},linear_weight{ori}] = SVM_Decoding_LR(data0, 1, 5,5);
end
%%
clearvars -except data
channels = 1:96;
for pattern = 1:6
    traindata = squeeze(data(:,:,pattern,:,:));
    testData = reshape(data(:,:,setdiff(1:6,pattern),:,:),[18,4*5,126,96]);
    [~, accuracies_test{pattern}] = generalizationDecoding(permute(traindata,[1,2,4,3]), permute(testData,[1,2,4,3]), 'temporal');
    [~, accuracies_cv_train{pattern}] = generalizationDecoding(permute(traindata,[1,2,4,3]), permute(traindata,[1,2,4,3]), 'temporal');
end
acc = cat(1,accuracies_test{:});
acc_self = cat(1,accuracies_cv_train{:});
figure('Position',[0,0,800,300]);
hold on
plot(smooth(squmean(acc,1)),'LineWidth',2);
plot(smooth(squmean(acc_self,1)),'LineWidth',2);


%%
clear;
clc;

load('D:\ensemble_coding\middata\SNR\sel_channel_Yge.mat','sel_channel')
% load('D:\ensemble_coding\middata\Yge_data\SCECEC0SSC_Dataset3-FigureMap.mat')

options.mode = 'cross_gat';
options.do_permutation = false;
options.n_shuffles = 5;
options.n_repetitions = 1;
options.k_fold = 3;
options.time_smooth_win = 0;


EC1 = FigureOriMap.EC(:,1:3:324,:,:);
for ori = 1:18
    idx = (1:6)+(ori-1)*6;
    data(ori,:,:,:,:) = EC1(:,idx,:,:);
end
channels = sel_channel.DG;
data0 = reshape(data,[18,24,126,96]);
data0 = permute(data0(:,:,:,channels),[1,2,4,3]);
clearvars -except data0 options 
results = Master_Decoder(data0, [], options);