%这一个是用来构建和EC中同位置完全相同的patch的

info=imfinfo('D:\Desktop\Ensemble coding\sti\0814sti\gsq\ec\z324ec1_20240815\0000000001.bmp');
colormap = info.Colormap;
for i =1:324
    filename = sprintf('0000000%03d.bmp',i);
    filepath = fullfile('D:\Desktop\Ensemble coding\sti\0814sti\gsq\ec\z324ec1_20240815',filename);
    img=imread(filepath);
    newimg = struct();
    for m = 1:12
        mask = zeros(241,241);
        for x = 1:241
            for y = 1:241
                distance = sqrt((x-location(m,1))^2+(y-location(m,2))^2);
                if distance > 24
                    mask(x,y)=1;
                end
            end
        end
        newimg.(sprintf('location%d',m)) = img;
        newimg.(sprintf('location%d',m))(mask == 1) = 101;
    end

    for m = 1:12
        filename = sprintf('000000%04d.bmp',(i-1)*12+m);
        filepath1 = fullfile('D:\Desktop\1',filename);
        imwrite(newimg.(sprintf('location%d',m)),colormap,filepath1);
    end
end


% sequence = unique(ori_idx1);
% % 初始化结果矩阵，用于存储位置
% positions = zeros(length(sequence), 2);
% 
% for i = 1:length(sequence)
%     % 使用 find 函数找到矩阵中元素的位置
%     [row, col] = find(ori_idx1 == sequence(i), 1, 'first');
%     % 存储位置
%     if ~isempty(row)
%         positions(i, :) = [row, col];
%     else
%         positions(i, :) = [NaN, NaN]; % 若找不到则存 NaN
%     end
% end


%% 12.11
%%构建varince=20的图片，依照之前18*18，每个朝向18个重复，不考虑相位，只考虑朝向
clear;
ori_var = [3,5,9,12,15,19];
for orientation = 1:18
    data = ones(1,6)*orientation*10;
    data1 = data-ori_var;
    data2 = data+ori_var;
    ori_idx(orientation,:) = [data1,data2];
    
end
ori_idx1 = ori_idx;
ori_idx1(ori_idx<0) = ori_idx(ori_idx<0)+180;
ori_idx1(ori_idx>180) = ori_idx(ori_idx>180)-180;
% 显示结果
load('/home/dclab2/Ensemble coding/data/patch_location.mat')
location2 = location([4,3,2,1,11,10,9,8,7,6,5,12],:);
info = imfinfo('/home/dclab2/Ensemble coding/sti/0829sti/z1296first_20240829/0000000001.bmp');
colormap = info.Colormap;
[x1, y1] = meshgrid(1:241, 1:241);
[x2, y2] = meshgrid(1:369, 1:369);

% 高斯模糊参数
sigma = 1; % 标准差，控制模糊程度
gaussianFilter = fspecial('gaussian', [45, 45], sigma);
times = 1;
for ori = 1:18
    for repeat = 1:18
        randomidx = randperm(12);
        grating_local = ori_idx1(ori, randomidx);
        orientation_var20(times,:) = grating_local;
        times = times+1;
        imagehomo = ones(241, 241) * 101;
        for i = 1:12
            filename = sprintf('sine_grating_%s_30.png', num2str(grating_local(i)));
            filepath = fullfile('/home/dclab2/Ensemble coding/code/sti/base/nogaosi/2', filename);
            img = rgb2gray(imread(filepath)) * 0.788;
            img(img < 3) = 3;
            
            % 定义输入和输出的掩码
            maskinput = sqrt((x1 - location2(i, 1)).^2 + (y1 - location2(i, 2)).^2) <= 20;
            maskoutput = sqrt((x2 - 185).^2 + (y2 - 185).^2) <= 20;
            maskgaosi = sqrt((x1 - location2(i, 1)).^2 + (y1 - location2(i, 2)).^2) <= 24;
            croppedImg = img(maskoutput);
            
            % 将提取的圆形图像放置到目标图像中
            imagehomo(maskinput) = croppedImg;

            % 提取放置的图像区域
            origRegion = imagehomo(maskgaosi);

            % 将该区域进行高斯模糊
            blurredRegion = imfilter(origRegion, gaussianFilter, 'replicate');

            % 创建边缘模糊掩码
            distanceMask = bwdist(~maskgaosi);
            transitionZone = (distanceMask > 0) & (distanceMask <= 8); % 边缘过渡区域
            smoothMask = imfilter(double(transitionZone), gaussianFilter, 'replicate');
            smoothMask = smoothMask / max(smoothMask(:)); % 归一化

            % 调整 smoothMask 的大小与 origRegion 和 blurredRegion 匹配
            smoothMask = smoothMask(maskgaosi);

            % 使用模糊掩码的过渡区域进行合成
            imagehomo(maskgaosi) = blurredRegion .* smoothMask + origRegion .* (1 - smoothMask);
        end
        
        newimg = imagehomo;
        
        filename1 = sprintf('0000000%03d.bmp', (ori-1)*18 + repeat);
        filepath1 = fullfile('/home/dclab2/Ensemble coding/1212var20', filename1);
        imwrite(newimg, colormap, filepath1);
    end
end
save('/home/dclab2/Ensemble coding/data/var20.mat','orientation_var20')
    
        
    