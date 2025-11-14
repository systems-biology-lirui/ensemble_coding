function [results, handles] = analyzeAndPlotTrajectories(data_cell, cond_indices_to_compare, options)
% analyzeAndPlotTrajectories 对高维时间序列数据进行PCA降维并可视化
%
% [results, handles] = analyzeAndPlotTrajectories(data_cell, cond_indices_to_compare, options)
%
% 输入:
%   data_cell               - 1xN cell数组, N是条件数.
%                             每个cell {i} 是一个 T x F 的矩阵.
%   cond_indices_to_compare - M x 2 矩阵, M是要比较的条件对数量.
%                             每一行 [idx1, idx2] 指定要比较的一对条件.
%                             例如: [1, 2; 2, 3]
%   options                 - (可选) 包含绘图选项的结构体:
%     ... (其他选项同前)
%
% 输出:
%   results                 - 包含计算结果的结构体:
%     ...
%     .distance_over_time   - M x 1 cell数组, 每个cell是距离时间序列.
%     .angle_over_time      - M x 1 cell数组, 每个cell是向量夹角(度)的时间序列.
%   ...
%

%% --- 1. 参数处理和数据校验 ---
if nargin < 3, options = struct(); end

num_signals = numel(data_cell);
if ~iscell(data_cell) || num_signals == 0
    error('输入`data_cell`必须是一个非空的cell数组。');
end

[num_time_points, ~] = size(data_cell{1});

% 设置默认选项
if ~isfield(options, 'legend_labels')
    options.legend_labels = arrayfun(@(x) sprintf('Cond %d', x), 1:num_signals, 'UniformOutput', false);
end
if ~isfield(options, 'main_title')
    options.main_title = 'Neural Trajectory Analysis';
end

% *** MODIFICATION START: Handle M x 2 comparison matrix ***
if size(cond_indices_to_compare, 2) ~= 2 || any(cond_indices_to_compare(:) > num_signals)
    error('`cond_indices_to_compare`必须是包含有效索引的 M x 2 矩阵。');
end
num_comparisons = size(cond_indices_to_compare, 1);
% *** MODIFICATION END ***


%% --- 2. 核心计算 ---

% --- PCA (不变) ---
combined_data = cat(1, data_cell{:});
[~, score, ~, ~, explained] = pca(combined_data);
scores_separated = cell(1, num_signals);
for i = 1:num_signals
    start_idx = (i-1) * num_time_points + 1;
    end_idx = i * num_time_points;
    scores_separated{i} = score(start_idx:end_idx, :);
end

% *** MODIFICATION START: Loop through comparisons ***
distance_over_time = cell(num_comparisons, 1);
angle_over_time = cell(num_comparisons, 1); % <-- 变量名已更改
comparison_labels = cell(num_comparisons, 1);

for k = 1:num_comparisons
    idx1 = cond_indices_to_compare(k, 1);
    idx2 = cond_indices_to_compare(k, 2);
    
    % --- 距离计算 (不变) ---
    traj1_pca = scores_separated{idx1}(:, 1:3);
    traj2_pca = scores_separated{idx2}(:, 1:3);
    distance_over_time{k} = sqrt(sum((traj1_pca - traj2_pca).^2, 2));

    % --- 角度计算 ---
    vecs1_orig = data_cell{idx1};
    vecs2_orig = data_cell{idx2};
    
    dot_prods = sum(vecs1_orig .* vecs2_orig, 2);
    norms1 = vecnorm(vecs1_orig, 2, 2);
    norms2 = vecnorm(vecs2_orig, 2, 2);
    
    denominators = norms1 .* norms2;
    denominators(denominators == 0) = 1; % 防止除以零
    
    % 计算 cos(theta) 并处理数值精度问题
    cos_theta = dot_prods ./ denominators;
    cos_theta_clipped = min(1, max(-1, cos_theta)); % 裁剪到[-1, 1]区间以防 acosd 报错
    
    % 使用 acosd 直接计算角度（单位：度）
    angle_over_time{k} = acosd(cos_theta_clipped);
    
    % --- 生成标签用于图例 (不变) ---
    comparison_labels{k} = sprintf('%s vs %s', options.legend_labels{idx1}, options.legend_labels{idx2});
end
% *** MODIFICATION END ***

%% --- 3. 可视化 ---

if isfield(options, 'figure_handle') && ishandle(options.figure_handle)
    hFig = figure(options.figure_handle);
else
    hFig = figure('Position', [100, 100, 1600, 500], 'Color', 'w');
