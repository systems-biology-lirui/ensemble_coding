% 定义圆心坐标数组
circles = [
    0, 348;
    331, 108;
    204, -282;
    -331, 108;
    -204, -282;
    110, 64;
    -110, 64;
    0, -128
];

% 定义半径
radius = 100;

% 创建图形窗口
figure;
hold on; % 保持图形，以便在同一图形窗口中绘制所有圆

% 绘制每个圆
for i = 1:size(circles, 1)
    % 提取第i个圆的圆心坐标
    x0 = circles(i, 1);
    y0 = circles(i, 2);
    
    % 计算圆上点的坐标
    theta = linspace(0, 2*pi, 360); % 创建一个从0到2π的参数向量
    x = x0 + radius * cos(theta);
    y = y0 + radius * sin(theta);
    
    % 绘制圆
    plot(x, y, 'b-', 'LineWidth', 2); % 使用蓝色线条绘制圆
end

hold off; % 释放图形
axis equal; % 保持x和y轴的比例一致
grid on; % 显示网格
xlabel('X coordinate');
ylabel('Y coordinate');
title('Circles with Given Centers');