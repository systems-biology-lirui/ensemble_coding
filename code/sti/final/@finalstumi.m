%% 9个数据库（不同target），每个数据库160张（每张代表一个平均朝向），其中40张target，120张非target，采用随机抽取相位和小光栅方向
% % %整张图片，包括灰色背景小于4*4°
 clear;
 clc;

file_path = '/home/dclab2/Ensemble coding/code/sti/final/base/nogaosi/2';
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
% for o = 1:180
%     for p = 1:6
%         img = finalimg(y,x,:,p,o);
%         [X, Y] = meshgrid(1:44, 1:44);
%         centerX = 22;
%         centerY = 22;
%         radius = 40; % 圆的半径
%         mask = (X - centerX).^2 + (Y - centerY).^2 <= radius^2;
%         masked_img = img;
%         masked_img(~mask) = 0;
% 
%         % 对非圆形区域应用模糊处理
%         % 使用wiener2函数进行模糊处理
%         blurred_img = wiener2(img, [7 7], 0.1);
% 
%         % 将模糊处理后的图像与原始图像合并
%         result_img = blurred_img;
%         result_img(mask) = masked_img(mask);
%         finalimg(y,x,:,p,o) = result_img;
%     end
% end

disp('over');

stipath = '0730';
%% 绘制图片
%设置画布的尺寸
canvasWidth = 1920;
canvasHeight = 1080;

% 创建一个灰色背景
grayBackground = 130/255 * ones(canvasHeight, canvasWidth, 3);
varience = 10;

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


data = zeros(5,12,108);

info = imfinfo('D:\Desktop\electro\code\final\mt\2\0000000030.bmp');
colormap = info.Colormap;
tip = 200/255;




%% 生成固定相位矩阵
phases = ones(1,6);

for tt = 2:6
    phase1 = ones(1,6)*tt;
    phases = cat(2,phases,phase1);
end
for nn = 1:17
    phase1 = 1:6;
    phases = cat(2,phases,phase1);
end
for rr = 1:6
    phase1 = randi(6);
    phases = cat(2,phases,phase1);
end


targetorders = 1:2:17;
%for targetorder =targetorders
targetorder = 5;
    dataname = sprintf('data%d.mat', targetorder*10) ;
    datapath = fullfile('D:', 'Desktop', stipath, num2str(targetorder));

