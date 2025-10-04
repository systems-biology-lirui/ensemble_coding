%% -----------------------第二批次----------------------------------%%
% 在学习一下这种提取的想法，一个标签排布==标签序列就可以得到每个位置每个标签的逻辑

fitting_data = cell(15, 11);  % 15 locations × 11 conditions   
conditionIdx = [1:2:17, 19, 20];  % 9ori +blank +random
locations = 1:15;  % 13location + SC +blank 
Days = 16:18; 


for day = 1:length(Days)
    [~, Meta_data,All_data] ...
    = load_data(Days(day),Conditions,Type,sessionIdx,pattern);
    for session = 1:size(All_data{1}, 2)
        % 提取数据
        cond_labels = Meta_data{1}{session}{3};      % 1×N
        loc_labels = Meta_data{1}{session}{2}(1,:);  % 1×N
        session_data = All_data{1}{session};          % N×...
        num_trials = size(session_data,1);
        
        % 维度对齐
        loc_mask = (loc_labels == locations') ...     % 生成14×N矩阵
            & ~isnan(loc_labels);                      % 处理可能的NaN值
        cond_mask = (cond_labels == conditionIdx') ... % 生成11×N矩阵
            & ~isnan(cond_labels);
        
        % 三维逻辑索引（15×11×N）
        combined_mask = permute(loc_mask, [1,3,2]) ... % 15×1×N
            & permute(cond_mask, [3,1,2]);             % 1×11×N
        
        % 按location和condition聚合数据
        fitting_data = cellfun(@(cell_data, mask) ...
            [cell_data; session_data(squeeze(mask),:,:)], ...
            fitting_data, num2cell(combined_mask,3), ...
            'UniformOutput', false);
    end
    fprintf('Processed Day: %d\n', day);
    clear Meta_data All_data
end

%% ----------------------------叠加信号的SSVEP--------------------------%%
Fs = 500;                   
N = 1600;                   
f = Fs * (0:N/2) / N;  
fftplot = cell(1, 11);      

% 汉宁窗
hanwindow = hann(N)';          % 行向量便于广播

for block = [5,11]
    % trials × coils × time
    data_block = [];
    for location = 1:12
        data_block = cat(1,data_block,fitting_data{location,block}(:,:,:));
        fitting_data{location,block} = [];
    end
    % data_block = data_block/12;
    % ECpatch_data{block} = data_block;
    num_trials = size(data_block, 1);
    num_coils = size(data_block, 2);
    
    % 时间点
    signals = data_block(:, :, 41:40+N); % 维度：trials × coils × N
    
    % 重组+fft
    signals_reshaped = reshape(permute(signals, [2 1 3]), [], N);
    [P1_3d,Phase_3d] = fftanalyse(signals_reshaped,N,hanwindow,num_trials,num_coils,block);
    fftplot{block} = {P1_3d,Phase_3d};
end



%% ----------------------------trial水平拟合----------------------------%%
% EC可以从SSVEP的方法来提取
% 拟合效果比较差
patchdata = zeros(96,1640,12);
for location = 1:12
    patchdata(:,:,location) = squeeze(mean(fitting_data{location,5},1));
end
EC_data = squeeze(mean(SSVEP_data{5},1));
for coil = 1:96
    model = fitlm(squeeze(patchdata(coil,:,:)),EC_data(coil,:)');
    R2_values(coil) = model.Rsquared.Ordinary;
    locationweights(coil, :) = model.Coefficients.Estimate(2:end);
end
%% ---------------------------pic水平拟合--------------------------------%%



%% ---------------------------拟合，残差的SSVEP---------------------------%%
k_fitting_data = zeros(120,96,1640);
k_fitting_data_random = zeros(120,96,1640);
for location = 1:12
    for coil = 1:96
        for trial = 1:120
            k_fitting_data(trial,coil,:) = k_fitting_data(trial,coil,:)+locationweights(coil,location)*fitting_data{location,5}(trial,coil,:);
            k_fitting_data_random(trial,coil,:) = k_fitting_data_random(trial,coil,:)+locationweights(coil,location)*fitting_data{location,11}(trial,coil,:);
        end
    end
end
%%
Fs = 500;                   
N = 1600;                   
f = Fs * (0:N/2) / N;  
fftplot = cell(1, 11);     
hanwindow = hann(N)';  
for block = [5,11]
    if block == 5
        data_block = k_fitting_data;
    else
        data_block = k_fitting_data_random;
    end

    num_trials = size(data_block, 1);
    num_coils = size(data_block, 2);

    % 时间点
    signals = data_block(:, :, 41:40+N); % 维度：trials × coils × N

    % 重组+fft
    signals_reshaped = reshape(permute(signals, [2 1 3]), [], N);
    [P1_3d,Phase_3d] = fftanalyse(signals_reshaped,N,hanwindow,num_trials,num_coils,block);
    fftplot{block} = {P1_3d,Phase_3d};
end

%% ---------------------------function----------------------------------%%
function  [P1_3d,Phase_3d] = fftanalyse(data,N, hanwindow,num_trials,num_coils,block)
    signals_detrended = detrend(data')'; % 按列去趋势
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