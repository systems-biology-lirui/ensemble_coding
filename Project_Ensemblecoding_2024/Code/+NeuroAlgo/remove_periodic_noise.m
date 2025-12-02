function data_clean = remove_periodic_noise(data, fs, target_freq, bw)
% REMOVE_PERIODIC_NOISE 去除指定频率的周期性噪声 (谱插值法)
% 适用于 MUA/LFP 信号，比陷波滤波器 (Notch) 引起的振铃更小
%
% 输入:
%   data:        [nCh, nTime] 或 [nTrials, nCh, nTime] 数据矩阵
%   fs:          采样率 (Hz)
%   target_freq: 目标频率 (Hz), 例如 100
%   bw:          带宽 (Hz), 例如 2 (即 99-101Hz)
%
% 输出:
%   data_clean:  去噪后的数据
%
% 原理:
%   将信号转换到频域，将目标频率附近的幅度替换为周围频率的平均值(插值)，
%   然后转换回时域。这种方法能有效去除单一频率的正弦干扰，且保留相位信息。

    if nargin < 4, bw = 2; end

    % 记录原始维度
    orig_size = size(data);
    
    % 展平为 [N, nTime]
    nTime = orig_size(end);
    X = reshape(data, [], nTime);
    
    % 1. FFT
    % 使用 nextpow2 优化速度，或者直接用 nTime (保持频率对应关系最简单)
    N = nTime; 
    F = fft(X, N, 2);
    freqs = (0:N-1) * (fs / N);
    
    % 2. 构造频率掩码 (Mask)
    % 只需要处理正频率部分 (0 ~ fs/2)，负频率部分由对称性处理
    % 但为了简单，直接处理双边频谱
    
    % 找到目标频率范围 indices
    % 目标: 100Hz
    idx_target = abs(freqs - target_freq) <= bw/2 | ...
                 abs(freqs - (fs - target_freq)) <= bw/2;
             
    % 3. 谱插值 (Spectral Interpolation)
    % 对于每个被 mask 的点，用它两边未被 mask 的点的均值代替
    % 简单起见，我们将幅度置为邻域的插值
    
    F_clean = F;
    
    % 我们需要遍历每一行吗？可以用矩阵操作加速
    % 找到需要处理的列索引
    cols_to_fix = find(idx_target);
    
    if isempty(cols_to_fix)
        warning('未找到目标频率 %.1f Hz (Fs=%d)', target_freq, fs);
        data_clean = data;
        return;
    end
    
    % 定义邻域宽度 (用于计算平均值的窗口)
    neighbor_width = round(2 * (N/fs)); % 约 2Hz 的外围
    if neighbor_width < 1, neighbor_width = 1; end
    
    for c = cols_to_fix
        % 寻找左邻域和右邻域 (跳过 target 区域)
        % 这是一个简化的插值：直接用该频率点 左右 neighbor_width 处的非噪声点的均值
        
        % 这里的逻辑比较复杂，为了效率，我们采用 "Amplitude Scaling"
        % 将该频率点的幅度设为 0 (强行 Notch) 或者 设为邻居均值
        % 设为邻居均值更自然
        
        % 左边参考点
        left_ref = max(1, c - neighbor_width*2);
        while idx_target(left_ref) && left_ref > 1
            left_ref = left_ref - 1;
        end
        
        % 右边参考点
        right_ref = min(N, c + neighbor_width*2);
        while idx_target(right_ref) && right_ref < N
            right_ref = right_ref + 1;
        end
        
        % 执行插值 (复数插值可能涉及相位，比较危险。通常只插值幅度，保留相位? 
        % 不，噪声的相位就是噪声。我们希望用“背景信号”填补)
        % 简单的做法：设为两边参考点的复数平均
        F_clean(:, c) = (F(:, left_ref) + F(:, right_ref)) / 2;
    end
    
    % 4. IFFT
    X_clean = ifft(F_clean, N, 2, 'symmetric');
    
    % 5. MUA 特殊处理: 非负性约束 (Optional)
    % 如果原始数据是 MUA (非负)，去噪后可能会出现微小的负值振铃
    % 我们可以将其截断为 0，或者不做处理(保持均值)
    % 这里为了通用性，不做强制截断，交给用户决定
    
    data_clean = reshape(X_clean, orig_size);
end
