function h_lines = plot_orierp_diffcolor(ax, data)
%% 1. 数据准备 (模拟生成 18x121 的数据)
% 实际使用时，请将下面的 'data' 替换为你真实的 18x121 矩阵
% 假设行(1-18)是朝向，列(1-121)是时间
time_points = 1:121;
orientations = 1:20;
% 生成一些示例数据：中间的朝向振幅大一点，方便观察

% 2. 参数设置
target_idx = 20;   % 目标中心朝向（最红、最粗）
max_width = 3.0;  % 最粗线条宽度
min_width = 0.5;  % 最细线条宽度

% 计算每个朝向距离中心(9)的距离
% distance 越小，说明越靠近 9
distances = abs(orientations - target_idx);
max_dist = max(distances); % 用于归一化 (最大距离应该是 9)

% 3. 确定绘制顺序
%为了让红色的粗线浮在最上面，我们需要按照距离从大到小排序
% 也就是先画远的(蓝线)，后画近的(红线)
[~, plot_order] = sort(distances, 'descend');

if isempty(ax), figure; ax = gca; end

hold(ax, 'on'); box on; grid on;

% 初始化句柄数组
h_lines = gobjects(length(orientations), 1);

for i = 1:length(plot_order)
    idx = plot_order(i); % 当前的真实朝向索引 (1-18)
    
    % --- 计算颜色 ---
    % 归一化距离因子 (0 = 在中心, 1 = 最远)
    norm_dist = distances(idx) / max_dist; 
    
    % 颜色插值: 
    % 靠近 9 (norm_dist -> 0): 红色 [1 0 0]
    % 远离 9 (norm_dist -> 1): 蓝色 [0 0 1]
    % 中间过渡色为紫色
    line_color = [1 - norm_dist, 0, norm_dist];
    
    % --- 计算线宽 ---
    % 距离越近(norm_dist小)，线越粗
    current_width = min_width + (max_width - min_width) * (1 - norm_dist);
    
    % --- 绘制线条并保存句柄 ---
    h_lines(idx) = plot(ax, time_points, smooth(data(idx, :)), ...
         'Color', line_color, ...
         'LineWidth', current_width);
end

% 5. 图形美化
xlabel('Time');
ylabel('Signal Amplitude');
% title('Signal by Orientation (Red/Thick = Orientation 9)');
xlim([1 121]);

% 添加一个自定义的 Colorbar 说明 (可选)
colormap([linspace(0,1,64)', zeros(64,1), linspace(1,0,64)']); % 创建蓝到红的colormap
% c = colorbar;
c.Label.String = 'Proximity to Orientation 9';
c.Ticks = [0, 1];
c.TickLabels = {'Blue (Far)', 'Red (Close)'};

hold off;
end