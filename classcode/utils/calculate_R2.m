function R2 = calculate_R2(y_true, y_pred)
    % y_true: 原始信号
    % y_pred: 拟合信号
    
    % 计算总平方和 (SST)
    SST = sum((y_true - mean(y_true)).^2);
    
    % 计算残差平方和 (SSE)
    SSE = sum((y_true - y_pred).^2);
    
    % 计算R²
    R2 = 1 - SSE/SST;
end
