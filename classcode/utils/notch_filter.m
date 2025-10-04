function [b,a] = notch_filter(fs, f_notch, Q_factor)
    % 陷波滤波器，专门滤除特定频率
    %
    % 输入:
    %   signal: 输入信号
    %   fs: 采样率
    %   f_notch: 陷波频率
    %   Q_factor: 品质因子（默认10，值越大带宽越窄）
    
    if nargin < 4
        Q_factor = 10;
    end
    
    % 计算陷波滤波器参数
    w0 = 2 * pi * f_notch / fs;  % 归一化角频率
    bw = w0 / Q_factor;          % 带宽
    
    % 陷波滤波器系数
    r = 1 - bw/2;
    K = (1 - 2*r*cos(w0) + r^2) / (2 - 2*cos(w0));
    
    % 滤波器系数
    b = K * [1, -2*cos(w0), 1];
    a = [1, -2*r*cos(w0), r^2];
    
    
    % 显示结果
%     visualize_notch_filter(signal, filtered_signal, fs, f_notch, b, a);
end