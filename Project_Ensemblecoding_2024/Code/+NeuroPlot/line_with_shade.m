function h = line_with_shade(ax, x, data_matrix, varargin)
% LINE_WITH_SHADE 绘制高可定制的带误差阴影线图
%
% 用法:
%   h = line_with_shade(ax, x, data, 'Color', 'r', 'ErrorType', 'std');
%   h = line_with_shade(ax, x, data, 'LineWidth', 2, 'LineStyle', '--', 'Alpha', 0.2);
%
% 输入:
%   ax: Axes 句柄 (可选，若为 [] 则使用 gca)
%   x: [1 x T] 时间/频率轴
%   data_matrix: [Observations x T] 数据矩阵
%
% 可选参数 (Name-Value):
%   --- 统计控制 ---
%   'ErrorType': 'sem' (默认), 'std', 'ci95' (95%置信区间)
%
%   --- 颜色与外观 ---
%   'Color': 主色调 (默认 MATLAB 蓝色)。阴影会自动使用此颜色。
%   'Alpha': 阴影透明度 (默认 0.3)
%   'ShadeColor': (可选) 强制指定阴影颜色，不随 Line 颜色变化
%
%   --- 标准 Plot 参数 ---
%   支持所有 plot() 的参数: 'LineWidth', 'LineStyle', 'Marker', 'MarkerSize', etc.
%
% 输出:
%   h: 结构体，包含句柄
%      h.line  (中间均值线)
%      h.patch (阴影区域)
%      h.mu    (计算出的均值向量)
%      h.err   (计算出的误差向量)

    % 1. 初始化与参数解析
    if isempty(ax), figure; ax = gca; end
    
    % 创建解析器
    p = inputParser;
    p.KeepUnmatched = true; % 允许传入 plot 的标准参数 (如 LineWidth)
    
    % 定义自定义参数默认值
    addParameter(p, 'ErrorType', 'sem', @(x) any(validatestring(x, {'std','sem','ci95'})));
    addParameter(p, 'Color', [0 0.4470 0.7410]); % 默认蓝
    addParameter(p, 'Alpha', 0.3);
    addParameter(p, 'ShadeColor', []); % 默认跟随主色
    
    parse(p, varargin{:});
    
    % 提取自定义参数
    params = p.Results;
    % 提取 Plot 参数 (将结构体转为 Name-Value Cell 用于传递给 plot)
    plot_params = namedargs2cell(p.Unmatched); 
    
    % 2. 数据统计计算
    % 确保数据是 double 类型以避免 int16 溢出
    data_matrix = double(data_matrix);
    
    mu = mean(data_matrix, 1, 'omitnan');
    N = sum(~isnan(data_matrix), 1);
    sd = std(data_matrix, 0, 1, 'omitnan');
    
    switch lower(params.ErrorType)
        case 'sem'
            err = sd ./ sqrt(N);
        case 'std'
            err = sd;
        case 'ci95'
            % t-inverse roughly 1.96 for large N, but calculated precisely here
            % 简单的 1.96 * SEM 近似，或者用 tinv
            err = 1.96 * (sd ./ sqrt(N)); 
    end
    
    % 确保向量方向一致
    x = x(:)'; mu = mu(:)'; err = err(:)';
    
    % 3. 准备绘图数据
    upper_curve = mu + err;
    lower_curve = mu - err;
    
    % 构造 Patch 坐标 (闭合多边形)
    x_patch = [x, fliplr(x)];
    y_patch = [upper_curve, fliplr(lower_curve)];
    
    % 处理 NaN (Patch 不能有 NaN)
    valid_mask = ~isnan(y_patch);
    x_patch = x_patch(valid_mask);
    y_patch = y_patch(valid_mask);
    
    % 确定颜色
    line_color = params.Color;
    if isempty(params.ShadeColor)
        shade_color = line_color;
    else
        shade_color = params.ShadeColor;
    end
    
    % 4. 执行绘图
    hold(ax, 'on');
    
    % A. 绘制阴影 (先画，这样线会在上面)
    h.patch = fill(ax, x_patch, y_patch, shade_color, ...
        'FaceAlpha', params.Alpha, ...
        'EdgeColor', 'none', ...
        'HandleVisibility', 'off'); % 这样 legend 就不显示方块了
    
    % B. 绘制均值线 (合并用户传入的 LineWidth 等参数)
    % 强制把 Color 加进去，但允许用户通过 varargin 覆盖
    h.line = plot(ax, x, mu, '-', ...
        'Color', line_color, ...
        plot_params{:}); 
    
    % 5. 保存计算结果 (可选，便于后续检查)
    h.mu = mu;
    h.err = err;
    
    grid(ax, 'on');
    box(ax, 'off');
end

% 辅助函数：兼容旧版 MATLAB 的 struct 转 cell
function c = namedargs2cell(s)
    fields = fieldnames(s);
    values = struct2cell(s);
    c = [fields(:)'; values(:)'];
    c = c(:)';
end