function rotatedPoints = rotatePoints(points, angle)
    % 检查输入参数
    if size(points, 2) ~= 2
        error('Points must be a matrix with two columns.');
    end
    
    % 将角度转换为弧度
    angleInRadians = angle * (pi / 180);
    
    % 初始化旋转后的点坐标矩阵
    numPoints = size(points, 1);
    rotatedPoints = zeros(numPoints, 2);
    
    % 对每个点应用旋转矩阵
    for i = 1:numPoints
        % 提取第i个点的坐标
        point = points(i, :);
        
        rotationMatrix = [cos(angleInRadians(i,:)), -sin(angleInRadians(i,:));
                       sin(angleInRadians(i,:)),  cos(angleInRadians(i,:))];
        
        % 应用旋转矩阵计算新坐标
        newCoordinates = rotationMatrix * point';
        
        % 四舍五入到最近的整数
        rotatedPoints(i, :) = round(newCoordinates);
    end
end