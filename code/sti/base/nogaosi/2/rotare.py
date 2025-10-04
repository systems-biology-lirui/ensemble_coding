import numpy as np
import matplotlib.pyplot as plt
from scipy.ndimage import rotate

# 设置光栅的基本参数
rows, cols = 256, 256  # 图像的行和列
frequency = 0.047  # 正弦波的频率

# 创建一个全为0的矩阵作为光栅的背景
grating = np.zeros((rows, cols))

# 计算正弦波的周期数，确保至少有一个半周期在图像内
num_cycles = 1.5

# 生成正弦波光栅

phase = np.pi 
for i in range(rows):
        for j in range(cols):
        # 正弦波的周期性变化

                grating[i, j] = 0.5 * (1 + np.sin(2 * np.pi * frequency * i +phase))

for angle in range(0, 181, 1):  # 从0度到360度，每次增加1度
        rotated_grating = rotate(grating, angle, reshape=False, mode='nearest', cval=0.0)
        plt.imshow(rotated_grating, cmap='gray')  # 使用灰度色图显示旋转后的光栅
        plt.axis('off')  # 不显示坐标轴
        plt.savefig(f'sine_grating_{angle}_{180}.png', cmap='gray', bbox_inches='tight', pad_inches=0)
        plt.close()  # 关闭图像显示窗口