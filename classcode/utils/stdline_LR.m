function varargout = stdline_LR(data, varargin)
% plotMeanTimeSeries - 绘制带误差阴影的时间序列平均线
%
% 语法:
%   plotMeanTimeSeries(data)
%   plotMeanTimeSeries(data, 'x', xVector)
%   plotMeanTimeSeries(data, 'errorType', 'sd')
%   h = plotMeanTimeSeries(...)
%
% 描述:
%   该函数用于可视化随时间变化的平均数据及其不确定性。
%
%   如果输入 'data' 是一个 2D 矩阵 (m*n):
%   - m 被视为重复次数/试验次数 (trials)。
%   - n 被视为时间序列的长度 (time points)。
%   - 函数将绘制一条平均线 (n个时间点的均值) 和一个表示误差的阴影区域。
%
%   如果输入 'data' 是一个 3D 矩阵 (m*n*k):
%   - k 被视为不同的条件/组 (conditions)。
%   - 函数将为每个条件绘制一条不同颜色的平均线和对应的误差阴影。
%
% 输入参数:
%   data - 必需，数值矩阵 (m*n 或 m*n*k)。
%
% 可选参数 (键值对):
%   'x'            - x轴的向量 (长度必须为n)。默认: 1:n。
%   'errorType'    - 误差类型: 'sem' (标准误, 默认) 或 'sd' (标准差)。
%   'color'        - 线的颜色。对于3D数据，可以是一个 k*3 的RGB矩阵。
%                    默认: MATLAB的默认颜色循环。
%   'alpha'        - 阴影区域的透明度 (0到1)。默认: 0.2。
%   'lineWidth'    - 平均线的线宽。默认: 2。
%   'legendLabels' - 图例标签，一个包含k个字符串的cell数组。
%                    默认: {'Condition 1', 'Condition 2', ...}。
%
% 输出参数 (可选):
%   h - 图像中绘制的平均线的句柄数组。
%
% 示例:
%   % 示例 1: 2D 矩阵
%   m = 50; n = 100;
%   time = linspace(0, 4*pi, n);
%   noise = randn(m, n) * 0.3;
%   signal = sin(time);
%   data_2d = repmat(signal, m, 1) + noise;
%   figure;
%   plotMeanTimeSeries(data_2d, 'x', time);
%   title('2D 矩阵示例'); xlabel('时间'); ylabel('值');
%
%   % 示例 2: 3D 矩阵
%   k = 3;
%   data_3d = zeros(m, n, k);
%   for i = 1:k
%       phase_shift = (i-1)*pi/2;
%       signal = sin(time + phase_shift);
%       noise = randn(m, n) * 0.3;
%       data_3d(:, :, i) = repmat(signal, m, 1) + noise;
%   end
%   figure;
%   plotMeanTimeSeries(data_3d, 'x', time, 'legendLabels', {'C1', 'C2', 'C3'});
%   title('3D 矩阵示例'); xlabel('时间'); ylabel('值');

    % --- 输入解析 ---
    p = inputParser;
    addRequired(p, 'data', @(x) isnumeric(x) && ndims(x) >= 2 && ndims(x) <= 3);
    
    % 获取数据维度
    [m, n, k] = size(data);
    
    % 可选参数默认值
    defaultX = 1:n;
    defaultErrorType = 'sem';
    defaultColor = get(groot, 'defaultAxesColorOrder');
    defaultAlpha = 0.2;
    defaultLineWidth = 2;
    defaultLegend = arrayfun(@(x) sprintf('Condition %d', x), 1:k, 'UniformOutput', false);

    addParameter(p, 'x', defaultX, @(x) isvector(x) && length(x) == n);
    addParameter(p, 'errorType', defaultErrorType, @(x) ismember(x, {'sem', 'sd'}));
    addParameter(p, 'color', defaultColor, @(x) isnumeric(x) && (size(x, 2) == 3 || isvector(x)));
    addParameter(p, 'alpha', defaultAlpha, @(x) isscalar(x) && x >= 0 && x <= 1);
    addParameter(p, 'lineWidth', defaultLineWidth, @isscalar);
    addParameter(p, 'legendLabels', defaultLegend, @iscellstr);
    
    parse(p, data, varargin{:});
    
    % 将解析结果赋给变量
    x = p.Results.x(:)'; % 确保是行向量
    errType = p.Results.errorType;
    colors = p.Results.color;
    alpha = p.Results.alpha;
    lineWidth = p.Results.lineWidth;
    legendLabels = p.Results.legendLabels;

    % --- 核心逻辑 ---
    
    % 准备绘图
    hold on;
    h = gobjects(1, k); % 预分配句柄数组
    
    for i = 1:k
        % 提取当前条件的数据
        current_data = data(:, :, i);
        
        % 计算均值
        mean_line = mean(current_data, 1);
        
        % 计算误差
        if strcmp(errType, 'sem')
            % 标准误 (Standard Error of the Mean)
            err_bound = std(current_data, 0, 1) / sqrt(m);
        else % 'sd'
            % 标准差 (Standard Deviation)
            err_bound = std(current_data, 0, 1);
        end
        
        % 获取当前颜色
        color_idx = mod(i-1, size(colors, 1)) + 1;
        current_color = colors(color_idx, :);
        
        % 绘制阴影区域
        % fill 函数需要一个闭合多边形的坐标
        x_fill = [x, fliplr(x)];
        y_fill = [mean_line - err_bound, fliplr(mean_line + err_bound)];
        
        % 使用 fill 绘制阴影，并设置透明度和无边框
        fill(x_fill, y_fill, current_color, 'FaceAlpha', alpha, 'EdgeColor', 'none');
        
        % 绘制平均线
        h(i) = plot(x, mean_line, 'Color', current_color, 'LineWidth', lineWidth);
    end
    
    % --- 完善图像 ---
    
    % 添加图例（仅当有多个条件时）
    if k > 1 && ~isempty(legendLabels)
        legend(h, legendLabels, 'Location', 'best');
    end
    
    % 设置坐标轴
    box on;
    grid on;
    
    hold off;
    
    % 返回句柄（如果需要）
    if nargout > 0
        varargout{1} = h;
    end
end