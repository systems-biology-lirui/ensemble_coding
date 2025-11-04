function ridgePlot(data, varargin)
% ridgePlot - 在MATLAB中创建山脊图 (Joy Plot)
%
% 语法:
%   ridgePlot(data)
%   ridgePlot(data, 'param1', value1, 'param2', value2, ...)
%
% 输入:
%   data - (N x M) 矩阵，N是样本数(trials)，M是类别/时间点数。
%          每一列的数据将被用来绘制一条山脊。
%
% 可选参数 (Parameter-Value pairs):
%   'labels'      - (1 x M) cell 数组或字符串数组，用于Y轴的标签。
%                   默认: 1, 2, 3, ...
%   'overlap'     - (0到1之间的数字) 控制山脊之间的重叠程度。
%                   0表示不重叠，1表示完全重叠。默认: 0.6
%   'scale'       - (正数) 控制每条山脊的高度。默认: 1.5
%   'colors'      - (M x 3) RGB矩阵或MATLAB颜色字符(如'b')，用于指定颜色。
%                   默认: 'b' (蓝色)
%   'faceAlpha'   - (0到1之间的数字) 控制填充区域的透明度。默认: 0.5
%   'edgeColor'   - 轮廓线的颜色。默认: 'k' (黑色)
%   'lineWidth'   - 轮廓线的宽度。默认: 1.5
%
% 示例:
%   mock_data = [randn(100,1), randn(100,1)+3, normrnd(0,2,[100,1])];
%   labels = {'Group A', 'Group B', 'Group C'};
%   figure;
%   ridgePlot(mock_data, 'labels', labels, 'overlap', 0.5, 'scale', 2);
%

% --- 解析输入参数 ---
p = inputParser;
addRequired(p, 'data', @(x) isnumeric(x) && ismatrix(x));
addParameter(p, 'labels', [], @(x) iscell(x) || isstring(x));
addParameter(p, 'overlap', 0.6, @(x) isnumeric(x) && x>=0 && x<=1);
addParameter(p, 'scale', 1.5, @(x) isnumeric(x) && x>0);
addParameter(p, 'colors', 'b', @(x) (isnumeric(x) && size(x,2)==3) || ischar(x) || isstring(x));
addParameter(p, 'faceAlpha', 0.5, @(x) isnumeric(x) && x>=0 && x<=1);
addParameter(p, 'edgeColor', 'k', @(x) (ischar(x) || isstring(x)) || (isnumeric(x) && numel(x)==3));
addParameter(p, 'lineWidth', 1.5, @(x) isnumeric(x) && x>0);

parse(p, data, varargin{:});

% 将解析结果存入变量
labels = p.Results.labels;
overlap = p.Results.overlap;
scale = p.Results.scale;
colors = p.Results.colors;
faceAlpha = p.Results.faceAlpha;
edgeColor = p.Results.edgeColor;
lineWidth = p.Results.lineWidth;

[~, M] = size(data);

% 如果未提供标签，则使用数字
if isempty(labels)
    labels = string(1:M);
end

% 处理颜色输入
if ischar(colors) || isstring(colors)
    colors = repmat(colors, M, 1);
end
if size(colors, 1) == 1 && M > 1
    colors = repmat(colors, M, 1);
end

% --- 开始绘图 ---
hold on;
y_spacing = 1 - overlap; % Y轴上每条线的间距

for i = 1:M
    % 提取当前列的数据
    current_data = data(:, i);
    
    % 使用 ksdensity 进行核密度估计
    [f, xi] = ksdensity(current_data);
    
    % 标准化密度曲线的高度，使其最大值为1
    if max(f) > 0
        f = f / max(f);
    end
    
    % 计算当前山脊的Y轴偏移量
    y_offset = (i-1) * y_spacing;
    
    % 创建用于填充的坐标
    x_fill = [xi, fliplr(xi)];
    y_fill = [f * scale + y_offset, ones(1, length(f)) * y_offset];
    
    % 绘制填充区域
    fill(x_fill, y_fill, colors(i,:), ...
         'FaceAlpha', faceAlpha, ...
         'EdgeColor', 'none');
     
    % 绘制轮廓线 (为了美观，只画上半部分)
    plot(xi, f * scale + y_offset, ...
         'Color', edgeColor, ...
         'LineWidth', lineWidth);
end

% --- 美化坐标轴 ---
ax = gca;
ax.YTick = (0:M-1) * y_spacing;
ax.YTickLabel = labels;
ax.YLim = [-y_spacing/2, (M-1)*y_spacing + scale*1.2];
ax.Box = 'off';
ax.XGrid = 'on';
ax.YDir = 'reverse'; % 经典的山脊图Y轴是反向的
hold off;

end