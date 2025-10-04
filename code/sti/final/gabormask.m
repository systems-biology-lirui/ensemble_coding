fifi = zeros(60,60,6,180);
imggray = 221/255 * ones(60, 60);

for o = 1:180
    for p = 1:6
        img = im2gray(finalimg(:,:,:,p,o));
        bind = 5;
        imggray(bind+1:end-bind, bind+1:end-bind) = img;
        [X, Y] = meshgrid(1:60, 1:60);
        centerX = 30;
        centerY = 30;
        radius = 23; % 圆的半径
        mask = (X - centerX).^2 + (Y - centerY).^2 <= radius^2;
        masked_img = imggray;
        masked_img(~mask) = 0;

        % 对非圆形区域应用模糊处理
        % 使用wiener2函数进行模糊处理
        blurred_img = wiener2(imggray, [30 30], 0.1);

        % 将模糊处理后的图像与原始图像合并
        result_img = blurred_img;
        result_img(mask) = masked_img(mask);
        fifi(:,:,p,o) = result_img;
    end
end
