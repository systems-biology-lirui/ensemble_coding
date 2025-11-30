function handles = plot_decoding_timecourse(acc_matrix, chance_matrix, p_matrix, time_points, varargin)
% PLOT_DECODING_TIMECOURSE 绘制跨时间解码正确率 (支持半峰值标记)
%
% 新增参数:
%   'MarkHalfPeak': (Logical) 是否标记半峰值点 (50% Onset Latency)。默认 false。
%                   计算逻辑：寻找 (Peak - Chance)/2 + Chance 的第一个时间点。
%
% 示例:
%   plot_decoding_timecourse(..., 'MarkHalfPeak', true);

    % --- 1. 参数解析 ---
    p = inputParser;
    addRequired(p, 'acc_matrix');
    addRequired(p, 'chance_matrix');
    addRequired(p, 'p_matrix');
    addRequired(p, 'time_points');
    addParameter(p, 'Alpha', 0.05);
    addParameter(p, 'Colors', lines(size(acc_matrix, 1))); 
    addParameter(p, 'Legend', {});
    addParameter(p, 'SmoothWin', 1);
    addParameter(p, 'Parent', []); 
    addParameter(p, 'MarkHalfPeak', false); % 新增开关
    
    parse(p, acc_matrix, chance_matrix, p_matrix, time_points, varargin{:});
    
    alpha_thresh = p.Results.Alpha;
    colors = p.Results.Colors;
    legend_names = p.Results.Legend;
    smooth_win = p.Results.SmoothWin;
    parent_ax = p.Results.Parent;
    mark_half_peak = p.Results.MarkHalfPeak;
    
    [n_cond, ~, n_time] = size(acc_matrix);

    % --- 2. 确定绘图目标 Axes ---
    if isempty(parent_ax)
        handles.ax = gca;
    else
        handles.ax = parent_ax;
    end
    handles.fig = get(handles.ax, 'Parent');

    hold(handles.ax, 'on'); 
    grid(handles.ax, 'on');
    
    % 初始化句柄
    handles.lines         = gobjects(n_cond, 1);
    handles.patches       = gobjects(n_cond, 1);
    handles.scatters      = gobjects(n_cond, 1); 
    handles.half_markers  = gobjects(n_cond, 1); % 存储半峰值标记

    % --- 3. 绘制 Chance Level ---
    mean_chance = squeeze(mean(chance_matrix, 1));
    std_chance  = squeeze(std(chance_matrix, 0, 1));
    
    % 计算一个全局的标量 Chance 值，用于半峰值计算 (取平均比较稳健)
    scalar_chance_level = mean(mean_chance);
    
    if smooth_win > 1
        mean_chance = smoothdata(mean_chance, 'gaussian', smooth_win);
        std_chance  = smoothdata(std_chance, 'gaussian', smooth_win);
    end
    
    upper_chance = mean_chance + std_chance;
    lower_chance = mean_chance - std_chance;
    
    handles.chance_patch = fill(handles.ax, [time_points, fliplr(time_points)], ...
                                [upper_chance, fliplr(lower_chance)], ...
                                [0.5 0.5 0.5], 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
                                'DisplayName', 'Chance Std');
    
    handles.chance_line = plot(handles.ax, time_points, mean_chance, '--', ...
                               'Color', [0.3 0.3 0.3], 'LineWidth', 1.5, ...
                               'DisplayName', 'Chance Level');

    % --- 4. 绘制 Condition ---
    for c = 1:n_cond
        current_data = squeeze(acc_matrix(c, :, :));
        mu = mean(current_data, 1);
        sigma = std(current_data, 0, 1);
        
        if smooth_win > 1
            mu = smoothdata(mu, 'gaussian', smooth_win);
            sigma = smoothdata(sigma, 'gaussian', smooth_win);
        end
        
        upper = mu + sigma;
        lower = mu - sigma;
        col = colors(c, :);
        
        % A. 误差阴影
        handles.patches(c) = fill(handles.ax, [time_points, fliplr(time_points)], ...
                                  [upper, fliplr(lower)], ...
                                  col, 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
                                  'HandleVisibility', 'off');
         
        % B. 均值线
        disp_name = sprintf('Cond %d', c);
        if ~isempty(legend_names) && c <= length(legend_names)
            disp_name = legend_names{c};
        end
        
        handles.lines(c) = plot(handles.ax, time_points, mu, '-', 'Color', col, ...
                                'LineWidth', 2, 'DisplayName', disp_name);
        
        % C. 显著性点
        sig_idx = find(p_matrix(c, :) < alpha_thresh);
        if ~isempty(sig_idx)
            handles.scatters(c) = scatter(handles.ax, time_points(sig_idx), mu(sig_idx), ...
                                          30, col, 'filled', ...
                                          'HandleVisibility', 'off', 'MarkerEdgeColor', 'none'); 
        end
        
        % D. 半峰值标记 (New Feature)
        if mark_half_peak
            % 1. 找到峰值和位置
            [peak_val, peak_idx] = max(mu);
            
            % 2. 计算阈值: (峰值 + Chance) / 2
            %    这是最符合 Decoding 上下文的定义
            half_thresh = (peak_val + scalar_chance_level) / 2;
            
            % 3. 在 1 到 peak_idx 之间寻找第一个超过阈值的点
            %    mu(1:peak_idx) 截取峰值前的数据
            search_region = mu(1:peak_idx);
            
            % find(..., 1, 'first') 返回第一个索引
            idx_onset = find(search_region >= half_thresh, 1, 'first');
            
            if ~isempty(idx_onset)
                % 绘制标记 (例如：空心圆圈 + 十字)
                handles.half_markers(c) = plot(handles.ax, time_points(idx_onset), mu(idx_onset), ...
                    'o', 'MarkerSize', 8, 'LineWidth', 2, 'Color', col, ...
                    'MarkerFaceColor', 'w', 'HandleVisibility', 'off'); % 不进图例
                
                % (可选) 也可以画一条竖线指示时间
                % xline(handles.ax, time_points(idx_onset), ':', 'Color', col, 'HandleVisibility', 'off');
            end
        end
    end
    
    % --- 5. 设置标签与图例 ---
    xlabel(handles.ax, 'Time (ms)');
    ylabel(handles.ax, 'Decoding Accuracy');
    title(handles.ax, 'Time-Resolved Decoding Accuracy');
    xlim(handles.ax, [min(time_points), max(time_points)]);
    
    if ~isempty(legend_names)
        legend(handles.ax, handles.lines, legend_names, 'Location', 'best');
    end
end