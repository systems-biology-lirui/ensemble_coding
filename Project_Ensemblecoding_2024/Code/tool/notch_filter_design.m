function [b, a] = notch_filter_design(Fs, F0, Bandwidth)
% F0: 陷波中心频率
% Bandwidth: -3dB 带宽 (例如 2Hz 或 4Hz)
% Q factor 计算
Q = F0 / Bandwidth;
% 使用 iirnotch 设计二阶 IIR 陷波器 (比手动计算系数更稳健)
% 注意：filtfilt 会使阶数翻倍，二阶变成四阶，通常足够
d = designfilt('bandstopiir', 'FilterOrder', 2, ...
    'HalfPowerFrequency1', F0 - Bandwidth/2, ...
    'HalfPowerFrequency2', F0 + Bandwidth/2, ...
    'DesignMethod', 'butter', 'SampleRate', Fs);
[b, a] = tf(d);
end