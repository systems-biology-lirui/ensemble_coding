function draw_circles()
    maxR = 500; % 大圆的半径
    circleR = 100; % 小圆的半径
    numCircles = 8; % 需要放置的小圆数量
    centerX = 0; % 大圆的中心x坐标
    centerY = 0; % 大圆的中心y坐标
    
    circles = zeros(numCircles, 3); % 存储圆心坐标和半径，3列分别代表x, y, r
    
    for i = 1:numCircles
        % 随机生成圆心坐标
        angle = 2 * pi * rand();
        x = centerX + (maxR - circleR) * cos(angle);
        y = centerY + (maxR - circleR) * sin(angle);
        
        % 检查是否与已有圆重叠
        overlap = true;
        while overlap
            overlap = any(sqrt(sum((circles(1:i-1, 1:2) - [x, y]).^2, 2)) < (circleR * 2));
            if overlap
                % 如果重叠，重新生成圆心坐标
                angle = 2 * pi * rand();
                x = centerX + (maxR - circleR) * cos(angle);
                y = centerY + (maxR - circleR) * sin(angle);
            end
        end
        
        % 存储圆心坐标和半径
        circles(i, :) = [x, y, circleR];
    end
    
    % 可视化结果
    figure;
    hold on;
    viscircles([centerX, centerY], maxR, 'r'); % 画大圆
    for i = 1:numCircles
        viscircles(circles(i, 1:2), circles(i, 3), 'b'); % 画小圆
    end
    hold off;
end
