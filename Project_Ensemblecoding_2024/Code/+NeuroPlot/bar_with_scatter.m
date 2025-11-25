function h = bar_with_scatter(ax, data_cell, group_names, varargin)
% BAR_WITH_SCATTER 绘制带散点和统计显著性标注的柱状图
%
% 用法:
%   NeuroPlot.bar_with_scatter(ax, {dataA, dataB}, {'A', 'B'}, ...
%       'ShowSigVs0', true, ...
%       'ComparePairs', [1 2]);
%
% 输入:
%   ax: 目标 Axes
%   data_cell: Cell 数组 {Vector1, Vector2, ...}
%   group_names: Cell 字符串数组
%
% 可选参数 (Name-Value):
%   'Colors': 颜色矩阵
%   'ShowSigVs0': (Logical) 是否显示与0的差异显著性 (默认 false)
%   'ComparePairs': [N x 2] 矩阵，每一行代表要比较的两组索引，如 [1 2; 2 3] (默认不比较)
%   'TestType': 'ttest' (默认参数检验) 或 'ranksum' (非参数检验)
%   'YLimExpand': (Scalar) 顶部留白比例，以便放星号 (默认 1.2)
%
% 输出:
%   h: 结构体，包含 bar, scatter, errorbar, sig_lines 等句柄

    % 1. 参数解析
    if isempty(ax), figure; ax = gca; end
    
    p = inputParser;
    addParameter(p, 'Colors', []);
    addParameter(p, 'ShowSigVs0', false); % 默认不显示 vs 0
    addParameter(p, 'ComparePairs', []);  % 默认不进行组间比较
    addParameter(p, 'TestType', 'ttest'); % ttest (vs 0) / ttest2 (between)
    addParameter(p, 'YLimExpand', 1.25);  % Y轴扩充比例
    
    parse(p, varargin{:});
    opts = p.Results;
    
    n_groups = length(data_cell);
    if isempty(opts.Colors)
        opts.Colors = lines(n_groups);
    end
    
    hold(ax, 'on');
    
    % 初始化句柄
    h.bar = gobjects(1, n_groups);
    h.scatter = gobjects(1, n_groups);
    h.errorbar = gobjects(1, n_groups);
    h.sig_vs0 = gobjects(1, n_groups);
    h.sig_between = [];
    
    % 用于记录绘图元素的最高点，以便安排星号位置
    max_heights = zeros(1, n_groups);
    all_data_points = [];
    
    % 2. 绘制 Bar, Scatter, ErrorBar
    for i = 1:n_groups
        this_data = data_cell{i};
        this_data = double(this_data(~isnan(this_data))); % 转 double 并去 NaN
        all_data_points = [all_data_points; this_data(:)];
        
        mu = mean(this_data);
        sem = std(this_data) / sqrt(length(this_data));
        
        % A. Bar
        h.bar(i) = bar(ax, i, mu, ...
            'FaceColor', opts.Colors(i,:), ...
            'FaceAlpha', 0.6, 'EdgeColor', 'none', 'BarWidth', 0.6);
        
        % B. Scatter (Jitter)
        jitter = (rand(size(this_data)) - 0.5) * 0.25;
        h.scatter(i) = scatter(ax, i + jitter, this_data, 15, ...
            'MarkerFaceColor', opts.Colors(i,:) * 0.8, ...
            'MarkerEdgeColor', 'w', 'LineWidth', 0.5);
            
        % C. Error Bar
        h.errorbar(i) = errorbar(ax, i, mu, sem, ...
            'k', 'LineWidth', 1.5, 'CapSize', 10, 'LineStyle', 'none');
        
        % 记录当前组最高点 (Bar顶 或 ErrorBar顶)
        max_heights(i) = max(mu + sem, max(this_data)); % 这里的策略：星号要躲开所有数据点
        if mu < 0, max_heights(i) = max(0, max(this_data)); end % 负值情况处理
    end
    
    % 计算 Y 轴范围基准
    y_max_limit = max(all_data_points) * 1.05;
    if y_max_limit <= 0, y_max_limit = 1; end % 防止全负数出错
    
    % 3. 统计显著性：每组 vs 0
    if opts.ShowSigVs0
        for i = 1:n_groups
            this_data = double(data_cell{i});
            this_data = this_data(~isnan(this_data));
            
            % 统计检验
            if strcmpi(opts.TestType, 'ranksum')
                p_val = signrank(this_data); % Wilcoxon signed rank test for vs 0
            else
                [~, p_val] = ttest(this_data); % One-sample t-test
            end
            
            % 获取星号文本
            txt = get_star_text(p_val);
            
            if ~isempty(txt)
                % 绘制在当前最高点上方一点
                y_pos = max_heights(i) + 0.05 * range(all_data_points); 
                h.sig_vs0(i) = text(ax, i, y_pos, txt, ...
                    'HorizontalAlignment', 'center', ...
                    'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');
                
                % 更新高度记录，避免重叠
                max_heights(i) = y_pos;
            end
        end
    end
    
    % 4. 统计显著性：组间比较 (Between Groups)
    if ~isempty(opts.ComparePairs)
        pairs = opts.ComparePairs;
        n_pairs = size(pairs, 1);
        
        % 定义层级高度步长
        step_height = 0.1 * range(all_data_points);
        if step_height == 0, step_height = 1; end
        
        current_top = max(max_heights);
        
        for k = 1:n_pairs
            g1 = pairs(k, 1);
            g2 = pairs(k, 2);
            
            d1 = double(data_cell{g1}); d1 = d1(~isnan(d1));
            d2 = double(data_cell{g2}); d2 = d2(~isnan(d2));
            
            % 统计检验
            if strcmpi(opts.TestType, 'ranksum')
                p_val = ranksum(d1, d2);
            else
                [~, p_val] = ttest2(d1, d2); % Unpaired t-test
            end
            
            % 只有显著才画线 (或者把 ns 也画出来，这里默认全画)
            txt = get_star_text(p_val); 
            
            % 提升绘制高度
            current_top = current_top + step_height;
            
            % 绘制横线和下折线
            line_x = [g1, g1, g2, g2];
            line_y = [current_top-step_height*0.2, current_top, current_top, current_top-step_height*0.2];
            
            h_line = plot(ax, line_x, line_y, '-k', 'LineWidth', 1);
            h_txt = text(ax, mean([g1, g2]), current_top + step_height*0.1, txt, ...
                'HorizontalAlignment', 'center', 'FontSize', 12);
            
            h.sig_between = [h.sig_between; h_line, h_txt];
        end
        
        % 更新最终 Y Limit
        y_max_limit = current_top + step_height;
    else
        y_max_limit = max(max_heights);
    end
    
    % 5. 调整坐标轴
    set(ax, 'XTick', 1:n_groups, 'XTickLabel', group_names);
    set(ax, 'XLim', [0.5, n_groups + 0.5]);
    
    % 自动调整 Y 轴上限，留出位置给星号
    ylim(ax, [min(0, min(all_data_points)*1.1), y_max_limit * opts.YLimExpand]);
    
    box(ax, 'off');
end

% 内部辅助函数：P值转星号
function txt = get_star_text(p)
    if p < 0.001
        txt = '***';
    elseif p < 0.01
        txt = '**';
    elseif p < 0.05
        txt = '*';
    else
        txt = 'n.s.'; % 或者返回 '' 不显示
    end
end