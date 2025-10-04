file_path = 'D:\Desktop\mt\';
for i = 1:160
    if i <100
        num1 =  num2str(i, '%03d');
    else
        num1 = num2str(i);
    end
    filename = sprintf('0000000%s.bmp', num1);
    img = imread(fullfile(file_path, filename));
    colormap = info.Colormap;
    %img = uint8(img);

% 保存RGB图像

    savename = sprintf('0000000%s.bmp', num1);
    full = fullfile('D:\Desktop\mt\2', savename);
    imwrite(img, colormap, full);
end


% file_path = 'D:\Desktop\mt\';
% num1 = num2str(30, '%03d');
% filename = sprintf('0000000%s.bmp', num1);
% img = imread(fullfile(file_path, filename));
% img = uint8(img);
% 
% imwrite(img,colormap,'D:\Desktop\mt\2\0000000030.bmp')
