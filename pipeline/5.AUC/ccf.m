
signal = MGv(5).Data(:,selected_coil_final,:);
[nRepeats,nNeurons,nTimePoints]  =size(signal);
% --- 2. 计算所有配对的互相关信息 ---

% 初始化存储结果的矩阵
peak_corr_matrix = eye(nNeurons); % 对角线为1（自身相关性）
peak_lag_matrix = zeros(nNeurons);  % 对角线为0（自身延迟）

% 使用waitbar来显示进度，因为这可能需要一些时间
h = waitbar(0, '正在计算所有神经元配对的互相关...');

max_lag = nTimePoints - 1; % xcorr的最大延迟

for i = 1:nNeurons
    for j = (i+1):nNeurons % 只计算上三角，避免重复
        
        % 提取神经元i和j的所有trials信号
        neuron_i_signals = squeeze(signal(:, i, :));
        neuron_j_signals = squeeze(signal(:, j, :));
        
        % 计算跨trials的平均互相关
        % 'coeff'标准化模式
        [mean_corr, lags] = xcorr(mean(neuron_i_signals, 1), mean(neuron_j_signals, 1), 'coeff');
        
        % --- 另一种更稳健的方法：先计算每个trial的xcorr再平均 ---
        % all_correlations = [];
        % for r = 1:nRepeats
        %     [c, lags] = xcorr(neuron_i_signals(r, :), neuron_j_signals(r, :), 'coeff');
        %     all_correlations(:, r) = c;
        % end
        % mean_corr = mean(all_correlations, 2);
        % -----------------------------------------------------------
        
        % 找到峰值和对应的延迟
        [peak_val, max_idx] = max(mean_corr);
        peak_lag = lags(max_idx);
        R = corrcoef(squmean(neuron_i_signals,1), squmean(neuron_j_signals,1));
        R2_matrix(j,i) = R(1,2);
        % 填充结果矩阵 (利用对称性)
        peak_corr_matrix(i, j) = peak_val;
        peak_corr_matrix(j, i) = peak_val; % 相关性是对称的
        
        peak_lag_matrix(i, j) = peak_lag;
        peak_lag_matrix(j, i) = -peak_lag; % 延迟是反对称的 (如果i领先j，则j落后i)
    end
    waitbar(i / nNeurons, h); % 更新进度条
end
close(h); % 关闭进度条
disp('计算完成！');
%% --- 3. 可视化结果 ---

figure('Position', [100, 100, 1200, 500]); % 创建一个大一点的窗口

% 子图1: 峰值相关性矩阵
subplot(1, 3, 1);
imagesc(peak_corr_matrix);
axis square; % 让坐标轴成正方形
title('峰值相关性矩阵 (Peak Correlation Matrix)', 'FontSize', 14);
xlabel('神经元 ID', 'FontSize', 12);
ylabel('神经元 ID', 'FontSize', 12);
colorbar; % 显示颜色条
caxis([0.7,1])
% 子图2: 峰值延迟矩阵
subplot(1, 3, 2);
imagesc(peak_lag_matrix);
axis square;
title('峰值延迟矩阵 (Peak Lag Matrix)', 'FontSize', 14);
xlabel('神经元 ID', 'FontSize', 12);
ylabel('神经元 ID', 'FontSize', 12);
colorbar;

subplot(1, 3, 3);
imagesc(R2_matrix);
axis square;
title('神经元相似性矩阵 (Peak Lag Matrix)', 'FontSize', 14);
xlabel('神经元 ID', 'FontSize', 12);
ylabel('神经元 ID', 'FontSize', 12);
colorbar;
caxis([0.7,1])