%此处是为了做出另一种SC

clear;
clc;

file_path = 'D:\Desktop\Ensemble coding\code\sti\base\nogaosi\2';
%导入全部图片
imgsize = 60;%图像大小
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

canvasWidth = 1920;
canvasHeight = 1080;

info = imfinfo('D:\Desktop\data\0801\2\z432s1_EC_20240801\0000000030.bmp');
colormap = info.Colormap;
% 创建一个灰色背景
grayBackground = 130/255 * ones(canvasHeight, canvasWidth, 3);


%设置光栅位置中心
num_out = 8;
num_in = 4;
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

data = [];
local_matrix = cat(1,centermatrix_in,centermatrix_out);
i = 1;
for p = 1:6
    for o = 1:18

        
        grayBackground = 130/255 * ones(canvasHeight, canvasWidth, 3);
        dir = 'SC';
        path1 = fullfile('D:\Desktop','0814sti',dir);
        path2 = fullfile('D:\Desktop','0814sti',dir,'1');
        if ~exist(path1, 'dir')
            mkdir(path1);
        end
        if ~exist(path2,'dir')
            mkdir(path2);
        end
        for local = 1:12
        % 确定圆心和半径
            single = o*10;
            phase = p;
            for x = 1:stisize
                for y = 1:stisize
                    distance = sqrt((x - stisize/2)^2 + (y - stisize/2)^2);
                    if distance <=stisize/2
                        grayBackground(local_matrix(local,2)-stisize/2+y, local_matrix(local,1)-stisize/2+x, :) = finalimg(y, x, :, phase, single);
                    end
                end
            end
        end
        order = num2str(i, '%03d');
        filename =  sprintf('0000000%s.bmp',  order);
%         data(1,i,local) = i;
%         data(2,i,local) = phase*30;
%         data(3,i,local) = o*10;
%         data(4,i,local) = local;
        i =i +1;
        fullpath = fullfile('D:\Desktop','0814sti',dir, filename);

        sti = im2gray(grayBackground(420:660,840:1080,:));
        
        imwrite(sti, fullpath);
        %% colormap
        fullpath2 = fullfile('D:\Desktop','0814sti',dir,'1', filename);
        sti1 = imread(fullpath);
        tip = 201/255;
        sti1 = sti1 * tip;
        sti2 = sti1;
        for local = 1:12
            for xx = 3:238
                for yy = 3:238          
                    if sqrt((local_matrix(local,1)+1 - 840 -xx)^2+(local_matrix(local,2)+1 -420-yy)^2) < 22 && sqrt((local_matrix(local,1)+1 - 840 -xx)^2+(local_matrix(local,2)+1 -420-yy)^2) >= 12
                        a = sti1(yy-2:yy+2,xx-2:xx+2);
                        sti2(yy,xx) = round(mean(a(:)));
                    elseif sqrt(( local_matrix(local,1)+1 - 840 -xx)^2+(local_matrix(local,2)+1 -420-yy)^2) == 21
                        sti2(yy,xx) = 102;
                    end
                end
            end
        end
        sti1 = sti2;
        sti1(sti1<=3)=4;
        sti1(sti1>200) = 200;


        imwrite(sti1, colormap, fullpath2);
    
   end
    
end


