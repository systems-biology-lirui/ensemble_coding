function plot_multicondition_decoding(ax, data_matrix, chance_level, baseline_idx, condition_names)
% PLOT_MULTICONDITION_DECODING 绘制多条件Decoding曲线、误差阴影、显著性标记及半峰值点
%
% 输入参数:
%   ax:              绘图的坐标轴句柄
%   data_matrix:     5 x 121 x N_Cond 的矩阵 (Repeat x Time x Condition)
%   chance_level:    对比值 (例如 0.5)
%   baseline_idx:    基线校正的时间点索引 (例如 1:10)
%   condition_names: (可选) 一个包含字符串的Cell数组，例如 {'Cond A', 'Cond B', 'Cond C'}

    [n_repeat, n_time, n_cond] = size(data_matrix);
    
    % 如果没有提供条件名称，自动生成
    if nargin < 5 || isempty(condition_names)
        condition_names = arrayfun(@(x) sprintf('Cond %d', x), 1:n_cond, 'UniformOutput', false);
    end

    % 激活坐标轴
    axes(ax); hold on;
    
    % 设置颜色映射 (使用 MATLAB 默认的 lines 配色，或者你可以自定义 hex 颜色)
    colors = lines(n_cond); 
    
    % 准备 X 轴
    x = 1:n_time;
    
    % --- 0. 先绘制 Chance Level 虚线 (在最底层) ---
    yline(chance_level, '--k', 'Chance', 'LineWidth', 1.2, 'Alpha', 0.5, 'LabelHorizontalAlignment', 'left');

    % 用于存储图例句柄
    h_plots = gobjects(1, n_cond);
    
    % 获取Y轴大致范围用于确定显著性标记的位置
    % 为了简单起见，先预估一个偏移量步长
    % 在循环中我们会动态更新 y_lim，但这里先设定一个初始步长
    sig_marker_step = 0.01; 
    
    %% --- 循环处理每个条件 ---
    for c = 1:n_cond
        
        % 提取当前条件的数据 (5 x 121)
        current_data = data_matrix(:, :, c);
        this_color = colors(c, :);
        
        %% 1. 基线校正 (Baseline Alignment)
        if ~isempty(baseline_idx)
            current_baseline_mean = mean(current_data(:, baseline_idx), 'all');
            offset = chance_level - current_baseline_mean;
            current_data = current_data + offset;
        end
        
        %% 2. 平滑处理 (Smoothing)
        data_smooth = smoothdata(current_data, 2, 'gaussian', 5);
        
        %% 3. 统计计算 (Permutation Test)
        p_values = ones(1, n_time);
        n_perms = 2^n_repeat; % 32
        
        for t = 1:n_time
            obs_data = data_smooth(:, t) - chance_level;
            obs_mean = mean(obs_data);
            
            perm_means = zeros(n_perms, 1);
            for i = 0:(n_perms-1)
                signs = bitget(i, 1:n_repeat) * 2 - 1; 
                perm_means(i+1) = mean(obs_data .* signs');
            end
            p_values(t) = sum(perm_means >= obs_mean) / n_perms;
        end
        
        %% 4. 寻找半峰值点 (Latency)
        mean_curve = mean(data_smooth, 1);
        [peak_val, peak_idx] = max(mean_curve);
        half_height_val = (peak_val + chance_level) / 2;
        
        if peak_idx > 1
            pre_peak_data = mean_curve(1:peak_idx);
            [~, min_idx] = min(abs(pre_peak_data - half_height_val));
            half_peak_idx = min_idx;
            half_peak_val = mean_curve(half_peak_idx);
        else
            half_peak_idx = peak_idx;
            half_peak_val = peak_val;
        end
        
        %% 5. 绘图 (Visualization)
        
        % A. 绘制误差阴影 (SEM)
        sem_curve = std(data_smooth, 0, 1) / sqrt(n_repeat);
        curve_upper = mean_curve + sem_curve;
        curve_lower = mean_curve - sem_curve;
        
        x_fill = [x, fliplr(x)];
        y_fill = [curve_upper, fliplr(curve_lower)];
        
        % FaceAlpha 设低一点，防止多层遮挡看不清
        fill(x_fill, y_fill, this_color, 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
        
        % B. 绘制平均线 (保存句柄用于图例)
        h_plots(c) = plot(x, mean_curve, 'Color', this_color, 'LineWidth', 2, 'DisplayName', condition_names{c});
        
        % C. 标注半峰值点 (实心圆点)
        plot(half_peak_idx, half_peak_val, 'o', ...
            'MarkerSize', 6, ...
            'MarkerEdgeColor', this_color, ...
            'MarkerFaceColor', this_color, ...
            'HandleVisibility', 'off');
        
        % (可选) 添加一根细的垂直线指向半峰值点，帮助看时间
        line([half_peak_idx, half_peak_idx], [chance_level, half_peak_val], ...
             'Color', this_color, 'LineStyle', ':', 'LineWidth', 1, 'HandleVisibility', 'off');
        
        % D. 标注显著性 (p < 0.05)
        % 策略：在 chance level 下方分层显示
        % 第1个条件在 chance - 1*step, 第2个在 chance - 2*step...
        sig_indices = find(p_values < 0.05);
        sig_indices(sig_indices<33) = [];
        if ~isempty(sig_indices)
            % 动态计算纵坐标位置
            y_pos_sig = chance_level - (c * sig_marker_step) - 0.02; 
            
            % 绘制显著性横线或点
            plot(x(sig_indices), repmat(y_pos_sig, size(sig_indices)), ...
                '.', 'Color', this_color, 'MarkerSize', 8, 'HandleVisibility', 'off');
            
            % 在该行最左侧标一个小小的提示 (可选)
            % text(1, y_pos_sig, '*', 'Color', this_color, 'FontSize', 14, 'HorizontalAlignment', 'right');
        end
        
    end
    
    %% --- 图像美化 ---
    xlabel('Time (points)');
    % ylabel('Decoding Accuracy');
    % title('Multi-Condition Decoding Time Course');
    % box on;
    % grid on;
    xlim([1, n_time]);
    
    % 添加图例
    % legend(h_plots, 'Location', 'best');
    
    hold off;
end