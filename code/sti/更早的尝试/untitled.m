% 打开屏幕窗口
[window, windowRect] = Screen('OpenWindow', 0, 255);

% 将背景设置为黑色
blackIndex = BlackIndex(window);
Screen('FillRect', window, blackIndex);

% 绘制圆形刺激参数
rectX = windowRect(3) / 2;    % 假设圆形中心在屏幕水平中心
rectY = windowRect(4) / 2;    % 假设圆形中心在屏幕垂直中心
radius = 100;                 % 圆形半径

% 绘制圆形
Screen('FillOval', window, [255 0 0], rectX - radius, rectY - radius, radius * 2, radius * 2);

% 刷新屏幕显示刺激
Screen('Flip', window);

% 捕获屏幕的特定区域（圆形刺激区域）
% 注意：这里需要根据实际情况调整捕获区域的参数
captureRect = [rectX - radius, rectY - radius, radius * 2, radius * 2];
image = Screen('GetImage', window, captureRect);

% 将捕获的图像转换为标准的MATLAB图像格式
% Psychtoolbox的图像数据存储方式与MATLAB不同，需要转换
% 假设image是double类型的数据，且[0, 255]映射到[0, 1]
matlabImage = uint8(image * 255);

% 导出为图片文件
imwrite(matlabImage, 'stimulus.png');

% 关闭屏幕窗口
Screen('CloseAll');