end

handles.figure = hFig;
handles.axes = gobjects(1, 3);

% --- 子图1: PCA三维轨迹图 (不变) ---
ax1 = subplot(1, 3, 1);
% ... (这部分代码与之前完全相同) ...
hold(ax1, 'on');
color_palette_pca = lines(num_signals);
line_handles_pca = gobjects(num_signals, 1);
for i = 1:num_signals
    pc1 = scores_separated{i}(:, 1); pc2 = scores_separated{i}(:, 2); pc3 = scores_separated{i}(:, 3);
    line_handles_pca(i) = plot3(ax1, pc1, pc2, pc3, 'LineWidth', 2, 'Color', [color_palette_pca(i,:), 0.8]);
    plot3(ax1, pc1(1), pc2(1), pc3(1), 'o', 'MarkerSize', 7, 'MarkerFaceColor', color_palette_pca(i,:), 'MarkerEdgeColor', 'k');
    plot3(ax1, pc1(end), pc2(end), pc3(end), 's', 'MarkerSize', 7, 'MarkerFaceColor', color_palette_pca(i,:), 'MarkerEdgeColor', 'k');
end
legend(ax1, line_handles_pca, options.legend_labels, 'Location', 'northeast', 'FontSize', 10, 'Box', 'off');
grid(ax1, 'on'); ax1.GridColor = [0.8 0.8 0.8]; ax1.GridAlpha = 0.5; ax1.BoxStyle = 'full';
title(ax1, 'State Trajectories in PCA Space', 'FontSize', 14);
xlabel(ax1, sprintf('PC1 (%.1f%%)', explained(1)), 'FontSize', 11);
ylabel(ax1, sprintf('PC2 (%.1f%%)', explained(2)), 'FontSize', 11);
zlabel(ax1, sprintf('PC3 (%.1f%%)', explained(3)), 'FontSize', 11);
view(ax1, 35, 25); axis(ax1, 'equal'); axis(ax1, 'tight'); rotate3d(ax1, 'on');
hold(ax1, 'off');
handles.axes(1) = ax1;


% *** MODIFICATION START: Plot multiple comparison lines ***

% --- 子图2: 距离-时间图 ---
ax2 = subplot(1, 3, 2);
hold(ax2, 'on');
color_palette_comp = lines(num_comparisons);
for k = 1:num_comparisons
    plot(ax2, 1:num_time_points, distance_over_time{k}, '-', 'LineWidth', 1.5, 'Color', color_palette_comp(k,:));
end
hold(ax2, 'off');
legend(ax2, comparison_labels, 'Location', 'best', 'Box', 'off');
grid(ax2, 'on');
ax2.Box = 'off'; ax2.GridColor = [0.9 0.9 0.9];
axis(ax2, 'tight');
title(ax2, 'Pairwise Distances', 'FontSize', 14);
xlabel(ax2, 'Time', 'FontSize', 11);
ylabel(ax2, 'Euclidean Distance (in PCA space)', 'FontSize', 11);
handles.axes(2) = ax2;

% --- 子图3: 角度-时间图 ---
ax3 = subplot(1, 3, 3);
hold(ax3, 'on');
color_palette_comp = lines(num_comparisons);
for k = 1:num_comparisons
    plot(ax3, 1:num_time_points, angle_over_time{k}, '-', 'LineWidth', 1.5, 'Color', color_palette_comp(k,:));
end
% 添加一条90度参考线
plot(ax3, get(ax3, 'XLim'), [90 90], '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
hold(ax3, 'off');
legend(ax3, [comparison_labels; {'Orthogonal'}], 'Location', 'best', 'Box', 'off'); % 添加参考线标签
grid(ax3, 'on');
ax3.Box = 'off'; ax3.GridColor = [0.9 0.9 0.9];
axis(ax3, 'tight');
ylim(ax3, [0, 180]); % 角度范围是 0 到 180 度
yticks(ax3, 0:30:180); % 设置刻度，使其更易读
title(ax3, 'Angle Between Vectors', 'FontSize', 14);
xlabel(ax3, 'Time', 'FontSize', 11);
ylabel(ax3, 'Angle (degrees)', 'FontSize', 11);
handles.axes(3) = ax3;
% ... (中间代码) ...
%% --- 4. 封装返回结果 ---
results.pca_scores = scores_separated;
results.explained_variance = explained;
results.distance_over_time = distance_over_time;
results.angle_over_time = angle_over_time; % <-- 变量名和字段名已更改
results.comparison_labels = comparison_labels;
end