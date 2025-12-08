function plot_decoding_timecourse(ax, data_matrix, chance_level, baseline_idx)
% PLOT_DECODING_CURVE 绘制Decoding准确率曲线、误差阴影、显著性标记及半峰值点
%
% 输入参数:
%   ax:           绘图的坐标轴句柄 (例如 gca 或 subplot 的返回值)
%   data_matrix:  5 x 121 的矩阵 (Repeat x Time)
%   chance_level: 对比值 (Chance level，例如 0.5 或 1/6)
%   baseline_idx: 基线校正的时间点索引 (例如 1:10)，如果为空则不进行基线校正

    %% 1. 数据预处理
    [n_repeat, n_time] = size(data_matrix);
    
    % --- 基线校正 (Baseline Alignment) ---
    % 将基线部分的平均值对齐到 chance_level
    if ~isempty(baseline_idx)
        % 计算当前的全局基线均值
        current_baseline_mean = mean(data_matrix(:, baseline_idx), 'all');
        % 计算偏移量
        offset = chance_level - current_baseline_mean;
        % 应用偏移
        data_matrix = data_matrix + offset;
    end
    
    % --- 平滑处理 (Smoothing) ---
    % 对每个 repeat (行) 在时间维度上进行平滑
    % 使用移动平均或高斯平滑，这里使用窗口为5的高斯平滑
    data_smooth = smoothdata(data_matrix, 2, 'gaussian', 5);
    
    %% 2. 统计计算 (Permutation Test)
    % 针对每个时间点，计算是否显著大于 chance_level
    p_values = ones(1, n_time);
    
    % 由于 N=5 非常小，我们可以使用 Exact Permutation Test (全排列)
    % 总组合数 = 2^5 = 32 种符号翻转情况
    n_perms = 2^n_repeat; 
    
    for t = 1:n_time
        % 当前时间点的数据 (减去 chance level 用于符号翻转测试)
        obs_data = data_smooth(:, t) - chance_level;
        obs_mean = mean(obs_data);
        
        % 生成所有可能的符号翻转 (0 到 31 的二进制表示)
        perm_means = zeros(n_perms, 1);
        for i = 0:(n_perms-1)
            % 生成符号向量 (-1 或 1)
            signs = bitget(i, 1:n_repeat) * 2 - 1; 
            % 计算翻转后的均值
            perm_means(i+1) = mean(obs_data .* signs');
        end
        
        % 计算单尾 p 值 (有多少次随机翻转的均值 >= 观察到的均值)
        p_values(t) = sum(perm_means >= obs_mean) / n_perms;
    end
    
    %% 3. 寻找半峰值点 (Latency calculation)
    % 计算平均曲线
    mean_curve = mean(data_smooth, 1);
    
    % 找到最大峰值及其位置
    [peak_val, peak_idx] = max(mean_curve);
    
    % 计算目标高度 (峰值和 chance 的中间值)
    half_height_val = (peak_val + chance_level) / 2;
    
    % 在峰值之前寻找最接近半高值的点
    % 只搜索峰值左侧的数据
    if peak_idx > 1
        pre_peak_data = mean_curve(1:peak_idx);
        % 寻找交叉点 (差值绝对值最小的点)
        [~, min_idx] = min(abs(pre_peak_data - half_height_val));
        half_peak_idx = min_idx;
        half_peak_val = mean_curve(half_peak_idx);
    else
        half_peak_idx = peak_idx;
        half_peak_val = peak_val;
    end

    %% 4. 绘图 (Visualization)
    
    % 准备 X 轴 (假设是 1 到 121，也可以改为具体时间 ms)
    x = 1:n_time;
    
    % 激活目标坐标轴
    axes(ax); hold on;
    
    % --- A. 绘制 Chance Level 虚线 ---
    yline(chance_level, '--k', 'LineWidth', 1.2, 'Alpha', 0.6);
    
    % --- B. 绘制误差阴影 (SEM) ---
    sem_curve = std(data_smooth, 0, 1) / sqrt(n_repeat); % 标准误
    curve_upper = mean_curve + sem_curve;
    curve_lower = mean_curve - sem_curve;
    
    % 使用 fill 绘制半透明阴影
    fill_color = [0.85, 0.33, 0.1]; % 橙红色风格
    x_fill = [x, fliplr(x)];
    y_fill = [curve_upper, fliplr(curve_lower)];
    fill(x_fill, y_fill, fill_color, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    
    % --- C. 绘制平均线 ---
    plot(x, mean_curve, 'Color', fill_color, 'LineWidth', 2);
    
    % --- D. 标注显著性 (p < 0.05) ---
    % 找出显著的点
    sig_indices = find(p_values < 0.05);
    if ~isempty(sig_indices)
        % 在 chance level 下方一点的位置绘制
        sig_y_pos = chance_level - (max(mean_curve) - min(mean_curve)) * 0.05; 
        scatter(x(sig_indices), repmat(sig_y_pos, size(sig_indices)), ...
            15, fill_color, 'filled', 's'); % 方块标记
        
        % 可选：添加文字说明
        text(x(1), sig_y_pos, ' p<0.05', 'FontSize', 8, 'Color', fill_color, ...
             'VerticalAlignment', 'middle');
    end
    
    % --- E. 标注半峰值点 ---
    plot(half_peak_idx, half_peak_val, 'o', ...
        'MarkerSize', 8, ...
        'MarkerEdgeColor', 'b', ...
        'MarkerFaceColor', 'b');
    
    % 添加垂直虚线连接到X轴或Chance (可选，这里画一条线指示时间)
    line([half_peak_idx, half_peak_idx], [chance_level, half_peak_val], ...
        'Color', 'b', 'LineStyle', ':', 'LineWidth', 1.5);
    
    % 标注文字
    text(half_peak_idx, half_peak_val, sprintf(' Onset\n t=%d', half_peak_idx), ...
        'Color', 'b', 'FontSize', 9, 'VerticalAlignment', 'bottom');

    % --- 图像美化 ---
    xlabel('Time (points)');
    % ylabel('Decoding Accuracy');
    % title('Decoding Time Course');
    box off;
    xlim([1, n_time]);
    
    hold off;
end