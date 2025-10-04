
plot_final = {};
label = {'SG','MGnv','MGv','SG','MGnv','MGv'};
condition = {'random_am','target_am','dprimeresult'};
for i = 4:6
    for m = 1:3
        plot_final{i,m} = plot_content_dg.(label{i}).(condition{m});

    end
end
% 1. 生成示例数据
% --- 您需要将这部分替换为您自己的实际数据 ---
Fs = 500;
N = 1600;
f = Fs * (0:N/2) / N;
% 定义6组线条的固定y坐标
y_coords_groups = [1, 11, 21, 31, 41, 51];


% 2. 开始绘图
% 创建一个新的图形窗口和三维坐标轴
figure('Name', '3D Line and Data Visualization', 'Position', [100, 100, 1000, 800]);
ax = axes;
hold(ax, 'on'); % 保持坐标轴，以便在上面叠加多个绘图对象

% --- 2a. 绘制灰色半透明方块 ---
% 定义方块的顶点和面
x_box = [5.6, 6.8];
y_box = [0, 27];
z_box = [0, 25];

% 8个顶点坐标
vertices1 = [
    x_box(1), y_box(1), z_box(1); % 1
    x_box(2), y_box(1), z_box(1); % 2
    x_box(2), y_box(2), z_box(1); % 3
    x_box(1), y_box(2), z_box(1); % 4
    x_box(1), y_box(1), z_box(2); % 5
    x_box(2), y_box(1), z_box(2); % 6
    x_box(2), y_box(2), z_box(2); % 7
    x_box(1), y_box(2), z_box(2)  % 8
];
x_box = [24.6, 25.4];
y_box = [0, 27];
z_box = [0, 10];
vertices2 = [
    x_box(1), y_box(1), z_box(1); % 1
    x_box(2), y_box(1), z_box(1); % 2
    x_box(2), y_box(2), z_box(1); % 3
    x_box(1), y_box(2), z_box(1); % 4
    x_box(1), y_box(1), z_box(2); % 5
    x_box(2), y_box(1), z_box(2); % 6
    x_box(2), y_box(2), z_box(2); % 7
    x_box(1), y_box(2), z_box(2)  % 8
];

% 6个面 (每个面由4个顶点索引定义)
faces = [
    1, 2, 6, 5; % 底面
    2, 3, 7, 6; % 右面
    3, 4, 8, 7; % 顶面
    4, 1, 5, 8; % 左面
    1, 2, 3, 4; % 前面
    5, 6, 7, 8  % 后面
];

% 使用 patch 绘制方块
% patch(ax, 'Vertices', vertices1, 'Faces', faces, ...
%       'FaceColor', [0.5, 0.5, 0.7], ... % 灰色
%       'FaceAlpha', 0.2, ...            % 半透明
%       'EdgeColor', 'none');            % 无边缘线
% patch(ax, 'Vertices', vertices2, 'Faces', faces, ...
%       'FaceColor', [0.5, 0.5, 0.5], ... % 灰色
%       'FaceAlpha', 0.2, ...            % 半透明
%       'EdgeColor', 'none');            % 无边缘线
      
