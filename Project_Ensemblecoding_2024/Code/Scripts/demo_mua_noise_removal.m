% DEMO_MUA_NOISE_REMOVAL
% 演示如何使用 NeuroQC 去除 MUA 信号中的 100Hz 周期性噪声

clear; clc; close all;

%% 1. 生成模拟数据 (Synthetic MUA Data)
fs = 500;          % 1 kHz 采样率
T = 0.242;              % 2 seconds
t = (0:1/fs:T-1/fs);




%% 2. 使用 NeuroQC 处理


qc = NeuroQC.Analyzer(EpochDB.Data, EpochDB.Meta, fs, t*1000);

% 绘制处理前的一个样本
figure('Color','w', 'Name', 'Before vs After');
plot(t, squmean(qc.Data(:,46,:),1), 'r');
title('Before: MUA + 100Hz Noise');
xlabel('Time (s)'); ylabel('Amp');
hold on;

% 执行噪声去除
fprintf('执行 100Hz 噪声去除...\n');
qc.remove_periodic_noise('TargetFreq', 50, 'Bandwidth', 4);
plot(t, squmean(qc.Data(:,46,:),1), 'b');
%% 3. 结果对比
subplot(3,1,2);
plot(t, squmean(qc.Data(:,46,:),1), 'b');
title('After: Cleaned MUA (Spectral Interpolation)');
xlabel('Time (s)'); ylabel('Amp');
grid on;





fprintf('Demo 完成。\n');
