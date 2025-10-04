function  [P1_3d,Phase_3d,f] = SSVEP_fftanalyse(data)
    % SSVEP_fftanalyse 对多维数据计算频谱
    % 去趋势是为了降低低频段的赋值
    % 
    % 输入参数:
    %   data - 三维数组，维度为 (trials, channels, time)
    %   
    % 固定参数：
    %   Fs - 采样频率 (Hz)
    %   N - 采用trial中1600个点进行，有利于6，25hz位于频谱点上
    %   f - 频谱结果的频率索引
    %
    % 输出:
    %   P1_3d - 频谱赋值结果
    %   Phase_3d - 频谱相位结果


    Fs = 500;
    N = 1600;
    f = Fs * (0:N/2) / N;
    
    % 汉宁窗
    hanwindow = hann(N)';

    num_trials = size(data, 1);
    num_coils = size(data, 2);
    data = data(:, :, 41:(40+N)); 
    data = reshape(permute(data, [2 1 3]), [], N);

    % 按列去趋势
    signals_detrended = detrend(data')'; 

    signals_windowed = signals_detrended .* hanwindow;  % 广播乘窗
    
    % 向量化FFT计算
    Y = fft(signals_windowed, [], 2);     % 按行计算FFT
    P2 = abs(Y) / N;                      % 双侧频谱幅值
    P1 = P2(:, 1:N/2+1);                  % 单侧频谱
    P1(:, 2:end-1) = 2 * P1(:, 2:end-1);  % 调整幅值
    
    % 计算相位谱
    Phase = angle(Y);                      % 获取复数相位（弧度制）
    Phase = Phase(:, 1:N/2+1);             % 单侧相位
    
    % 将结果重塑为三维数组 (trials × coils × frequency)
    P1_3d = single(permute(reshape(P1, num_coils, num_trials, []), [2 1 3]));
    Phase_3d = single(permute(reshape(Phase, num_coils, num_trials, []), [2 1 3]));


end