from PIL import Image, ImageFilter
import os

# 设置你的图片文件夹路径
folder_path = 'D:\Desktop\picture'

# 遍历文件夹中的所有文件
for filename in os.listdir(folder_path):
    # 检查文件扩展名是否为图片格式
    if filename.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.gif')):
        # 构建完整的文件路径
        file_path = os.path.join(folder_path, filename)
        
        # 打开图片
        with Image.open(file_path) as img:
            # 计算新的尺寸，这里是原来的一半
            new_width = img.width // 2
            new_height = img.height // 2
            # 缩放图片，使用 Image.LANCZOS 作为重采样滤镜
            img_resized = img.resize((new_width, new_height), Image.LANCZOS)
            
            # 保存缩放后的图片，可以选择覆盖原图或保存为新文件
            # img_resized.save(file_path)  # 覆盖原图
            # 或者保存为新文件
            new_file_path = os.path.join(folder_path, f'small_{filename}')
            img_resized.save(new_file_path)

print('图片缩放完成。')