%设置光栅位置中心
num_out = 8;
num_in = 4;
%外环8个
% 定义半径
radius = 55;
l_out = 17;%光栅间距离缩放
l_in = 0;
distance_out = (radius+l_out)/sin(pi/num_out);%光栅距离原点
distance_in = (radius+l_in)/sin(pi/num_in);

%% 外环
% 计算角度，每个点之间的角度为 360/8 度
angle_step_out = 360 / num_out;
angles_out = 0:angle_step_out:(360 - angle_step_out);

% 计算每个点的坐标
x_coords_out = round(distance_out * cosd(angles_out));
x_coords_out([2,4,6,8]) = round(x_coords_out([2,4,6,8])*0.9);
y_coords_out = round(distance_out * sind(angles_out));
y_coords_out([2,4,6,8]) = round(y_coords_out([2,4,6,8])*0.9);
centermatrix_out=cat(2,x_coords_out.',y_coords_out.');
centermatrix_out(:,1) = centermatrix_out(:,1) + 960;
centermatrix_out(:,2) = 540 - centermatrix_out(:,2);

%% 内环
% 计算角度，每个点之间的角度为 360/8 度
angle_step_in = 360 / num_in;
angles_in = 0:angle_step_in:(360 - angle_step_in);

% 计算每个点的坐标
x_coords_in = round(distance_in * cosd(angles_in));
y_coords_in = round(distance_in * sind(angles_in));
centermatrix_in=cat(2,x_coords_in.',y_coords_in.');
centermatrix_in(:,1) = centermatrix_in(:,1) + 960;
centermatrix_in(:,2) = 540 - centermatrix_in(:,2);

%% 四角



%设置画布的尺寸
canvasWidth = 1920;
canvasHeight = 1080;

filepath= 'D:\Desktop\gabor2.png';
% 创建一个灰色背景
grayBackground = 0.5 * ones(canvasHeight, canvasWidth, 3);


% 读取不同的图片
img = im2double(imread(filepath)); % 替换为你的图片路径





% 遍历每个像素点
for i = 1:num_out
    % 确定圆心和半径
    center_x = round(size(img, 2) / 2);
    center_y = round(size(img, 1) / 2);
    for y = 1:size(img, 1)
        for x = 1:size(img, 2)
            % 计算当前像素点到圆心的距离
            distance = sqrt((x - center_x)^2 + (y - center_y)^2);

            % 如果距离小于等于半径，则将该像素点的值复制到 circle_img 中
            if distance <= radius
                grayBackground(centermatrix_out(i,2)-center_y/2+y, centermatrix_out(i,1)-center_x/2+x, :) = img(y, x, :);
            end
        end
    end
end
for i = 1:num_in
    % 确定圆心和半径
    center_x = round(size(img, 2) / 2);
    center_y = round(size(img, 1) / 2);
  
    for y = 1:size(img, 1)
        for x = 1:size(img, 2)
            % 计算当前像素点到圆心的距离
            distance = sqrt((x - center_x)^2 + (y - center_y)^2);

            % 如果距离小于等于半径，则将该像素点的值复制到 circle_img 中
            if distance <= radius
                grayBackground(centermatrix_in(i,2)-center_y/2+y, centermatrix_in(i,1)-center_x/2+x, :) = img(y, x, :);
            end
        end
    end
end

% 显示结果
imshow(grayBackground);
