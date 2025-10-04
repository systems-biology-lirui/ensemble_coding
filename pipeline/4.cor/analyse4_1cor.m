%% -------------------------相似性表征-----------------------------%%
% readme（用于不同条件的时间信号的相似性表征计算）

%% ---------------------Exp2（Event）的相似性矩阵------------------------%%
% 这里的条件有MGv，MGnv，SG，SSGnv
% 数据导入
clc;
clear;
% QQnew
% load('D:\Ensemble coding\QQdata\Processed_Event\QQ_EVENT_Days39_40_MUA2_MGv.mat');
% load('D:\Ensemble coding\QQdata\Processed_Event\QQ_EVENT_Days39_40_MUA2_MGnv.mat');
% load('D:\Ensemble coding\QQdata\Processed_Event\QQ_EVENT_Days39_40_MUA2_SG.mat');
% load('D:\Ensemble coding\QQdata\Processed_Event\QQ_EVENT_Days39_40_MUA2_SSGnv.mat');
% QQold
% load('D:\Ensemble coding\QQdata\Processed_Event\QQ_EVENT_Days2_27_MUA2_MGv.mat');
% load('D:\Ensemble coding\QQdata\Processed_Event\QQ_EVENT_Days2_27_MUA2_MGnv.mat');
% load('D:\Ensemble coding\QQdata\Processed_Event\QQ_EVENT_Days2_27_MUA2_SG.mat');
% load('D:\Ensemble coding\QQdata\Processed_Event\QQ_EVENT_Days2_27_MUA2_SSGnv.mat');
% DG
load('D:\Ensemble coding\DGdata\Processed_Event\DG_EVENT_Days25_29_MUA2_MGv.mat');
load('D:\Ensemble coding\DGdata\Processed_Event\DG_EVENT_Days25_29_MUA2_MGnv.mat')
load('D:\Ensemble coding\DGdata\Processed_Event\DG_EVENT_Days25_29_MUA2_SG.mat')
load('D:\Ensemble coding\DGdata\Processed_Event\DG_EVENT_Days25_29_MUA2_SSGnv.mat')



% ---------------------- 相似性矩阵条件设置----------------------%
% MGv,MGnv,SG,SSGnv-center,SSGnv-fit,SSGnv-sum
n_condition = 108;
correlationData = zeros(n_condition,96,100);
% QQ_old
% coilselect=[7,9,13,17,18,19,21,22,23,24,25,27,35,38,39,41,51,61,73,74,80,82,84,87,89]+1;
% QQ_new
coilselect= [75,79,43,78,81,41,45,82,84,38,47,49,85,42,44,51,88,17,50,46,89,8,54,52,58,91,92,23,25,21,62,60,14,16,20,27,29,31,63,56,22,24,26,28];
% DG
% coilselect = [63,18,31,26,21,32,20,28,60,94,59,29,52,96,22,64,61,95,24,30,62,16,25,27,93,23,12,91,57,58];
win = 1;            %窗口平均长度

% ------------------------数据矩阵构建--------------------------%
for ori = 1:18   
    correlationData(ori,:,:) = smoothdata(squmean(MGv(ori).Data,1),2);            % EC
    correlationData(ori+18,:,:) = smoothdata(squmean(MGnv(ori).Data,1),2);        % EC0
    correlationData(ori+36,:,:) = smoothdata(squmean(SG(ori).Data,1),2);         % SC
    correlationData(ori+54,:,:) = smoothdata(squmean(SSGnv(ori+216).Data,1),2);   % Patch_center
end
% for ori = 1:18    
%     correlationData(ori,:,:) = squmean(MGv(ori).Data,1);            % EC
%     correlationData(ori+18,:,:) = squmean(MGnv(ori).Data,1);        % EC0
%     correlationData(ori+36,:,:) = squmean(SG(ori).Data,1);         % SC
%     correlationData(ori+54,:,:) = squmean(SSGnv(ori+216).Data,1);   % Patch_center
% end
SSGnvdata = zeros(12*18,96,100);
for i = 1:234
    SSGnvdata(i,:,:) = squmean(SSGnv(i).Data,1);
end

% -----------------------------滤波50hz,100hz----------------------------%
% frequency = [50,100];
% for m = 1:2
%     [b,a] = notch_filter(500, frequency(m), 10);
%     for i = 1:72
%         for channel = 1:96
%             correlationData(i,channel,:)  = filtfilt(b,a,squeeze(correlationData(i,channel,:)));
%         end
%     end
%     for i = 1:234
%         for channel = 1:96
%             SSGnvdata(i,channel,:)  = filtfilt(b,a,squeeze(SSGnvdata(i,channel,:)));
%         end
%     end
% end

% -----------------------------SSGnv的拟合-----------------------------%
R = {};
W = {};
fitting_data = {};
% method           - (可选) 指定计算方法的字符串:
    % 'linear_unconstrained' (默认) - 标准多元线性回归，包含截距项，
    % 'linear_constrained'   - 线性回归，但对权重施加约束：
    % 'sum'                  - 直接将所有预测信号相加，不进行任何拟合。
    % 'scaled_sum'           - 先将所有预测信号相加，然后对这个“和信号”进行增益(gain)和偏移(offset)的线性拟合。
