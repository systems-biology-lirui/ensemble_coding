% 定义Gabor滤波器的参数
theta = pi/4; % 滤波器的方向，以弧度为单位
lambda = 10;  % 波长
gamma = 0.5;  % 空间频率的缩放因子
sigma = lambda/2/pi; % 高斯包络的标准差

% 使用fspecial创建Gabor核
gaborKernel = fspecial('gaussian', 9, sigma);

% 旋转Gabor核以匹配所需的方向
gaborKernel = imrotate(gaborKernel, theta*180/pi, 'bilinear', 'crop');

% 创建一个正弦Gabor滤波器
% 首先创建一个与Gabor核大小相同的矩阵，填充正弦波
[X, Y] = meshgrid(-size(gaborKernel)+1:size(gaborKernel)-1);
gaborFilter = cos(2*pi*X/lambda);

% 将正弦波与Gabor核相乘
gaborFilter = gaborFilter .* gaborKernel;

% 现在gaborFilter是一个正弦Gabor滤波器
% 你可以将其应用到图像上，例如：
% image = imread('your_image.jpg'); % 读取图像
% filteredImage = imfilter(image, gaborFilter, 'replicate');

% 显示Gabor滤波器
imshow(gaborFilter, []);