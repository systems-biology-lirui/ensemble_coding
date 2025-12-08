function plot_simple_decoding(ax, data_matrix, chance_level, baseline_idx, time_vector)
% PLOT_3COND_ALIGNED_SMOOTH 
% 对 3x121 的矩阵进行基线对齐、平滑，绘制曲线并标记半峰值点。
%
% 输入参数:
%   ax:              绘图坐标轴句柄
%   data_matrix:     3 x 121 矩阵 (Condition x Time)
%   chance_level:    对比值 (例如 0.5，用于对齐基线和计算半峰高度)
%   baseline_idx:    基线时间点的索引 (例如 1:10)
%   time_vector:     (可选) 时间轴向量 (例如 -200:10:1000)，为空则用 1:121
%   condition_names: (可选) 条件名称 cell数组

    [n_cond, n_time] = size(data_matrix);

    % --- 参数默认值处理 ---
    if nargin < 5 || isempty(time_vector)
        time_vector = 1:n_time;
    end


    % 激活坐标轴
    axes(ax); hold on;
    
    % 配色方案
    colors = lines(n_cond); 
    
    % 1. 绘制 Chance Level 虚线 (最底层)
    yline(chance_level, '--k', 'Chance', 'LineWidth', 1.2, 'Alpha', 0.5, ...
        'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');

    % 存储线条句柄用于图例
    h_lines = gobjects(1, n_cond);
    
    %% --- 循环处理每个条件 ---
    for c = 1:n_cond
        
        % 原始曲线
        raw_curve = data_matrix(c, :);
        this_color = colors(c, :);
        
        %% A. 基线对齐 (Alignment)
        % 计算当前曲线在基线段的平均值
        if ~isempty(baseline_idx)
            current_base_mean = mean(raw_curve(baseline_idx));
            % 计算需要移动的偏移量
            offset = chance_level - current_base_mean;
            % 对整条曲线进行平移
            raw_curve = raw_curve + offset;
        end
        
        %% B. 平滑处理 (Smoothing)
        % 使用高斯平滑
        final_curve = smoothdata(raw_curve, 'gaussian', 5);
        
        %% C. 绘制曲线
        h_lines(c) = plot(time_vector, final_curve, 'Color', this_color, 'LineWidth', 2.5);
         
        %% D. 计算并标记半峰值点 (Half-Peak Latency)
        % 1. 找峰值
        [peak_val, peak_idx_local] = max(final_curve);
        
        % 2. 计算半高值 (Peak与Chance的中点)
        half_height_val = (peak_val + chance_level) / 2;
        
        % 3. 搜索峰值左侧最接近半高值的点
        if peak_idx_local > 1
            pre_peak_data = final_curve(1:peak_idx_local);
            [~, min_idx] = min(abs(pre_peak_data - half_height_val));
            half_peak_idx = min_idx;
        else
            half_peak_idx = peak_idx_local;
        end
        
        % 获取对应的物理坐标
        x_target = time_vector(half_peak_idx);
        y_target = final_curve(half_peak_idx);
        
        % 4. 绘制标记点
        plot(x_target, y_target, 'o', ...
            'MarkerSize', 8, ...
            'MarkerEdgeColor', this_color, ...
            'MarkerFaceColor', 'w', ... %以此区分，空心或白心看起来更清晰
            'LineWidth', 1.5, ...
            'HandleVisibility', 'off');
        
        % 5. 绘制垂直虚线 (帮助读数)
        line([x_target, x_target], [chance_level, y_target], ...
            'Color', this_color, 'LineStyle', ':', 'LineWidth', 1.5, ...
            'HandleVisibility', 'off');
    end
    
    %% --- 图像修饰 ---
    xlabel('Time');
    % ylabel('Decoding Accuracy (Aligned)');
    % title('Aligned & Smoothed Time Course');

    xlim([min(time_vector), max(time_vector)]);
    
    % 自动调整Y轴范围，让曲线不顶天立地
    axis tight; 
    yl = ylim;
    ylim([yl(1)-0.01, yl(2)+0.01]); % 上方多留点空间
    

    hold off;
end