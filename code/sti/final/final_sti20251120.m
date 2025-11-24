clear;
clc;

%% ================= 1. 参数设置与初始化 =================

% 路径设置 (请修改为你的实际路径)
file_path = 'D:\ensemble_coding\code\sti\base\nogaosi\2'; 
% 需要一张参考BMP来获取Colormap (原代码逻辑)
ref_bmp_path = 'D:\ensemble_coding\z5833session1_20250407\0000000030.bmp'; 
output_dir = 'D:\ensemble_coding\zichenMGnv';

% 图像参数
imgsize = 60;
center_x = 185;
center_y = 185;
stisize = 40;
radius_px = stisize/2;

% 检查输出目录
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% 获取参考 Colormap
try
    info = imfinfo(ref_bmp_path);
    map_palette = info.Colormap;
catch
    error('无法读取参考BMP文件，请检查 ref_bmp_path 是否正确。');
end

%% ================= 2. 导入基础光栅图片 =================

disp('正在加载基础光栅图片...');
finalimg = zeros(stisize,stisize,3,6,180); 
% 假设文件名格式为 sine_grating_角度_相位.png
% 角度: 1-180, 相位: 30, 60 ... 180 (对应索引1-6)
for o = 1:180
    for p = 1:6
        file_name = sprintf('sine_grating_%d_%d.png',  o, p*30);  
        full_p = fullfile(file_path, file_name);
        if exist(full_p, 'file')
            img = im2double(imread(full_p));
            % 裁剪中心 40x40
            finalimg(:,:,:,p,o) = img(center_y-radius_px+1:center_y+radius_px, ...
                                      center_x-radius_px+1:center_x+radius_px, :);
        end
    end
end
disp('图片加载完成。');

%% ================= 3. 定义坐标系统 =================

canvasWidth = 1920;
canvasHeight = 1080;
bgColor = 130/255; % 灰色背景

% 定义几何参数
num_out = 8; num_in = 4;
l_out = 15; l_in = 6;
dist_out = (radius_px + l_out) / sin(pi/num_out);
dist_in  = (radius_px + l_in)  / sin(pi/num_in);

% --- 计算外环 ---
angs_out = 0 : (360/num_out) : (360 - 360/num_out);
x_out = round(dist_out * cosd(angs_out));
y_out = round(dist_out * sind(angs_out));
% 挤压特定点 (原代码逻辑)
idx_sq = [2,4,6,8]; 
x_out(idx_sq) = round(x_out(idx_sq) * 0.9);
y_out(idx_sq) = round(y_out(idx_sq) * 0.9);

% --- 计算内环 ---
angs_in = 0 : (360/num_in) : (360 - 360/num_in);
x_in = round(dist_in * cosd(angs_in));
y_in = round(dist_in * sind(angs_in));

% 合并12个位置的相对坐标 (先内后外)
pos_offsets = [x_in.', y_in.'; x_out.', y_out.'];

% 转换为屏幕坐标 (X+960, Y倒置)
% screen_coords 存储的是 [X, Y]
screen_coords = zeros(12, 2);
screen_coords(:,1) = pos_offsets(:,1) + 960;
screen_coords(:,2) = 540 - pos_offsets(:,2);

%% ================= 4. 预计算边缘模糊掩膜 (优化核心) =================
% 原代码在像素级循环中计算距离，效率极低。这里预先计算好Mask。

disp('预计算模糊掩膜...');
% 定义裁剪区域 (原代码中的 420:660, 840:1080)
crop_y = 420:660; % 高度 241
crop_x = 840:1080; % 宽度 241
[xx_grid, yy_grid] = meshgrid(crop_x, crop_y);

% edge_mask: 标记需要进行模糊处理的像素 (距离中心 [12, 22))
edge_mask = false(size(xx_grid));

for k = 1:12
    cx = screen_coords(k, 1);
    cy = screen_coords(k, 2); % 这里已经是屏幕坐标
    
    % 计算网格点到该光栅中心的距离
    dist_map = sqrt((xx_grid - cx).^2 + (yy_grid - cy).^2);
    
    % 标记距离在 [12, 22) 范围内的点
    % 注意：原代码中 distance < 22 && distance >= 12
    mask_k = (dist_map >= 12) & (dist_map < 22);
    edge_mask = edge_mask | mask_k;
end
disp('掩膜计算完成。');

%% ================= 5. 实验循环生成 =================

