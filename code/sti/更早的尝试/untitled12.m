% 计算小圆环直径
d = (400 * 2 * sin(pi/8)) / sqrt(2);

% 计算圆心角度
theta = 0:45:360-45;

% 存储圆心坐标
centers = zeros(8, 2);

% 计算每个圆环的圆心坐标
for i = 1:8
    centers(i, :) = [400 * cosd(theta(i)), 400 * sind(theta(i))];
end

% 打印结果
disp(centers);