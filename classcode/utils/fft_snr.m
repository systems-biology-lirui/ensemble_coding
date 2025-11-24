function snr_spectrum = fft_snr(power_spectrum, freqs, noise_win_hz, noise_excl_hz)
% CALCULATE_SNR_SPECTRUM - 将功率谱转换为信噪比(SNR)谱
%
% 语法:
%   snr_spectrum = calculate_snr_spectrum(power_spectrum, freqs)
%   snr_spectrum = calculate_snr_spectrum(power_spectrum, freqs, noise_win_hz, noise_excl_hz)
%
% 描述:
%   此函数将一个三维的功率谱矩阵（trials × channels × frequencies）转换为
%   一个同样维度的SNR谱矩阵。对于每个频率点，SNR的计算方法为：
%   SNR = (该频率点的功率) / (邻近频带的平均功率)
%
%   邻近频带（噪声频带）被定义为目标频率两侧一定范围（如2Hz）内，但又
%   排除掉紧邻目标频率的一个小范围（如0.25Hz）的频率。
%
% 输入参数:
%   power_spectrum - 三维矩阵 (trials × channels × frequencies)。
%                    输入的功率谱数据。
%
%   freqs            - 一维向量。
%                    与 power_spectrum 的第三维对应的频率轴。
%
%   noise_win_hz     - (可选) 数值，定义噪声估计的窗口大小（单位Hz）。
%                      例如，2 表示在目标频率两侧2Hz范围内寻找噪声。
%                      默认值为 2。
%
%   noise_excl_hz    - (可选) 数值，定义从噪声估计中排除的窗口大小（单位Hz）。
%                      例如，0.25 表示排除目标频率两侧0.25Hz范围内的点。
%                      默认值为 0.25。
%
% 输出参数:
%   snr_spectrum     - 三维矩阵 (trials × channels × frequencies)。
%                    计算得到的SNR谱。如果某个频率点找不到有效的噪声邻居
%                    （例如在频谱边缘），其SNR值将被设为NaN。
%
% 示例:
%   % 1. 创建模拟数据
%   n_trials = 10;
%   n_channels = 5;
%   freqs = 0:0.1:40; % 频率从0到40Hz，分辨率0.1Hz
%   n_freqs = length(freqs);
%   
%   % 创建随机背景噪声
%   power_data = rand(n_trials, n_channels, n_freqs) * 0.5 + 1./freqs;
%   
%   % 在10Hz处注入一个信号峰值
%   [~, sig_idx] = min(abs(freqs - 10));
%   power_data(:, :, sig_idx) = power_data(:, :, sig_idx) * 10;
%   
%   % 2. 调用函数计算SNR
%   snr_data = calculate_snr_spectrum(power_data, freqs);
%   
%   % 3. 可视化结果（以第一个trial和第一个channel为例）
%   figure;
%   subplot(2,1,1);
%   plot(freqs, squeeze(power_data(1,1,:)));
%   title('原始功率谱 (Trial 1, Channel 1)');
%   xlabel('频率 (Hz)'); ylabel('功率');
%   
%   subplot(2,1,2);
%   plot(freqs, squeeze(snr_data(1,1,:)));
%   title('SNR谱 (Trial 1, Channel 1)');
%   xlabel('频率 (Hz)'); ylabel('SNR');

% --- 参数检查和默认值设定 ---
if nargin < 3
    noise_win_hz = 2;
end
if nargin < 4
    noise_excl_hz = 0.25;
end

% 获取输入矩阵的维度
[n_trials, n_channels, n_freqs] = size(power_spectrum);

% 检查频率向量的长度是否与数据匹配
if n_freqs ~= length(freqs)
    error('频率向量 `freqs` 的长度必须与 `power_spectrum` 的第三维匹配。');
end

% --- 主计算流程 ---

% 预分配输出矩阵，用NaN填充
snr_spectrum = nan(n_trials, n_channels, n_freqs);

% 遍历每个trial和每个channel
for i_trial = 1:n_trials
    for i_chan = 1:n_channels
        
        % 提取当前trial和channel的频谱（一个一维向量）
        current_spectrum = squeeze(power_spectrum(i_trial, i_chan, :));
        
        % 遍历该频谱上的每一个频率点
        for i_freq = 1:n_freqs
            
            target_freq = freqs(i_freq);
            
            % --- 寻找噪声邻居的索引 ---
            % 计算所有频率点与目标频率的绝对差值
            freq_diff = abs(freqs - target_freq);
            
            % 创建一个逻辑掩码 (logical mask) 来识别噪声邻居
            % 条件1: 在 `noise_win_hz` (例如2Hz) 范围内
            % 条件2: 在 `noise_excl_hz` (例如0.25Hz) 范围外
            noise_mask = (freq_diff <= noise_win_hz) & (freq_diff > noise_excl_hz);
            
            % --- 计算信号和噪声 ---
            % 信号值就是当前频率点的值
            signal_power = current_spectrum(i_freq);
            
            % 噪声值是所有噪声邻居的均值
            % 使用逻辑掩码从频谱中选择噪声点
            noise_power_values = current_spectrum(noise_mask);
            
            % 计算均值。如果 noise_power_values 为空（在频谱边缘可能发生），
            % mean() 会返回NaN，这正是我们想要的结果。
            noise_mean = mean(noise_power_values);
            
            % --- 计算并存储SNR ---
            snr_spectrum(i_trial, i_chan, i_freq) = signal_power / noise_mean;
            
        end % 频率循环结束
    end % channel循环结束
end % trial循环结束

end