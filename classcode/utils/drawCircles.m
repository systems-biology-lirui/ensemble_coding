function h = drawCircles(circleData, varargin)
% drawCircles - 根据指定的圆心和半径数据绘制多个圆，并添加标签 (v2, Corrected)
%
% 语法:
%   drawCircles(circleData)
%   drawCircles(circleData, 'Color', 'r', 'LineWidth', 2)
%   h = drawCircles(..., 'ShowLabels', false)
%
% 描述:
%   该函数接收一个 3xN 的矩阵来绘制 N 个圆。所有圆将共享
%   相同的样式 (颜色, 线宽等)，并在中心用数字标记。
%
% 输入参数:
%   circleData - 必需，一个 3xN 的数值矩阵。
%                - circleData(1, :) = x 坐标
%                - circleData(2, :) = y 坐标
%                - circleData(3, :) = 半径
%
% 可选参数 (键值对):
%   --- 绘图属性 (同时用于圆和标签) ---
%   'Color', 'LineStyle', 'LineWidth', ... (任何 'plot' 接受的参数)
%
%   --- 标签特定属性 ---
%   'ShowLabels'  - 是否显示数字标签 (true/false)。默认: true。
%   'FontSize'    - 标签的字体大小。默认: 10。
%   'FontWeight'  - 标签的字体粗细 ('normal', 'bold')。默认: 'bold'。
%
% 输出参数 (可选):
%   h - 一个结构体，包含图形句柄:
%       h.circles - 圆圈的 plot 句柄 (1xN)
%       h.labels  - 标签的 text 句柄 (1xN)
%
% 示例:
%   data_3xn = [1 5 8; 2 6 3; 1 1.5 0.8];
%   figure;
%   drawCircles(data_3xn, 'Color', 'm', 'LineWidth', 2, 'FontSize', 12, 'FontWeight', 'bold');
%   title('修正后: 所有圆圈颜色一致');

% --- 1. 输入解析 ---
% 分离出我们自己处理的参数和需要直接传递给 plot 的参数
% 默认值
params.ShowLabels = true;
params.FontSize = 10;
params.FontWeight = 'bold'; % 将 'bold' 设为默认，更显眼

% 检查 varargin 中是否有我们自定义的参数
args_to_pass = varargin; % 默认全部传递给 plot
to_remove = []; % 记录要移除的参数索引

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'showlabels'
            params.ShowLabels = varargin{i+1};
            to_remove = [to_remove, i, i+1];
        case 'fontsize'
            params.FontSize = varargin{i+1};
            to_remove = [to_remove, i, i+1];
        case 'fontweight'
            params.FontWeight = varargin{i+1};
            to_remove = [to_remove, i, i+1];
    end
end
% 从传递给 plot 的参数列表中移除我们已经处理过的参数
args_to_pass(to_remove) = [];

% --- 2. 提取数据 ---
if ~isnumeric(circleData) || size(circleData, 1) ~= 3 || isempty(circleData)
    error('输入必须是一个非空的 3xN 数值矩阵。');
end
x_centers = circleData(1, :);
y_centers = circleData(2, :);
radii     = circleData(3, :);
n_circles = size(circleData, 2);

% --- 3. 绘图准备 ---
theta = linspace(0, 2*pi, 101);
hold on;
h_circles = gobjects(1, n_circles);
h_labels = gobjects(1, n_circles);

% --- 4. 循环绘图 ---
for i = 1:n_circles
    x_c = x_centers(i);
    y_c = y_centers(i);
    r = radii(i);
    
    x_coords = r * cos(theta) + x_c;
    y_coords = r * sin(theta) + y_c;
    
    % 绘制圆，并将所有未被我们处理的参数传递给 plot
    % **这是关键的修正**：现在 'Color', 'LineWidth' 等参数会正确地
    % 应用到每一个 plot 命令上，确保样式统一。
    h_circles(i) = plot(x_coords, y_coords, args_to_pass{:});
    
    % 获取刚刚绘制的线条的颜色，用于标签
    % 即使 'Color' 是 'm' 这样的字符，get 返回的也是 RGB 值
    line_color = get(h_circles(i), 'Color');
    
    % 添加数字标签
    if params.ShowLabels
        label_str = num2str(i);
        
        % **这是第二个关键修正**：使用正确的坐标和对齐方式
        h_labels(i) = text(x_c, y_c, label_str, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment',   'middle', ...
            'FontSize',            params.FontSize, ...
            'FontWeight',          params.FontWeight, ...
            'Color',               line_color); % 标签颜色与线条一致
    end
end

% --- 5. 完善图像和输出 ---
axis equal;
hold off;

if nargout > 0
    h.circles = h_circles;
    h.labels = h_labels;
end

end