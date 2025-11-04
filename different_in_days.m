%% 不同天的采集差异效应可视化

% ------------------------------------SSVEP_b---------------------------------------%
% file_idx = {'D:\ensemble_coding\preplot\DG_SSVEPB_SG.mat',...
%     'D:\ensemble_coding\QQdata\Processed_Event\QQ_SSVEP_Days9_27_MUA2_SG.mat',...
%     'D:\ensemble_coding\QQdata\Processed_Event\QQ_SSVEPB_Days34_40_MUA2_SG.mat'};
% sessions_all = {{1:8,9:16,17:24,25:32,33:39,40:46,47:53,54:61},{1:16,17:32,33:49,50:66,67:90},{1:16,17:32,33:49,50:66,67:90}};

% ------------------------------------event---------------------------------------------%
file_idx = {'D:\ensemble_coding\DGdata\Processed_Event\DG_EVENT_Days25_29_MUA2_SG.mat',...
  'D:\ensemble_coding\QQdata\Processed_Event\QQ_EVENT_Days2_27_MUA2_SG.mat',...
  'D:\ensemble_coding\QQdata\Processed_Event\QQ_EVENT_Days39_42_MUA2_SG.mat'};
coils_all = {[63,18,24,96],[74,81,25,55],[74,81,25,55]};
sessions_all = {{1:28,29:56,57:84},{1:18,19:42,43:50},{1:32,33:51,52:85}};

for macaque = 1:3
    
    load(file_idx{macaque},'SG')
    data = permute(SG(1).Data,[2,1,3]);
    coils = coils_all{macaque};
    sessions = sessions_all{macaque};

    figure;

    for i = 1:length(coils)

        subplot(2,length(coils),i)
        current_coil = coils(i);
        current_data = squeeze(data(current_coil,:,:));
        current_data(current_data<0) = 0;
        imagesc(-current_data);
        subtitle(sprintf('coil%d',current_coil))
        colormap("gray")

        subplot(2,length(coils),i+length(coils))
        hold on
        for idx = 1:length(sessions)
            current_sessions = sessions{idx};
            plotdata = squmean(current_data(current_sessions,:),1)-squmean(current_data(current_sessions,1:20),[1,2]);
            plot(smooth(plotdata));
        end
        hold off

    end
end
%% 不同天的聚类情况
channel1 =[74,67,68,72,45,38,40,86,7,87,58,91,92,25,94,29,64,61,56,30];
% ---
data_A = squmean(SG(1).Data(1:85, channel1, 40:42),3);
data_B = squmean(SG(9).Data(1:85, channel1, 40:42),3); % 假设B也是85个trials

day_idx = {1:28,29:56,57:84};

% --- 2. 数据合并与处理 (你的代码) ---
all_data = [data_A; data_B];
all_data(all_data<0) = 0;
% all_data = sqrt(all_data);
labels_condition = [ones(size(data_A,1), 1); 2*ones(size(data_B,1), 1)];

all_data_zscored = zscore(all_data);

% --- 3. PCA (你的代码) ---
[coeff, score, latent, tsquared, explained] = pca(all_data_zscored);
data_2d = score(:, 1:2);

% --- 4. 优化后的可视化 ---
figure;
hold on;


colors = lines(3);      % 为3天定义3种颜色
markers = {'o', 'x'};   % 为2个条件定义2种形状 (o: A, x: B)
marker_size = 60;

% 定义图例句柄和名称，避免重复
legend_handles = [];
legend_names = {};

% 循环遍历每一天
for d = 1:3
    % 获取当天在 data_A 中的索引
    day_indices_A = day_idx{d};
    
    % 获取当天在 data_B 中的索引 (同样是 day_idx{d}，因为A和B的trials结构相同)
    day_indices_B = day_idx{d};
    
    % 从降维后的数据中找到对应的数据点
    points_A_day = data_2d(day_indices_A, :);
    points_B_day = data_2d(size(data_A,1) + day_indices_B, :); % 注意B的索引要加上A的数量
    
    % 绘制 A 条件的点 (实心圆 'o')
    hA = scatter(points_A_day(:, 1), points_A_day(:, 2), marker_size, colors(d,:), ...
                 'filled', 'Marker', markers{1});
                 
    % 绘制 B 条件的点 (叉号 'x')
    hB = scatter(points_B_day(:, 1), points_B_day(:, 2), marker_size, colors(d,:), ...
                 'LineWidth', 1.5, 'Marker', markers{2});
    
    % 在第一次循环时，为图例收集代表性的句柄
    if d == 1
        legend_handles = [hA, hB];
        legend_names = {'Condition A', 'Condition B'};
    end
end

% 添加一个看不见的散点图来为颜色创建图例
for d = 1:3
    h_day = scatter(NaN, NaN, marker_size, colors(d,:), 'filled');
    legend_handles = [legend_handles, h_day];
    legend_names = [legend_names, {['Day ' num2str(d)]}];
end


% 创建图例
legend(legend_handles, legend_names, 'Location', 'best');
xlabel(['Principal Component 1 (' num2str(explained(1), '%.1f') '%)']);
ylabel(['Principal Component 2 (' num2str(explained(2), '%.1f') '%)']);
title('PCA of Neural Data by Condition and Day');
axis tight;
hold off;