%% 遍历每个像素点
    for num = 1:144%160
        phase = phases(num);
        %绘制前40个，target90
        if num < 37%41
            % 生成
            order = targetorder;
            rl = [1, 2, 3, 5 ,7, 9];
            ra = cat(2, rl,0-rl);
            ra = ra +order*10;
    
            %         ra= randperm(2*varience)+order*10-varience;
            %         randoml = ra(1:6);
            %         randomr = order*20 - randoml;
            %         ra = cat(2, randoml, randomr);
            idx = find(ra > 180);
            ra(idx) = ra(idx) - 180;
            idx = find(ra <= 0);
            ra(idx) = ra(idx) + 180;
            l = length(ra);
            ranorder = randperm(l);
            ra = ra(ranorder);
            randomSelectionO_out = ra(1:num_out);
            randomSelectionO_in = ra((num_out+1):(num_out+num_in));
        end
        if num > 36%40
            if num < 43%48
                if targetorder ==1
                    order = 2;
                else
                    order = 1;
                end
    
            elseif num > 42%47
                if num <= 36+(6*(targetorder-1))%97
                    order = (num-37 - mod(num-37, 6))/6+1;
                elseif num > 138
                    order = randi(18);
                    while order ==targetorder
                        order =randi(18);
                    end
                else
                    order = (num-37 - mod(num-37, 6))/6+2;
                end
            end
    
            %         ra = randperm(2*varience)+order*10-varience;
            %         %如果这一步处理可能会导致负数的话，还需要加上角度转换
            %
            %         randoml = ra(1:6);
            %         randomr = order*20 - randoml;
            %         ra = cat(2, randoml, randomr);
            %         idx = find(ra > 180);
            %         ra(idx) = ra(idx) - 180;
            %         idx = find(ra <= 0);
            %         ra(idx) = ra(idx) + 180;
            %         l = length(ra);
            %         ranorder = randperm(l);
            %         ra = ra(ranorder);
            %         randomSelectionO_out = ra(1:num_out);
            %         randomSelectionO_in = ra((num_out+1):(num_out+num_in));
            rl = [1, 2, 3, 5 ,7, 9];
            ra = cat(2, rl,0-rl);
            ra = ra +order*10;
            idx = find(ra > 180);
            ra(idx) = ra(idx) - 180;
            idx = find(ra <= 0);
            ra(idx) = ra(idx) + 180;
            l = length(ra);
            ranorder = randperm(l);
            ra = ra(ranorder);
            randomSelectionO_out = ra(1:num_out);
            randomSelectionO_in = ra((num_out+1):(num_out+num_in));
        end
        angle = ra;
        data(1,:,num)= angle;
        data(3,:,num)= order*10;
    
    
    
    
    
        for i = 1:num_out
            % 确定圆心和半径
            single = randomSelectionO_out(i);
    
            gabor_center_x = stisize/2;
            gabor_center_y = stisize/2;
            for y = 1:size(finalimg(:, :, :, phase, single), 1)
                for x = 1:size(finalimg(:, :, :, phase, single), 2)
                    % 计算当前像素点到圆心的距离
                    distance = sqrt((x - gabor_center_x)^2 + (y - gabor_center_y)^2);
    
                    % 如果距离小于等于半径，则将该像素点的值复制到 circle_img 中
                    if distance <= radius
                        grayBackground(centermatrix_out(i,2)-gabor_center_y+y, centermatrix_out(i,1)-gabor_center_x+x, :) = finalimg(y, x, :, phase, single);
                    end
                end
            end
            data(2,i,num) = phase*30;
            data(4,i,num) = centermatrix_out(i,1);
            data(5,i,num) = centermatrix_out(i,2);
        end
        for i = 1:num_in
            single = randomSelectionO_in(i);
    
            %phase = randi(6);
            % 确定圆心和半径
            gabor_center_x = stisize/2;
            gabor_center_y = stisize/2;
    
            for y = 1:size(finalimg(:, :, :, phase, single), 1)
                for x = 1:size(finalimg(:, :, :, phase, single), 2)
                    % 计算当前像素点到圆心的距离
                    distance = sqrt((x - gabor_center_x)^2 + (y - gabor_center_y)^2);
                    % 如果距离小于等于半径，则将该像素点的值复制到 circle_img 中
                    if distance <= radius
                        grayBackground(centermatrix_in(i,2)-gabor_center_y+y, centermatrix_in(i,1)-gabor_center_x+x, :) = finalimg(y, x, :, phase, single);
                    end
                end
            end
            data(2,i+8,num) = phase*30;
            data(4,i+8,num) = centermatrix_in(i,1);
            data(5,i+8,num) = centermatrix_in(i,2);
        end
        if num < 100
            num1 = num2str(num, '%03d');
        else
            num1 = num2str(num);
        end
        filename =  sprintf('0000000%s.bmp',  num1);
        fullpath = fullfile(datapath, filename);
        colormappath = fullfile('D:', 'Desktop', stipath, num2str(targetorder), '1');
        fullpath2 =fullfile(colormappath,filename);
        sti = im2gray(grayBackground(420:660,840:1080,:));
        imwrite(sti, fullpath);
        %% 进行colormap转换
        sti1 = imread(fullpath);
        tip = 0.78;
    
        for xxx = 1:241
            for yyy = 1:241
                sti1(xxx,yyy) = sti1(xxx,yyy)*tip;
            end
        end
        sti2 = sti1;
        %sti2 = sti1*tip;
        for xx = 3:238
            for yy = 3:238
                for oo = 1:8
                    if sqrt(( centermatrix_out(oo,1)+1 - 840 -xx)^2+(centermatrix_out(oo,2)+1 -420-yy)^2) < 22 && sqrt(( centermatrix_out(oo,1)+1 - 840 -xx)^2+(centermatrix_out(oo,2)+1 -420-yy)^2) >= 12
                        a = sti1(xx-2:xx+2,yy-2:yy+2);
                        sti2(xx,yy) = round(mean(a(:)));
                    elseif sqrt(( centermatrix_out(oo,1)+1 - 840 -xx)^2+(centermatrix_out(oo,2)+1 -420-yy)^2) == 21
                        sti2(xx,yy) = 102;
    
                    end
                end
                for ii = 1:4
                    if sqrt(( centermatrix_in(ii,1)+1 - 840 -xx)^2+(centermatrix_in(ii,2)+1 -420-yy)^2) < 22 && sqrt(( centermatrix_in(ii,1)+1 - 840 -xx)^2+(centermatrix_in(ii,2)+1 -420-yy)^2) >= 12
                        a = sti1(xx-2:xx+2,yy-2:yy+2);
                        sti2(xx,yy) = round(mean(a(:)));
                    elseif sqrt(( centermatrix_in(ii,1)+1 - 840 -xx)^2+(centermatrix_in(ii,2)+1 -420-yy)^2) == 21
                        sti2(xx,yy) = 102;
                    end
                end
            end
        end
        sti1 = sti2;
        sti1(sti1<=3)=4;
        %sti1 = sti1 * tip;
        %sti1(sti1 ==173)=221;
    
        for xx = 2:239
            for yy = 2:239
                for oo = 1:8
                    if sqrt(( centermatrix_out(oo,1)+1 - 840 -xx)^2+(centermatrix_out(oo,2)+1 -420-yy)^2) <= 21
                        if sti1(xx, yy)==221
                            sti1(xx, yy) = 102;
                        end
                    end
                end
                for ii = 1:4
                    if sqrt(( centermatrix_in(ii,1)+1 - 840 -xx)^2+(centermatrix_in(ii,2)+1 -420-yy)^2) <= 21
                        if sti1(xx, yy)==221
                            sti1(xx, yy) = 102;
                        end
                    end
                end
            end
        end
    
    
        imwrite(sti1, colormap, fullpath2); %colormap,
    
    end
    
    
    save(fullfile(datapath,dataname),'data');

% 显示结果
%imshow(grayBackground);



