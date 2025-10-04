
from PIL import Image
import os

image_path = r'D:\Desktop\picture\0000000002.png'
img = Image.open(image_path)

# 保存原始图片
original_image_path = os.path.join(r'D:\Desktop\picture\rotate2', r'0000000002.png')
img.save(original_image_path)

for angle in range(1, 181):
    # 旋转图片，使用expand=True避免裁剪
    rotated_img = img.rotate(angle, expand=True)
    
    # 构建新的文件名，包含旋转的角度
    rotated_image_filename = f'rotated_{angle}.png'
    rotated_image_path = os.path.join(r'D:\Desktop\picture\rotate2', rotated_image_filename)
    
    # 保存旋转后的图片，使用PNG格式
    rotated_img.save(rotated_image_path, 'PNG')

print('图片旋转完成。')