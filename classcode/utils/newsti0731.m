%% --- 准备一张 241x241 的原始图像 ---
% 我们重用之前生成光栅的代码来创建一张细节丰富的测试图
for i = 1:5833
    disp(i)
    originalImage = imread(sprintf('D:\\Ensemble coding\\z5833session1_20250407\\000000%04d.bmp',i));
    info = imfinfo(sprintf('D:\\Ensemble coding\\z5833session1_20250407\\000000%04d.bmp',i));
    % --- 图像准备完毕 ---
%     figure;
%     imshow(originalImage);
    % --- 开始对比不同的缩小方法 ---
    newSize = [96 96];

    % % 方法1: 最近邻插值 (效果差)
    % resized_nearest = imresize(originalImage, newSize, 'nearest');
    %
    % % 方法2: 双线性插值
    % resized_bilinear = imresize(originalImage, newSize, 'bilinear');

    % 方法3: 双三次插值 (推荐)
    resized_bicubic = imresize(originalImage, newSize, 'bicubic');

    % 方法4: 关闭抗锯齿的双三次插值 (作为反例)
    % resized_no_aa = imresize(originalImage, newSize, 'bicubic', 'Antialiasing', false);


    % --- 显示所有结果进行对比 ---
    % figure('Position', [100, 100, 1200, 500]); % 创建一个大窗口
    %
    % subplot(1, 4, 1);
    % imshow(resized_nearest);
    % title({'方法1: 最近邻', '(Nearest-Neighbor)'});
    %
    % subplot(1, 4, 2);
    % imshow(resized_bilinear);
    % title({'方法2: 双线性', '(Bilinear)'});
    %
    % subplot(1, 4, 3);
    % imshow(resized_bicubic);
    % title({'方法3: 双三次 (推荐)', '(Bicubic)'});
    %%
    %
    % subplot(1, 4, 4);
    % imshow(resized_no_aa);
    % title({'方法4: 双三次 (无抗锯齿)', '(Bicubic, No Anti-Aliasing)'});

    % 您可以仔细观察光栅条纹区域，会发现方法3的效果最自然，
    % 而方法1有明显锯齿，方法4在条纹密集处可能出现奇怪的伪影。
    % imwrite(originalImage,colormap, '1.bmp');
    imwrite(resized_bicubic, info.Colormap,sprintf('D:\\Ensemble coding\\z5833session1_20250407\\newsti0915\\000000%04d.bmp',i));
end