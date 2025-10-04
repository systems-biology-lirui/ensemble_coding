import numpy as np
from scipy.signal import convolve2d
from numpy.fft import fft2, ifft2, fftshift

# 参数设置
k = 0.5  # 波数，控制Gabor函数的频率
theta = np.pi/4  # 方向，以弧度为单位
sigma = 3.0  # 标准差，控制Gabor函数的宽度
Lx = 6 * sigma  # Gabor函数的长度
Ly = Lx

# 创建网格
x = np.linspace(-Lx/2, Lx/2, int(Lx))
y = np.linspace(-Ly/2, Ly/2, int(Ly))
[X, Y] = np.meshgrid(x, y)

# 计算Gabor核
X_theta = X * np.cos(theta) + Y * np.sin(theta)  # 旋转坐标轴
Y_theta = -X * np.sin(theta) + Y * np.cos(theta)

gabor_real = np.exp(-(X_theta**2 + Y_theta**2) / (2 * sigma**2)) * np.cos(2 * np.pi * k * X_theta)

# 使用傅里叶变换来确保Gabor核是带限的
gabor_fft = fftshift(fft2(gabor_real))
gabor_fft_shifted = np.zeros_like(gabor_fft)
gabor_fft_shifted[1:-1, 1:-1] = gabor_fft  # 忽略边界效应

# 通过逆傅里叶变换得到实际空间中的Gabor核
gabor = np.real(ifft2(ifftshift(gabor_fft_shifted)))

# 归一化Gabor核
gabor /= np.sum(gabor) * Lx * Ly

# 显示Gabor核
import matplotlib.pyplot as plt

plt.imshow(gabor, cmap='gray')
plt.title('Gabor Filter')
plt.show()