% --- 2b. 循环绘制6组线条、矩形和散点 ---
for i = 1:6
    if i<4
        sel_coil = dg_sel_coil;
    else
        sel_coil = qq_sel_coil;
    end
    % 获取当前组的固定y坐标
    y_val = y_coords_groups(i);
    
    % --- 绘制线条1 (gray) ---
    line1_data = plot_final{i, 1}(2:100);
    x_coords = f(2:100);  % x坐标不变
    z_coords = line1_data;  % y坐标变为z坐标
    y_coords = ones(size(x_coords)) * y_val; % 新的y坐标是固定的
    plot3(ax, x_coords, y_coords, z_coords, 'Color',[0.6,0.6,0.6], 'LineWidth', 2.5);

    % --- 绘制线条2 (red) ---
    line2_data = plot_final{i, 2}(2:100);
    x_coords = f(2:100);
    z_coords = line2_data;
    y_coords = ones(size(x_coords)) * y_val;
    plot3(ax, x_coords, y_coords, z_coords, 'Color', [0.7 0.2 0.2], 'LineWidth', 2.5);
    
    % --- 绘制 d-prime 相关的矩形和散点 ---
    d_primes = plot_final{i, 3}(1,sel_coil)*20;
    d_prime_mean = mean(d_primes);
    base_z = 28;
    
    % 绘制矩形 (使用 patch)
    % 矩形的x坐标固定为0
    % 为了让矩形可见，我们在y轴上给它一点宽度，例如 y_val-0.5 到 y_val+0.5
    rect_x = [0, 0, 0, 0];
    rect_y = [y_val - 1, y_val + 1, y_val + 1, y_val - 1]+2.5;
    rect_z = [base_z, base_z, base_z + d_prime_mean, base_z + d_prime_mean];
    patch(ax, rect_x, rect_y, rect_z, [0.5,0.5,0.5], 'FaceAlpha', 0.5); % 蓝色半透明矩形

    % 绘制 d-prime 散点
    num_points = length(d_primes);
    scatter_x = zeros(num_points, 1); % x坐标为0
    jitter = [];
    for dd = 1:length(sel_coil)
        jitter(dd) = randi(10)/10-0.5;
    end
    scatter_y = ones(num_points, 1) * y_val+jitter'+2.5; % y坐标为组的y坐标
    scatter_z = base_z + d_primes; % z坐标在基线之上
    scatter3(ax, scatter_x, scatter_y, scatter_z, 10, 'k', 'filled'); % 黑色实心散点

    [h, p, ci, stats] = ttest(d_primes, 0, 'Tail', 'right');

    % 根据p值标记显著性符号
    if p < 0.001
        significance = '***'; % 极其显著
    elseif p < 0.01
        significance = '**';  % 非常显著
    elseif p < 0.05
        significance = '*';   % 显著
    else
        significance = 'ns';  % 不显著（"not significant"）
    end
    text(0, y_val+2.5, 40 + 0.5, significance, 'FontSize', 20, ...
     'Color', [0.7,0.2,0.2], 'HorizontalAlignment', 'center');

    % --- 绘制 d-prime 相关的矩形和散点 ---
    d_primes = plot_final{i, 3}(3,sel_coil)*20;
    d_prime_mean = mean(d_primes);
    base_z = 2;
    
    % 绘制矩形 (使用 patch)
    % 矩形的x坐标固定为0
    % 为了让矩形可见，我们在y轴上给它一点宽度，例如 y_val-0.5 到 y_val+0.5
    rect_x = [32, 32, 32, 32];
    rect_y = [y_val - 1, y_val + 1, y_val + 1, y_val - 1]+2.5;
    rect_z = [base_z, base_z, base_z + d_prime_mean, base_z + d_prime_mean];
    patch(ax, rect_x, rect_y, rect_z, [0.5,0.5,0.5], 'FaceAlpha', 0.5); 

    % 绘制 d-prime 散点
    num_points = length(d_primes);
    scatter_x = ones(num_points, 1)*32; % x坐标为0
    for dd = 1:length(sel_coil)
        jitter(dd) = randi(10)/10-0.5;
    end
    scatter_y = ones(num_points, 1) * y_val+jitter'+2.5; % y坐标为组的y坐标
    scatter_z = base_z + d_primes; % z坐标在基线之上
    scatter3(ax, scatter_x, scatter_y, scatter_z, 10, 'k', 'filled'); % 黑色实心散点
    
    z = linspace(0, line2_data(20), 100);
    plot3(repmat(6.25, size(z)), repmat(y_val, size(z)), z, 'Color',[0.2,0.2,0.2], 'LineWidth', 2,'LineStyle','--');

    z = linspace(0, line2_data(80), 100);
    plot3(repmat(25, size(z)), repmat(y_val, size(z)), z, 'Color',[0.2,0.2,0.2], 'LineWidth', 2,'LineStyle','--');

    [h, p, ci, stats] = ttest(d_primes, 0, 'Tail', 'right');

    % 根据p值标记显著性符号
    if p < 0.001
        significance = '***'; % 极其显著
    elseif p < 0.01
        significance = '**';  % 非常显著
    elseif p < 0.05
        significance = '*';   % 显著
    else
        significance = 'ns';  % 不显著（"not significant"）
    end
    text(32, y_val+2.5, 8 + 0.5, significance, 'FontSize', 20, ...
     'Color', [0.7,0.2,0.2], 'HorizontalAlignment', 'center');
end

% 3. 设置图形样式
title('3D Visualization of Line Groups and d-prime Values');
xlabel('Frequency(hz)','FontSize',20,'FontWeight','bold');
% ylabel('Y-axis (Group Identifier)');
yticklabels({'DG SG','DG MGnv', 'DG MGv','QQ SG','QQ MGnv','QQ MGv'})

zlabel('Amplitude','FontSize',20,'FontWeight','bold');
grid off;
view(-35, 25); % 设置一个较好的三维视角
% 获取当前坐标轴对象
ax = gca;
ax.XAxis.FontSize = 16; % 设置字体大小为 14（可以根据需要调整大小）
ax.XAxis.FontWeight = 'bold';
ax.XAxis.LineWidth = 2;
% 修改 y 轴刻度标签的字体大小
ax.YAxis.FontSize = 18; % 设置字体大小为 14（可以根据需要调整大小）
ax.YAxis.FontWeight = 'bold';
ax.YAxis.LineWidth = 2;
ax.ZAxis.FontSize = 16; % 设置字体大小为 14（可以根据需要调整大小）
ax.ZAxis.FontWeight = 'bold';
ax.ZAxis.LineWidth = 2;
axis tight; % 调整坐标轴范围以适应数据
set(ax, 'YTick', y_coords_groups); % 让Y轴刻度只显示组的坐标

hold(ax, 'off');
zlim([0,50])