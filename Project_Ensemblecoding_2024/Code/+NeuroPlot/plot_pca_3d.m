function h_fig = plot_pca_3d(traj_data, varargin)
% PLOT_PCA_3D 绘制3D神经群体轨迹
% 
% 输入:
%   traj_data: [nCond, nTime, 3] 数据矩阵 (由 compute_pca_trajectory 输出)
% 
% 可选参数 (Name-Value):
%   'TimeVec'    : 时间向量 [1, nTime] (默认: 1:nTime)
%   'CondColors' : [nCond, 3] 颜色矩阵 (默认: 自动生成)
%   'CondLabels' : {nCond, 1} 条件标签 (默认: {'Cond 1', 'Cond 2', ...})
%   'Title'      : 图像标题 (默认: '3D Neural Trajectories')
%   'AxHandle'   : 目标绘图坐标轴 (默认: 新建图形)
%   'LineWidth'  : 线宽 (默认: 2)
%   'MarkStart'  : 是否标记起点 (默认: true)
%   'MarkEnd'    : 是否标记终点 (默认: true)
% 
% 输出:
%   h_fig        : 图形句柄 (或坐标轴句柄)

    % --- 参数解析 ---
    p = inputParser;
    addRequired(p, 'traj_data', @(x) isnumeric(x) && ndims(x) == 3 && size(x, 3) >= 3);
    addParameter(p, 'TimeVec', [], @isnumeric);
    addParameter(p, 'CondColors', [], @isnumeric);
    addParameter(p, 'CondLabels', {}, @iscell);
    addParameter(p, 'Title', '3D Neural Trajectories', @ischar);
    addParameter(p, 'AxHandle', [], @(x) isempty(x) || ishandle(x));
    addParameter(p, 'LineWidth', 2, @isnumeric);
    addParameter(p, 'MarkStart', true, @islogical);
    addParameter(p, 'MarkEnd', true, @islogical);
    
    parse(p, traj_data, varargin{:});
    
    % --- 变量提取 ---
    data = traj_data;
    [nCond, nTime, ~] = size(data);
    
    time_vec = p.Results.TimeVec;
    if isempty(time_vec)
        time_vec = 1:nTime;
    end
    
    colors = p.Results.CondColors;
    if isempty(colors)
        colors = lines(nCond);
    end
    
    labels = p.Results.CondLabels;
    if isempty(labels)
        labels = arrayfun(@(x) sprintf('Cond %d', x), 1:nCond, 'UniformOutput', false);
    end
    
    ax = p.Results.AxHandle;
    if isempty(ax)
        h_fig = figure('Color', 'w');
        ax = gca;
    else
        h_fig = ax;
        axes(ax); % Make current
    end
    
    hold(ax, 'on');
    
    % --- 绘图循环 ---
    for c = 1:nCond
        % 提取当前条件的 PC1, PC2, PC3
        x = data(c, :, 1);
        y = data(c, :, 2);
        z = data(c, :, 3);
        
        % 绘制轨迹
        plot3(ax, x, y, z, 'Color', colors(c, :), 'LineWidth', p.Results.LineWidth, ...
            'DisplayName', labels{c});
        
        % 标记起点 (Circle)
        if p.Results.MarkStart
            plot3(ax, x(1), y(1), z(1), 'o', 'MarkerSize', 8, ...
                'MarkerFaceColor', colors(c, :), 'MarkerEdgeColor', 'k', ...
                'HandleVisibility', 'off');
        end
        
        % 标记终点 (Square)
        if p.Results.MarkEnd
            plot3(ax, x(end), y(end), z(end), 's', 'MarkerSize', 8, ...
                'MarkerFaceColor', colors(c, :), 'MarkerEdgeColor', 'k', ...
                'HandleVisibility', 'off');
        end
    end
    
    % --- 装饰 ---
    xlabel(ax, 'PC 1');
    ylabel(ax, 'PC 2');
    zlabel(ax, 'PC 3');
    title(ax, p.Results.Title);
    grid(ax, 'on');
    legend(ax, 'Location', 'best');
    axis(ax, 'vis3d'); % 更好的3D视角
    view(ax, 3);       % 默认3D视角
    
    hold(ax, 'off');
    
    % 简单的美化
    set(ax, 'FontSize', 12, 'LineWidth', 1.2);
end