% 定义朝向差异列表 (12个，和为0)
% 原列表有13个，去掉了+4以匹配12个位置并保持平均值为中心
% ori_diffs = [-9, -7, -5, -3, -2, -1, 1, 2, 3, 5, 7, 9]; 
ori_diffs = zeros(1,12); 

repeats = 6;
mean_oris = 1:180;
total_trials = length(mean_oris) * repeats;

% 数据记录: [MeanOri, Repeat, Loc1_Ori ... Loc12_Ori]
data_record = zeros(total_trials, 2 + 12);
counter = 1;

% 预计算光栅圆形遮罩
[gx, gy] = meshgrid(1:stisize, 1:stisize);
grating_mask = (gx - stisize/2 - 0.5).^2 + (gy - stisize/2 - 0.5).^2 <= (stisize/2)^2;
grating_mask_3 = repmat(grating_mask, [1,1,3]);

disp('开始生成刺激图片...');
tic;
z= 1;
for m = 1:length(mean_oris)
    curr_mean = mean_oris(m);
    
    for r = 1:repeats
        % --- A. 准备画布 ---
        canvas = bgColor * ones(canvasHeight, canvasWidth, 3);
        
        % --- B. 计算并打乱朝向 ---
        trial_oris = curr_mean + ori_diffs;
        % 处理循环 (1-180)
        trial_oris(trial_oris > 180) = trial_oris(trial_oris > 180) - 180;
        trial_oris(trial_oris < 1)   = trial_oris(trial_oris < 1) + 180;
        
        % 打乱位置
        shuffle_idx = randperm(12);
        shuffled_oris = trial_oris(shuffle_idx);
        ph  = r; % 随机相位
        % --- C. 绘制12个光栅 ---
        for k = 1:12
            ori = shuffled_oris(k);
            
            
            cx = screen_coords(k, 1);
            cy = screen_coords(k, 2);
            
            % 目标区域
            x1 = cx - stisize/2 + 1; x2 = cx + stisize/2;
            y1 = cy - stisize/2 + 1; y2 = cy + stisize/2;
            
            % 融合
            patch_bg = canvas(y1:y2, x1:x2, :);
            patch_sti = finalimg(:,:,:, ph, ori);
            patch_bg(grating_mask_3) = patch_sti(grating_mask_3);
            canvas(y1:y2, x1:x2, :) = patch_bg;
        end
        
        % --- D. 裁剪与后处理 (核心部分) ---
        
        % 1. 裁剪
        sti_crop = canvas(crop_y, crop_x, :);
        
        % 2. 灰度化 (使用 im2gray 或 RGB 均值)
        sti_gray = im2gray(sti_crop); % double 0-1 or uint8
        if ~isa(sti_gray, 'double')
            sti_gray = im2double(sti_gray);
        end
        
        % 3. 变暗 (原代码: sti1 * 201/255) (范围转换到 0-255 进行计算)
        sti_val = sti_gray * 255; % 转回 0-255 范围的 double
        sti_val = sti_val * (201/255);
        
        % 4. 边缘模糊 (Vectorized)
        % 创建一个模糊版本 (5x5 均值滤波)
        h = fspecial('average', [5 5]);
        sti_blurred = imfilter(sti_val, h, 'replicate');
        
        % 仅在 edge_mask 区域应用模糊值
        % 这步代替了原代码中缓慢的 for xx, for yy 判断 distance
        sti_val(edge_mask) = round(sti_blurred(edge_mask));
        
        % 5. 阈值截断
        sti_val(sti_val <= 3) = 4;
        sti_val(sti_val > 200) = 200;
        
        % 6. 转为 uint8 并保存为索引图
        sti_uint8 = uint8(sti_val);
        
        file_name = sprintf('000000%04d.bmp', z);
        z = z+1;
        full_save_path = fullfile(output_dir, file_name);
        
        % 使用指定的 Colormap 保存
        imwrite(sti_uint8, map_palette, full_save_path);
        
        % --- E. 记录数据 ---
        data_record(counter, 1) = curr_mean;
        data_record(counter, 2) = r;
        data_record(counter, 3:end) = shuffled_oris;
        counter = counter + 1;
    end
    
    if mod(m, 10) == 0
        fprintf('已完成平均朝向: %d / 180\n', m);
    end
end

% 保存数据矩阵
save(fullfile(output_dir, 'stimuli_data.mat'), 'data_record', 'screen_coords');
toc;
disp('全部完成。');