factor = 'linear_unconstrained';
patch_num = 12;

for ori = 1:18
    MGv1 = squeeze(correlationData(ori+18,:,1:100));
    idx = ori:18:(patch_num*18);
    SSGv1 = permute(SSGnvdata(idx,:,1:100),[2,3,1]);
    [R{ori,1},W{ori,1},fitting_data{ori,1}] = trial_fitting(MGv1,SSGv1(:,:,1:patch_num),factor,[21,75]);
end

% ----------------------------SSGnv的加合--------------------------%
for ori = 1:18
    correlationData(ori+72,:,:) = cat(2,fitting_data{ori,:});
    for location = 1:patch_num
        dd = squmean(SSGnv(ori+(location-1)*18).Data,1);
        correlationData(ori+90,:,:) = correlationData(ori+90,:,:) + reshape(dd,[1,96,100]);         % Patch_sum
    end
end


% ---------------预处理（减基线，取非负，zscore）----------------%
correlationData = correlationData - mean(correlationData(:,:,1:20),3);
correlationData(correlationData<0) = 0;
% for t = 1:100
%     for condition = 1:108
%         correlationData(condition,:,t) = zscore(squeeze(correlationData(condition,:,t)));
%     end
% end

%% -----------------------相似性矩阵----------------------------%
correlationData = correlationData(:,coilselect,:);
num_repeats = size(correlationData, 1);
num_coils = size(correlationData, 2);
num_time_points = size(correlationData, 3);
timeidx = 1:win:(num_time_points-1);
p_value_matrix = zeros(num_repeats, num_repeats, length(timeidx));
similarity_matrix = zeros(num_repeats, num_repeats, length(timeidx));
for t = 1:(length(timeidx)-1)
    tt = timeidx(t);
    current_time_data = squeeze(mean(correlationData(:, :, tt:tt+win),3));

    [correlation_matrix,p_values] = corr(current_time_data');

    similarity_matrix(:, :, t) = correlation_matrix;
    p_value_matrix(:, :, t) = p_values;
end

%% ---------------------------------绘图---------------------------%
for t = timeidx
    MGnv_fitting_cor(t) = mean(diag(squeeze(similarity_matrix(19:36,73:90,t))));
    MGv_MGnv_cor(t) = mean(diag(squeeze(similarity_matrix(1:18,19:36,t))));
end
% for t = timeidx
%     MGnv_fitting_cor(t) = mean(squeeze(similarity_matrix(19:36,73:90,t)),[1,2]);
%     MGv_MGnv_cor(t) = mean(squeeze(similarity_matrix(1:18,19:36,t)),[1,2]);
% end
figure;
plot(MGnv_fitting_cor,'LineWidth',2);
hold on
plot(MGv_MGnv_cor,'LineWidth',2,'Color',[0.2,0.2,0.2],'LineStyle','-.')
xticks(10:10:100);
xticklabels({'-20','0','20','40','60','80','100','120','140','160'});
legend({'MGnv&fitting12','MGv&MGnv'});
xlim([1,100])
box off
xline(38,'--');
text(39, 0.1, '36ms', 'FontSize', 14);
xline(48,'--');
text(49, 0.2, '56ms', 'FontSize', 14);
box off

% figure;
% plot(MGv_MGnv_cor-MGnv_fitting_cor,'LineWidth',2)
% x_vertices = [20, 40, 40, 20];
% y_vertices = [-0.2, -0.2, 0.25, 0.25];
% 
% % 创建多边形
% p = patch('XData', x_vertices, 'YData', y_vertices, 'FaceColor', [0.5 0.5 0.5]);
% set(p, 'FaceAlpha', 0.4); % 设置 40% 的不透明度
% set(p, 'EdgeColor', 'none'); % 设置无边框
% xticks(10:10:100);
% xticklabels({'-20','0','20','40','60','80','100','120','140','160'});
% xline(38,'--');
% text(38, 0.1, '36ms', 'FontSize', 14);
%%
conditions_time = [5,23];
matrix1 = [];
timeidx = 1:win:(num_time_points-1);
for t = 1:(length(timeidx)-1)
    tt = timeidx(t);
    matrix1(:,:,t) = squeeze(mean(correlationData(conditions_time, :, tt:tt+win),3));
end
matrix1 = reshape(permute(matrix1,[3,1,2]),[length(conditions_time)*49,60]);
correlation_matrix1 = corr(matrix1');

%%
RDM = 1 - correlation_matrix1;
n_conditions = length(conditions_time);
n_times = 49;
num_items = n_conditions * n_times; % 1764
% 检查RDM的维度
disp('RDM 维度:');
disp(size(RDM));
% 预期输出:
% RDM 维度:
%   1764  1764

% 可视化RDM
figure;
imagesc(RDM);
colormap('jet');
colorbar;
axis square;
title('Representational Dissimilarity Matrix (RDM)');
xlabel('条件 x 时间点');
ylabel('条件 x 时间点');

% 如果需要，可以创建更精细的坐标轴标签来标识出条件和时间的边界
% 例如，每隔 36 (n_conditions) 个刻度画一条线
xticks(0.5:n_conditions:num_items+0.5);
yticks(0.5:n_conditions:num_items+0.5);
xticklabels(1:n_times);
yticklabels(1:n_times);
xlabel('时间点');
ylabel('时间点');
grid on;
set(gca, 'GridLineStyle', '-', 'GridColor', 'w', 'GridAlpha', 0.5);
%% --- 1. 准备工作：确保已有变量 ---
% --- 1. 准备工作：确保已有变量 ---
% 假设这些变量已在您的工作区中
% RDM: 1764x1764 的相异度矩阵 (1-correlation)
% n_conditions = 36;
% n_times = 49;
% num_items = n_conditions * n_times; % 1764

% --- 2. 执行MDS到3D空间 ---
% 将 mdscale 的第二个参数从 2 改为 3
% Y 现在是一个 [num_items, 3] 的矩阵，每一行是对应项目在3D空间中的 [x, y, z] 坐标
disp('正在执行MDS到3D空间...');
[Y, stress] = mdscale(RDM, 3); % <--- 主要改动在这里：2 -> 3
fprintf('MDS完成，Stress值: %f\n', stress);

% --- 3. 提取特定条件的轨迹坐标 ---
% 这部分代码与2D版本完全相同
% 条件1的索引
idx_cond1 = 1:n_conditions:num_items;
% 条件2的索引
idx_cond2 = 19:n_conditions:num_items;

% 从MDS结果Y中提取这两个条件的3D坐标
% 每个 coords_cond* 矩阵都是 [n_times, 3] 的，即 49x3
coords_cond1 = Y(idx_cond1, :);
coords_cond2 = Y(idx_cond2, :);

idx = 1:20;
% --- 4. 绘制3D轨迹图 ---
disp('正在绘制3D轨迹图...');
figure('Position', [100, 100, 900, 800]); % 窗口可以大一些
hold on;

% 绘制条件1的轨迹 (使用 plot3)
plot3(coords_cond1(idx,1), coords_cond1(idx,2), coords_cond1(idx,3), ...
      '--', ...
      'LineWidth', 2, ...
      'MarkerSize', 5, ...
      'DisplayName', 'Condition 1 Trajectory');

% 绘制条件2的轨迹 (使用 plot3)
plot3(coords_cond2(idx,1), coords_cond2(idx,2), coords_cond2(idx,3), ...
      '--', ...
      'LineWidth', 2, ...
      'MarkerSize', 5, ...
      'DisplayName', 'Condition 2 Trajectory');

% --- 5. 美化与增强信息 (3D版本) ---
% 使用颜色渐变来表示时间流逝
time_vector = 1:n_times; % 创建一个时间向量用于着色

% 为条件1的散点上色 (使用 scatter3)
% scatter3(coords_cond1(:,1), coords_cond1(:,2), coords_cond1(:,3), ...
%          50, time_vector, 'filled', 'MarkerEdgeColor', 'k');

scatter3(coords_cond1(1,1), coords_cond1(1,2), coords_cond1(1,3), ...
         50, 'filled', 'MarkerEdgeColor', 'k');
scatter3(coords_cond2(1,1), coords_cond2(1,2), coords_cond2(1,3), ...
         50, 'filled', 'MarkerEdgeColor', 'k');

% % 为条件2的散点上色 (使用 scatter3)
% scatter3(coords_cond2(:,1), coords_cond2(:,2), coords_cond2(:,3), ...
%          50, time_vector, 'filled', 'Marker', 's', 'MarkerEdgeColor', 'k');

% 标记起点和终点
% 起点 (T=1)
% plot3(coords_cond1(idx,1), coords_cond1(idx,2), coords_cond1(idx,3), 'p', 'MarkerSize', 15, 'MarkerFaceColor', 'g', 'DisplayName', 'Start Point');
% plot3(coords_cond2(idx,1), coords_cond2(idx,2), coords_cond2(idx,3), 'p', 'MarkerSize', 15, 'MarkerFaceColor', 'g', 'HandleVisibility', 'off');

% 终点 (T=49)
% plot3(coords_cond1(idx(end),1), coords_cond1(end,2), coords_cond1(end,3), 'h', 'MarkerSize', 15, 'MarkerFaceColor', 'r', 'DisplayName', 'End Point');
% plot3(coords_cond2(end,1), coords_cond2(end,2), coords_cond2(end,3), 'h', 'MarkerSize', 15, 'MarkerFaceColor', 'r', 'HandleVisibility', 'off');

% 添加图表元素
h_colorbar = colorbar;
ylabel(h_colorbar, 'Time Points');
% colormap('viridis');
xlabel('MDS Dimension 1');
ylabel('MDS Dimension 2');
zlabel('MDS Dimension 3'); % 添加Z轴标签
title('3D Neural Trajectories of Condition 1 vs Condition 2 in MDS Space');
legend('show', 'Location', 'best');
axis equal; % 保持坐标轴比例一致
grid on;
box on;
view(3); % 设置为三维视角，这是关键！
rotate3d on; % 允许用鼠标交互式旋转图形

hold off;