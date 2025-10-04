% %% 9个数据库（不同target），每个数据库160张（每张代表一个平均朝向），其中40张target，120张非target，采用随机抽取相位和小光栅方向
% %整张图片，包括灰色背景小于4*4°
% clear;
% clc;

file_path = 'D:\Desktop\final\base\nogaosi\2';
% %导入全部图片
imgsize = 240;%图像大小
center_x = 185;
center_y = 185;
stisize = 238;%单个光栅的大小
% finalimg = zeros(stisize,stisize,3,6,180);
% for o = 1:180
%     for p = 1:6
%         file_name = sprintf('sine_grating_%d_%d.png',  o, p*30);  
%         img = im2double(imread(fullfile(file_path,file_name)));
%         for y = 1:stisize
%             for x = 1:stisize
%                 finalimg(y,x,:,p,o) = img(center_y-stisize/2+y,center_x-stisize/2+x,:);
%             end
%         end
%     end
% end
% disp('over');


%% 绘制图片
%设置画布的尺寸
canvasWidth = 1920;
canvasHeight = 1080;

info = imfinfo('D:\Desktop\final\mt\2\0000000030.bmp');
colormap = info.Colormap;
% 创建一个灰色背景
grayBackground = 102/255 * ones(canvasHeight, canvasWidth, 3);
data = zeros(3,108);

i =1;
for p = 1:6
    for o = 1:18
    % 确定圆心和半径
        single = o*10;
        phase = p;
        for x = 1:stisize
            for y = 1:stisize
                distance = sqrt((x - stisize/2)^2 + (y - stisize/2)^2);
                if distance <=stisize/2
                    grayBackground(540-stisize/2+y, 960-stisize/2+x, :) = finalimg(y, x, :, phase, single);
                end
            end
        end
        order = num2str(i, '%03d');
        filename =  sprintf('0000000%s.bmp',  order);
        data(1,i) = i;
        data(2,i) = phase*30;
        data(3,i) = o*10;
        i =i +1;
        fullpath = fullfile('D:\Desktop\sti\single\', filename);
        sti = im2gray(grayBackground(420:660,840:1080,:));
        
        imwrite(sti, fullpath);
        %% colormap
        fullpath2 = fullfile('D:\Desktop\sti\single\1\', filename);
        sti1 = imread(fullpath);
        sti1(sti1<=3)=4;
        tip = 201/255;
        sti1 = sti1 * tip;
        sti1(sti1 ==173)=221;

        for xx = 2:239
            for yy = 2:239
                if sqrt((xx-120)^2+(yy-120)^2) <= 120
                    if sti1(xx, yy)==221
                        sti1(xx, yy) = 173;
                    end
                    if sti1(xx, yy) ==201
                        sti1(xx,yy) = 199;
                    end
                end
            end
       
        end


        imwrite(sti1, colormap, fullpath2);

    end

end


