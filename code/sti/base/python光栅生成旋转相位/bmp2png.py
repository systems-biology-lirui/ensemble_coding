from PIL import Image
import os

# 设置BMP图片的路径
bmp_image_path = r'D:\Desktop\picture\0000000002.bmp'

# 读取BMP图片
img = Image.open(bmp_image_path)

# 构建PNG图片的保存路径，通常PNG格式的文件扩展名是'.png'
png_image_path = os.path.splitext(bmp_image_path)[0] + '.png'

# 保存图片为PNG格式
img.save(png_image_path, 'PNG')

print(f'图片已转换为PNG格式并保存在：{png_image_path}')