%% 图片像素484*484，粗度5像素，
close all;
%朝向序列
ori_mean_all = [50,55,60,65,70,75,80,85];
band = 15;
barlength = 60;
for orichance = 1:8
 
%-----------------------------single--------------------------------------------
    ori_mean = ori_mean_all(orichance);
    ori_sequence = [ori_mean,ori_mean,ori_mean,ori_mean,ori_mean,ori_mean];
    figure('Units','pixels','Position',[100 100 484 484],'Color',[0.5 0.5 0.5],'Resize','off');
    ax = axes('Position',[0 0 1 1],'XLim',[0.5 484.5],'YLim',[0.5 484.5],...
        'Color',[0.5 0.5 0.5],'DataAspectRatio',[1 1 1],'YDir','reverse');
    axis off;
    hold on;
     % 生成6个不重复的随机位置
    grid_indices = randperm(16,1);  % 从16个网格中随机选6个
    [rows,cols] = ind2sub([4,4], grid_indices);  % 转换为行列坐标
    
    for k = 1
        i = rows(k);
        j = cols(k);
        
        % 计算方格中心坐标
        xc = (j-1)*121 + 61.5;  % 121 = 484/4
        yc = (i-1)*121 + 61.5;
        
        % 生成随机角度（0-360度）
        theta = ori_sequence(k);
        theta_rad = deg2rad(theta);
        
        % 创建变换对象并绘制矩形
        h = hgtransform('Parent',ax);
        rectangle('Position',[-15 -2.5 barlength band], 'FaceColor','r', 'Parent',h);
        
        % 应用旋转变换和平移
        R = makehgtform('zrotate', theta_rad);
        T = makehgtform('translate', xc, yc, 0);
        h.Matrix = T * R;
    end
    
    hold off;
    frame = getframe(gcf);           % 捕获整个窗口5
    imwrite(frame.cdata, sprintf('/home/dclab2/plot1118/plot/single%d.png',orichance));
    close all
% ----------------------------homo----------------------------------------------
    ori_mean = ori_mean_all(orichance);
    ori_sequence = [ori_mean,ori_mean,ori_mean,ori_mean,ori_mean,ori_mean,ori_mean,ori_mean];
    location_random = randperm(16,8);
    
    figure('Units','pixels','Position',[100 100 484 484],'Color',[0.5 0.5 0.5],'Resize','off');
    ax = axes('Position',[0 0 1 1],'XLim',[0.5 484.5],'YLim',[0.5 484.5],...
        'Color',[0.5 0.5 0.5],'DataAspectRatio',[1 1 1],'YDir','reverse');
    axis off;
    hold on;
    
    % 生成6个不重复的随机位置
    grid_indices = randperm(16,8);  % 从16个网格中随机选6个
    [rows,cols] = ind2sub([4,4], grid_indices);  % 转换为行列坐标
    
    for k = 1:8
        i = rows(k);
        j = cols(k);
        
        % 计算方格中心坐标
        xc = (j-1)*121 + 61.5;  % 121 = 484/4
        yc = (i-1)*121 + 61.5;
        
        % 生成随机角度（0-360度）
        theta = ori_sequence(k);
        theta_rad = deg2rad(theta);
        
        % 创建变换对象并绘制矩形
        h = hgtransform('Parent',ax);
        rectangle('Position',[-15 -2.5 barlength band], 'FaceColor','r', 'Parent',h);
        
        % 应用旋转变换和平移
        R = makehgtform('zrotate', theta_rad);
        T = makehgtform('translate', xc, yc, 0);
        h.Matrix = T * R;
    end
    
    hold off;
    frame = getframe(gcf);           % 捕获整个窗口
    imwrite(frame.cdata, sprintf('/home/dclab2/plot1118/plot/heter%d.png',orichance));
    close all
    % ----------------------------heter----------------------------------------------
    ori_mean = ori_mean_all(orichance);
    ori_sequence = [ori_mean-10,ori_mean-3.3,ori_mean+3.3,ori_mean+10,ori_mean-3.3,ori_mean+3.3,ori_mean+10,ori_mean-10];
    location_random = randperm(16,8);
    
    figure('Units','pixels','Position',[100 100 484 484],'Color',[0.5 0.5 0.5],'Resize','off');
    ax = axes('Position',[0 0 1 1],'XLim',[0.5 484.5],'YLim',[0.5 484.5],...
        'Color',[0.5 0.5 0.5],'DataAspectRatio',[1 1 1],'YDir','reverse');
    axis off;
    hold on;
    
    % 生成6个不重复的随机位置
    grid_indices = randperm(16,8);  % 从16个网格中随机选6个
    [rows,cols] = ind2sub([4,4], grid_indices);  % 转换为行列坐标
    
    for k = 1:8
        i = rows(k);
        j = cols(k);
        
        % 计算方格中心坐标
        xc = (j-1)*121 + 61.5;  % 121 = 484/4
        yc = (i-1)*121 + 61.5;
        
        % 生成随机角度（0-360度）
        theta = ori_sequence(k);
        theta_rad = deg2rad(theta);
        
        % 创建变换对象并绘制矩形
        h = hgtransform('Parent',ax);
        rectangle('Position',[-15 -2.5 barlength band], 'FaceColor','r', 'Parent',h);
        
        % 应用旋转变换和平移
        R = makehgtform('zrotate', theta_rad);
        T = makehgtform('translate', xc, yc, 0);
        h.Matrix = T * R;
    end
    
    hold off;
    frame = getframe(gcf);           % 捕获整个窗口
    imwrite(frame.cdata, sprintf('/home/dclab2/plot1118/plot/homo%d.png',orichance));
    
end
