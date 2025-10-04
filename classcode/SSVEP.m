%% SSVEP信号
%% ---------------------- 提取trial，使用向量化操作-------------- %%

% ssvep的凸显
% 有两种想法，一种是按照实际的信号来，
% 一种是让前一张图片也相同，进行每四张的拼接，这样不合理，会引入前一张的ssvep
% 或者可以选择相同数量的进行拼接，让前一张图片随机但是每个ori的数量一致。

% 向量化操作，
% 匿名函数，@（循环变量），操作，变量范围

SSVEP_data = cell(1, 11); % 初始化 SSVEP_data
conditionIdx = [1:2:17, 19, 20]; % 19blank,20-random


for day = 1:length(Days)
    for session = 1:size(All_data{1, day}, 2)
        % 提取所有条件的索引
        trialconditions = conditionIdx;
        
        idx_cluster = arrayfun(@(x) find(Meta_data{day}{session}{3} == x), trialconditions, 'UniformOutput', false);
        
        % 提取数据
        sessiondata = cellfun(@(idx) All_data{day}{session}(idx, :, :), idx_cluster, 'UniformOutput', false);

        % 数据拼接
        SSVEP_data = cellfun(@(x, y) [x; y], SSVEP_data, sessiondata, 'UniformOutput', false);
    end
    fprintf('Processed Day: %d\n', day);
end


%% -----------------------------频谱计算----------------------------- %%

% 先频谱后计算，是因为我们几乎没有不变的序列
% 定义信号参数
% 选择1600个点是因为让6，25hz落在点上

Fs = 500;                   
N = 1600;                   
f = Fs * (0:N/2) / N;  
fftplot = cell(1, 11);      

% 汉宁窗
hanwindow = hann(N)';          % 行向量便于广播

for block = 1:11
    % trials × coils × time
    data_block = SSVEP_data{block};
    num_trials = size(data_block, 1);
    num_coils = size(data_block, 2);
    
    % 时间点
    signals = data_block(:, :, 41:40+N); % 维度：trials × coils × N
    
    % 重组+fft
    signals_reshaped = reshape(permute(signals, [2 1 3]), [], N);
    [P1_3d,Phase_3d] = fftanalyse(signals_reshaped,N,hanwindow,num_trials,num_coils,block);
    fftplot{block} = {P1_3d,Phase_3d};
end




%% ---------------------------显著性计算---------------------------------%%

target_freq = 6.25;
[~, idx] = min(abs(f - target_freq));


noise_range = 1.0;
noise_mask = (f >= (target_freq - noise_range)) & (f <= (target_freq + noise_range));
noise_mask(idx) = false;

fft_p_predata = squeeze(fftplot{5}(:,63,:));
[~, p_value] = ttest2(fft_p_predata(:,idx), mean(fft_p_predata(:,noise_mask),2));
is_significant_stats = p_value < 0.05;
fprintf('6.25Hz显著性: p = %.4f, 显著: %s\n', p_value, string(is_significant_stats));



%% --------------------------d-prime------------------------------------%%




%% ------------------------------function-------------------------------%%
function  [P1_3d,Phase_3d] = fftanalyse(data,N, hanwindow,num_trials,num_coils,block)
    signals_detrended = detrend(data')'; % 按列去趋势
    % signals_detrended =data; 不去趋势会让低频飞起来
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
    P1_3d = permute(reshape(P1, num_coils, num_trials, []), [2 1 3]);
    Phase_3d = permute(reshape(Phase, num_coils, num_trials, []), [2 1 3]);
    
    fprintf('Processed Block: %d\n', block);
end