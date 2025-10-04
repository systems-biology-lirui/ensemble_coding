import numpy as np
import matplotlib.pyplot as plt
from scipy.ndimage import rotate

# 设置光栅的基本参数
rows, cols = 256, 256  # 图像的行和列
frequency = 0.047  # 正弦波的频率

# 创建一个全为0的矩阵作为光栅的背景
grating = np.zeros((rows, cols))

# 设置相位偏移量，可以根据需要修改这个值
phase_shift = 0

# 计算正弦波的周期数，确保至少有一个半周期在图像内
num_cycles = 1.5

# 生成正弦波光栅，添加相位偏移
for i in range(rows):
    for j in range(cols):
        # 正弦波的周期性变化，添加相位偏移
        grating[i, j] = 0.5 * (1 + np.sin(2 * np.pi * frequency * i + phase_shift))
plt.imshow(grating, cmap='gray') 
plt.savefig(f'sine_grating_{phase_shift}.png', cmap='gray', bbox_inches='tight', pad_inches=0)

# 改变相位并重新生成光栅
phase_shift += np.pi / 4  # 增加相位偏移量，例如增加90度
grating = np.zeros((rows, cols))  # 重置光栅矩阵
for i in range(rows):
    for j in range(cols):
        grating[i, j] = 0.5 * (1 + np.sin(2 * np.pi * frequency * i  + phase_shift))
plt.imshow(grating, cmap='gray') 
plt.savefig(f'sine_grating_{phase_shift}.png', cmap='gray', bbox_inches='tight', pad_inches=0)

