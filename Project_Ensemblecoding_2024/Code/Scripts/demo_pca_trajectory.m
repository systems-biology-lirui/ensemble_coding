%% Demo_PCA_Trajectory.m
% 这是一个演示脚本，展示如何使用 NeuroAlgo 和 NeuroPlot 包中的函数
% 进行神经群体轨迹的计算 (PCA) 和可视化 (2D/3D)。

clc; clear; close all;

%% 1. 生成模拟数据
% 假设我们有 2 个条件 (Condition)，64 个通道 (Channel)，每个 Trial 500 个时间点
nCond = 2;
nCh = 64;
nTime = 500;
time_vec = linspace(-200, 800, nTime); % 模拟时间轴 -200ms 到 800ms

% 生成一些具有时间结构的随机数据
% Cond 1: 正弦波模式
% Cond 2: 余弦波模式


%% 2. 计算 PCA 轨迹
% 使用 NeuroAlgo.compute_pca_trajectory
% 参数: 平滑窗口=20, 保留3个主成分
time_vec =1:121;
data_matrix = reshape(squmean(Mat_MGv_A_EVENT,3),[18*6,100,121]); 
fprintf('正在计算 PCA 轨迹...\n');
channels = [74,75,43,76,39,84,83,81,8,17,19,62,31,64,63,95,32,26];
[traj_data, explained, extra] = NeuroAlgo.compute_pca_trajectory(data_matrix(:,channels,:), ...
    'SmoothWin', 10, ...
    'NumComponents', 3, ...
    'SmoothMethod', 'gaussian');

fprintf('PCA 计算完成。\n');
fprintf('解释方差 (前3个成分): %.2f%%, %.2f%%, %.2f%%\n', explained(1), explained(2), explained(3));
fprintf('输出轨迹维度: [%d, %d, %d]\n', size(traj_data));

%% 3. 绘制 2D 轨迹 (PC1 vs PC2)
fprintf('绘制 2D 轨迹...\n');
% figure('Name', 'PCA 2D Demo', 'Color', 'w');
NeuroPlot.plot_pca_2d(traj_data([1,9],:,:), ...
    'TimeVec', time_vec, ...
    'CondLabels', {'Condition A (Sin)', 'Condition B (Cos)'}, ...
    'Title', 'Neural Population Trajectory (2D)', ...
    'MarkStart', true, ...
    'MarkEnd', true);

%% 4. 绘制 3D 轨迹 (PC1 vs PC2 vs PC3)
fprintf('绘制 3D 轨迹...\n');
% figure('Name', 'PCA 3D Demo', 'Color', 'w');
NeuroPlot.plot_pca_3d(traj_data([1,9],:,:), ...
    'TimeVec', time_vec, ...
    'Title', 'Neural Population Trajectory (3D)', ...
    'MarkStart', true, ...
    'MarkEnd', true);

fprintf('演示完成。\n');
%%
dist_t = NeuroTool.calc_traj_distance(traj_data, 1, 9, '3d');
avg_dist_t1 = NeuroTool.calc_group_avg_distance(traj_data, [1,19,37],'3d');
avg_dist_t9 = NeuroTool.calc_group_avg_distance(traj_data, [9,27,45],'3d');
avg_dist_t = mean([avg_dist_t1,avg_dist_t9],2);
distance_matrix = [avg_dist_t,dist_t]';
NeuroPlot.plot_simple_decoding(gca, distance_matrix, 0, 1:20, 1:121)