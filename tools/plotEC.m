
function h = plotEC(Orimatrix,base_path)


canvasWidth = 1920;
canvasHeight = 1080;


stisize = 40;%单个光栅的大小

% 创建一个灰色背景
grayBackground = 255/255 * ones(canvasHeight, canvasWidth, 3);


%设置光栅位置中心
num_out = 8;
num_in = 4;
load(base_path);
local_matrix = localnum(num_out,num_in,stisize);


for local = 1:12
    
    % 确定圆心和半径
    
    for x = 1:stisize
        for y = 1:stisize
            distance = sqrt((x - stisize/2)^2 + (y - stisize/2)^2);
            if distance <=stisize/2
                grayBackground(local_matrix(local,2)-stisize/2+y, local_matrix(local,1)-stisize/2+x, :) = finalimg(y, x, :, 2, Orimatrix(local));
            end
        end
    end
    
end
sti = im2gray(grayBackground(420:660,840:1080,:));
h = imshow(sti);


%导入全部图片
function finalimg = loadSC(file_path)
center_x = 185;
center_y = 185;
stisize = 40;%单个光栅的大小
finalimg = zeros(stisize,stisize,3,6,180);
for o = 1:180
    for p = 1:6
        file_name = sprintf('sine_grating_%d_%d.png',  o, p*30);
        img = im2double(imread(fullfile(file_path,file_name)));
        for y = 1:stisize
            for x = 1:stisize
                finalimg(y,x,:,p,o) = img(center_y-stisize/2+y,center_x-stisize/2+x,:);
            end
        end
    end
end


function  local_matrix = localnum(num_out,num_in,stisize)
%外环8个
% 定义半径
radius = stisize/2;
l_out = 15;%光栅间距离缩放
l_in =6;
distance_out = (radius+l_out)/sin(pi/num_out);%光栅距离原点
distance_in = (radius+l_in)/sin(pi/num_in);


%% 外环
% 计算角度，每个点之间的角度为 360/8 度
angle_step_out = 360 / num_out;
angles_out = 0:angle_step_out:(360 - angle_step_out);

% 计算每个点的坐标
x_clocalrds_out = round(distance_out * cosd(angles_out));
x_clocalrds_out([2,4,6,8]) = round(x_clocalrds_out([2,4,6,8])*0.9);
y_clocalrds_out = round(distance_out * sind(angles_out));
y_clocalrds_out([2,4,6,8]) = round(y_clocalrds_out([2,4,6,8])*0.9);
centermatrix_out=cat(2,x_clocalrds_out.',y_clocalrds_out.');
centermatrix_out(:,1) = centermatrix_out(:,1) + 960;
centermatrix_out(:,2) = 540 - centermatrix_out(:,2);

%% 内环
% 计算角度，每个点之间的角度为 360/8 度
angle_step_in = 360 / num_in;
angles_in = 0:angle_step_in:(360 - angle_step_in);

% 计算每个点的坐标
x_clocalrds_in = round(distance_in * cosd(angles_in));
y_clocalrds_in = round(distance_in * sind(angles_in));
centermatrix_in=cat(2,x_clocalrds_in.',y_clocalrds_in.');
centermatrix_in(:,1) = centermatrix_in(:,1) + 960;
centermatrix_in(:,2) = 540 - centermatrix_in(:,2);


local_matrix = cat(1,centermatrix_in,centermatrix_out);
