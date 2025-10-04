function gaborPatch = createGabor(patchSize, lambda, theta, sigma, phase, contrast, bgColor)
% createGabor - 生成一个Gabor光栅图像
%
% 用法:
%   gaborPatch = createGabor(patchSize, lambda, theta, sigma, phase, contrast, bgColor)
%
% 输入:
%   patchSize - Gabor图像的尺寸 (像素, e.g., 101 for 101x101)
%   lambda    - 正弦波的波长 (像素)
%   theta     - 光栅的朝向 (度, 0=水平, 90=垂直)
%   sigma     - 高斯包络的标准差 (像素), 控制Gabor的大小
%   phase     - 正弦波的相位 (度)
%   contrast  - 对比度 (0 到 1)
%   bgColor   - 背景灰度值 (0 到 255)
%
% 输出:
%   gaborPatch - 一个 patchSize x patchSize 的 uint8 图像矩阵

% 1. 创建网格坐标
center = (patchSize + 1) / 2;
[X, Y] = meshgrid(1:patchSize, 1:patchSize);
X = X - center;
Y = Y - center;

% 2. 将朝向转换为弧度
thetaRad = deg2rad(theta);

% 3. 旋转坐标系
X_theta = X * cos(thetaRad) + Y * sin(thetaRad);
% Y_theta = -X * sin(thetaRad) + Y * cos(thetaRad); % Y_theta is not needed for sine wave

% 4. 创建正弦波光栅
spatialFreq = 1 / lambda;
phaseRad = deg2rad(phase);
sineWave = sin(2 * pi * spatialFreq * X_theta + phaseRad);

% 5. 创建高斯包络
gaussianEnvelope = exp(-(X.^2 + Y.^2) / (2 * sigma^2));

% 6. 将正弦波和高斯包络相乘
gabor = sineWave .* gaussianEnvelope;

% 7. 应用对比度和背景色
% 将 gabor 的范围从 [-1, 1] 映射到 [bgColor - Amp, bgColor + Amp]
amplitude = contrast * bgColor;
gaborPatch = uint8(bgColor + gabor * amplitude);

end