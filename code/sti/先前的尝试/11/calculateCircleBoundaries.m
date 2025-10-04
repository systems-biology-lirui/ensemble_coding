function [rects] = calculateCircleBoundaries(centers, radius)
    % 检查输入参数
    if size(centers, 2) ~= 2
        error('Centers must be a matrix with two columns.');
    end
    
    % 初始化边界数组
    numCircles = size(centers, 1);
    left = zeros(numCircles, 1);
    top = zeros(numCircles, 1);
    right = zeros(numCircles, 1);
    bottom = zeros(numCircles, 1);
    
    % 计算每个圆的边界坐标
    for i = 1:numCircles
        centerX = centers(i, 1);
        centerY = centers(i, 2);
        
        left(i) = centerX - radius +960;
        top(i) = 540-(centerY + radius) ;
        right(i) = centerX + radius +960;
        bottom(i) = 540-(centerY - radius);
    end
    rects = cat(2, left, top, right, bottom);
    rects = rects.';
end



