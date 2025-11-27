% step1_process_ssgv.m
clear; clc;
macaque = 'QQ_new';
base_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\02_EpochDatabase\';
save_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\03_ResultData\Temp1\';
if ~exist(save_path, 'dir'), mkdir(save_path); end

fprintf('正在加载 SSGv 数据...\n');
data_ssgv = load(fullfile(base_path, sprintf('%s_SSGv_SSVEP_B_MUA2_Epochs_Avg.mat',macaque)));
meta_ssgv = data_ssgv.EpochDB.Meta;
raw_ssgv  = data_ssgv.EpochDB.Data; 
clear data_ssgv;

[~, nChs, nTime] = size(raw_ssgv);
target_ori_list = 1:18;
n_ori = 18;
n_pat = 6;
n_loc = 12;

% --- 1. 计算 SSGv 内部的最小 Trial 数 ---
valid_ssgv_counts = [];
for o = 1:n_ori
    for p = 1:n_pat
        for l = 1:n_loc
            idx = find(meta_ssgv.Location == l & meta_ssgv.PicID == target_ori_list(o) & meta_ssgv.Pattern == p);
            if ~isempty(idx), valid_ssgv_counts(end+1) = length(idx); end
        end
    end
end
min_trials_ssgv = min(valid_ssgv_counts);
fprintf('SSGv 内部最小 Trial 数: %d\n', min_trials_ssgv);

% --- 2. 计算缩放因子 ---
max_val = max(abs(raw_ssgv(:)));
scale_factor_ssgv = 32000 / double(max_val); 
fprintf('SSGv 缩放因子: %.4f\n', scale_factor_ssgv);

% --- 3. 构建 int16 矩阵 (包含 idx 回退逻辑) ---
Mat_SSGv_int16 = zeros(n_loc, n_ori, n_pat, min_trials_ssgv, nChs, nTime, 'int16');

fprintf('正在重组 SSGv 并转换为 int16...\n');
idx1 = []; % 初始化 idx1，防止第一次循环就为空时报错
% 注意：如果第一次循环就是空的，这里可能会出错。假设数据开头通常是存在的。

for l = 1:n_loc
    for o = 1:n_ori
        for p = 1:n_pat
            idx = find(meta_ssgv.Location == l & ...
                       meta_ssgv.PicID == target_ori_list(o) & ...
                       meta_ssgv.Pattern == p);
            
            % --- 补回的逻辑 ---
            if isempty(idx)
                if isempty(idx1)
                    error('数据的第一个 Condition 为空，无法进行 idx 回退，请检查数据完整性');
                end
                idx = idx1;
            end
            idx1 = idx;
            % ------------------
            
            % 取出数据 -> 缩放 -> 转 int16
            temp_data = raw_ssgv(idx(1:min_trials_ssgv), :, :);
            Mat_SSGv_int16(l, o, p, :, :, :) = int16(temp_data * scale_factor_ssgv);
        end
    end
end

save(fullfile(save_path, 'Preprocessed_SSGv_int16.mat'), ...
    'Mat_SSGv_int16', 'scale_factor_ssgv', 'meta_ssgv', 'min_trials_ssgv', '-v7.3');
fprintf('Step 1 完成: SSGv 已保存。\n');

% step2_process_mgv.m
clearvars -except macaque; clc;

base_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\02_EpochDatabase\';
save_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\03_ResultData\Temp1\';

fprintf('正在加载 MGv 数据...\n');
data_b = load(fullfile(base_path, sprintf('%s_MGv_SSVEP_B_MUA2_Epochs_Avg.mat',macaque)));
data_a = load(fullfile(base_path, sprintf('%s_MGv_SSVEP_A_MUA2_Epochs_Avg.mat',macaque)));

meta_mgv_b = data_b.EpochDB.Meta;
raw_mgv_b  = data_b.EpochDB.Data;
meta_mgv_a = data_a.EpochDB.Meta;
raw_mgv_a  = data_a.EpochDB.Data;
clear data_b data_a;

[~, nChs_b, nTime] = size(raw_mgv_b);
[~, nChs_a, nTime] = size(raw_mgv_a);
nChs = min(nChs_a,nChs_b);
target_ori_list = 1:18;
n_ori = 18;
n_pat = 6;

% --- 1. 计算 MGv 内部最小 Trial 数 ---
valid_mgv_b_counts = [];
valid_mgv_a_counts = [];

for o = 1:n_ori
    for p = 1:n_pat
        idx = find(meta_mgv_b.PicID == target_ori_list(o) & meta_mgv_b.Pattern == p);
        if ~isempty(idx), valid_mgv_b_counts(end+1) = length(idx); end
        
        idx = find(meta_mgv_a.PicID == target_ori_list(o) & meta_mgv_a.Pattern == p);
        if ~isempty(idx), valid_mgv_a_counts(end+1) = length(idx); end
    end
end
min_trials_mgv_b = min(valid_mgv_b_counts);
min_trials_mgv_a = min(valid_mgv_a_counts);

% --- 2. 计算缩放因子 ---
max_val_b = max(abs(raw_mgv_b(:)));
max_val_a = max(abs(raw_mgv_a(:)));
scale_factor_mgv_b = 32000 / double(max_val_b);
scale_factor_mgv_a = 32000 / double(max_val_a);

% --- 3. 构建 int16 矩阵 (包含 idx_b 回退逻辑) ---
Mat_MGv_B_int16 = zeros(n_ori, n_pat, min_trials_mgv_b, nChs, nTime, 'int16');
Mat_MGv_A_int16 = zeros(n_ori, n_pat, min_trials_mgv_a, nChs, nTime, 'int16');

fprintf('正在重组 MGv 并转换为 int16...\n');
idx_b1 = []; % 初始化

for o = 1:n_ori
    for p = 1:n_pat
        % --- MGv B (拟合目标) ---
        idx_b = find(meta_mgv_b.PicID == target_ori_list(o) & meta_mgv_b.Pattern == p);
        
        % --- 补回的逻辑 ---
        if isempty(idx_b)
             if isempty(idx_b1)
                 error('MGv_B 第一个 Condition 为空，无法回退');
             end
            idx_b = idx_b1;
        end
        idx_b1 = idx_b;
        % ------------------
        
        Mat_MGv_B_int16(o, p, :, :, :) = int16(raw_mgv_b(idx_b(1:min_trials_mgv_b), 1:nChs, :) * scale_factor_mgv_b);
        
        % --- MGv A (真实 Ensemble) ---
        % 注意：原代码中 MGv_A 没有写 fallback 逻辑，这里保持原样
        idx_a = find(meta_mgv_a.PicID == target_ori_list(o) & meta_mgv_a.Pattern == p);
        if ~isempty(idx_a)
             % 如果 A 也是空的且没有 fallback，这里会报错，但原代码没有处理 A 的空值
             Mat_MGv_A_int16(o, p, :, :, :) = int16(raw_mgv_a(idx_a(1:min_trials_mgv_a), 1:nChs, :) * scale_factor_mgv_a);
        end
    end
end

save(fullfile(save_path, 'Preprocessed_MGv_int16.mat'), ...
    'Mat_MGv_B_int16', 'Mat_MGv_A_int16', ...
    'scale_factor_mgv_b', 'scale_factor_mgv_a', ...
    'meta_mgv_b', 'meta_mgv_a', ...
    'min_trials_mgv_b', 'min_trials_mgv_a', '-v7.3');
fprintf('Step 2 完成: MGv 已保存。\n');

% step3_fitting_decoding.m
clearvars -except macaque; clc;
temp_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\03_ResultData\Temp1\';
result_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\03_ResultData\';

fprintf('加载预处理后的 int16 数据...\n');
% 使用 load 加载结构体，避免变量名污染
D_SSGv = load(fullfile(temp_path, 'Preprocessed_SSGv_int16.mat'));
D_MGv  = load(fullfile(temp_path, 'Preprocessed_MGv_int16.mat'));

% --- 1. 全局对齐 (Global Min-Pooling) ---
% 我们需要 SSGv 和 MGv_B 的 Trial 数一致才能进行 "Trial-wise" 拟合 (或者按照你的逻辑，用 SSGv 的 Avg 去拟合 MGv 的 Trials)
% 你的原代码逻辑是：Mat_SSGv 和 Mat_MGv_B 在第 3/4 维 Trial 数必须对齐
global_min_trials = min([D_SSGv.min_trials_ssgv, D_MGv.min_trials_mgv_b]);

fprintf('SSGv trials: %d, MGv_B trials: %d -> Global use: %d\n', ...
    D_SSGv.min_trials_ssgv, D_MGv.min_trials_mgv_b, global_min_trials);

% --- 2. 准备数据 (裁切并还原精度) ---
% 注意：为了节省内存，我们在循环外只保留 int16，循环内取数据时再 single() / scale
% 但如果 Fit_Mat 需要一次性生成，我们必须小心内存。
% 原始数据 SSGv 很大，我们将其保留为 int16 变量
Mat_SSGv_int16 = D_SSGv.Mat_SSGv_int16(:, :, :, 1:global_min_trials, :, :); 
Mat_MGv_B_int16 = D_MGv.Mat_MGv_B_int16(:, :, 1:global_min_trials, :, :);
% MGv A 也可以先裁切好，或者保留原样 (它用于最后验证)
Mat_MGv_A = single(D_MGv.Mat_MGv_A_int16) / D_MGv.scale_factor_mgv_a; % A 可以直接还原，通常比较小

scale_ssgv = D_SSGv.scale_factor_ssgv;
scale_mgv_b = D_MGv.scale_factor_mgv_b;
clear D_SSGv D_MGv; % 释放加载的结构体

[n_loc, n_ori, n_pat, n_trial, nChs, nTime] = size(Mat_SSGv_int16);

% --- 3. 拟合过程 ---
% 分配结果矩阵 (single 精度)
Fit_Mat = zeros(n_ori, n_pat, n_trial, nChs, nTime, 'single');
method = 'linear_unconstrained';
time_segment = [40, 60];

fprintf('开始逐 Trial 拟合...\n');
tic;
for o = 1:n_ori
    for p = 1:n_pat
        
        % A. 准备 SSGv Basis
        % 取出 int16 -> 还原 single -> 缩放
        % Data: [12, Trial, Ch, Time]
        tmp_ssgv = single(squeeze(Mat_SSGv_int16(:, o, p, :, :, :))) / scale_ssgv;
        
        % 计算 Trial 平均作为 Basis: [Loc, Ch, Time]
        % squmean(x, 2) 对应原来的第 4 维 (现在是 squeeze 后的第 2 维)
        Avg_SSGv = squeeze(mean(tmp_ssgv, 2)); 
        
        % 调整为 [Channel, Time, Loc] 用于 trial_fitting
        Basis_Input = permute(Avg_SSGv, [2, 3, 1]); 
        
        % B. 准备 MGv Target
        % 取出 int16 -> 还原 single -> 缩放 -> [Trial, Ch, Time]
        tmp_mgv_b = single(squeeze(Mat_MGv_B_int16(o, p, :, :, :))) / scale_mgv_b;
        % Target Input 需要是平均值吗？
        % 原代码: Target_Input = squmean(Mat_MGv_B(o, p, :, :, :),3); 
        % 注意：trial_fitting 只需要 Basis 和 Target 的“模式”。
        % 如果是 Trial-wise 拟合，这里的 W 应该是每各 Trial 一个 W 还是所有 Trial 共用一个 W？
        % 原代码计算了一个 Target_Input (Mean) 得到 W，然后应用回所有 Trial。
        
        Target_Input_Mean = squeeze(mean(tmp_mgv_b, 1)); % [Ch, Time]
        
        % 计算权重 W: [Channel, Location+1]
        [R{o,p}, W, ~] = trial_fitting(Target_Input_Mean, Basis_Input, method, time_segment);
        
        % C. 重构 (Reconstruction)
        % 优化：向量化计算以替代最内层循环
        % W(:, 2:end) 对应 Locations, W(:, 1) 对应 Bias
        Weights_Loc = W(:, 2:end); % [nCh, nLoc]
        Bias = W(:, 1);            % [nCh, 1]
        
        % tmp_ssgv 是 [nLoc, nTrial, nCh, nTime]
        % 我们需要计算: sum(Loc_data * Weight_Loc) + Bias
        
        % 这里的计算比较繁琐，因为每个 Channel 的 Weight 不同
        % 我们可以遍历 Channel (比遍历 Loc 快)
        for ch = 1:nChs
             % 提取该 Channel 所有 Loc 的数据: [nLoc, nTrial, nTime]
             data_ch = squeeze(tmp_ssgv(:, :, ch, :)); 
             w_ch = Weights_Loc(ch, :); % [1, nLoc]
             
             % 加权求和 (广播乘法):
             % sum( data_ch .* w_ch', 1 ) -> [1, nTrial, nTime]
             % permute data_ch to [nLoc, nTrial, nTime] if not already
             
             weighted_sum = zeros(n_trial, nTime, 'single');
             for l = 1:n_loc
                 weighted_sum = weighted_sum + squeeze(data_ch(l, :, :)) * w_ch(l);
             end
             
             % 加上 Bias 并存入 Fit_Mat
             Fit_Mat(o, p, :, ch, :) = weighted_sum + Bias(ch);
        end
    end
    if mod(o, 2) == 0, fprintf('完成 Ori %d / %d\n', o, n_ori); end
end
toc;

% --- 4. 还原 Mat_MGv_B (用于计算残差) ---
% 需要将 int16 的 B 还原为 single
Mat_MGv_B = single(Mat_MGv_B_int16) / scale_mgv_b;
clear Mat_MGv_B_int16 Mat_SSGv_int16; % 释放内存

% --- 5. 后处理 (Reshaping/Averaging) ---
% 这里的逻辑保留你原代码的逻辑，对 Fit_Mat 和 MGv_A 做平均对齐
fprintf('正在进行后处理与平均...\n');

% 处理 Fit_Mat (MGv_B format)
[n_ori, n_pat, ntrial_b, nch, ntime] = size(Mat_MGv_B);
[n_ori, n_pat, ntrial_fit, nch, ntime] = size(Fit_Mat);
ntrial_b = 13;
% 假设 ntrial_b 就是上面的 n_trial
index = floor(ntrial_fit / ntrial_b); % 假设目标是 13 trials? 原代码里 A 是 13?
minnum = index * ntrial_b; % 这里的 13 应改为具体的变量，或根据 A 的 trial 数定

% 对 Fit_Mat 进行平均处理 (模拟 Pseudo-trials)
% 注意：原代码的 reshape 逻辑需要保证 minnum > 0
if minnum > 0
    % Fit Mat Averaging
    data_temp = permute(Fit_Mat, [3, 1, 2, 4, 5]); % [Trial, Ori, Pat, Ch, Time]
    Fit_Mat = squeeze(mean(reshape(data_temp(1:minnum, :, :, :, :), ...
        [ntrial_b, index, n_ori, n_pat, nch, ntime]), 2)); % [13, Ori, Pat, Ch, Time]
    Fit_Mat = permute(Fit_Mat, [2, 3, 1, 4, 5]); % [Ori, Pat, 13, Ch, Time]
    
    % MGv B Averaging (对应 Res_Mat)
    data_temp_b = permute(Mat_MGv_B, [3, 1, 2, 4, 5]);
    Mat_MGv_B = squeeze(mean(reshape(data_temp_b(1:minnum, :, :, :, :), ...
        [ntrial_b, index, n_ori, n_pat, nch, ntime]), 2));
    Mat_MGv_B = permute(Mat_MGv_B, [2, 3, 1, 4, 5]);
    
    % 计算残差
    Res_Mat = Mat_MGv_B - Fit_Mat;
else
    warning('Trial 数不足以进行 Reshape 平均，使用原始数据计算残差');
    Fit_Mat = Fit_Mat;
    Mat_MGv_B = Mat_MGv_B;
    Res_Mat = Mat_MGv_B - Fit_Mat;
end

% 处理 MGv A (Ground Truth)
[n_ori, n_pat, ntrial_a, nch, ntime] = size(Mat_MGv_A);
ntrial_target = ntrial_b; 
index_a = floor(ntrial_a / ntrial_target);
minnum_a = index_a * ntrial_target;

if minnum_a > 0
    data_temp_a = permute(Mat_MGv_A, [3, 1, 2, 4, 5]);
    Mat_MGv_A1 = squeeze(mean(reshape(data_temp_a(1:minnum_a, :, :, :, :), ...
        [ntrial_target, index_a, n_ori, n_pat, nch, ntime]), 2));
    Mat_MGv_A1 = permute(Mat_MGv_A1, [2, 3, 1, 4, 5]);
else
    Mat_MGv_A1 = Mat_MGv_A;
end

% 保存结果
fprintf('保存最终结果...\n');
save(fullfile(result_path, sprintf('%s_fitmgv.mat',macaque)), ...
    'Mat_MGv_A', 'Mat_MGv_A1', 'Mat_MGv_B', 'Fit_Mat', 'Res_Mat', '-v7.3');

%% 6. 解码部分 (直接接你的代码)

clearvars -except Mat_MGv_A Mat_MGv_A1 Mat_MGv_B Fit_Mat Res_Mat macaque R
load('sel_channel_Yge.mat','sel_channel')
channels = sel_channel.(sprintf('%s',macaque));
channels1 = [1,8,34,67,68,35,36,44,76,45,53,57,32,79,91,95,85,88,59];
channels = setdiff(channels,channels1);
options.do_permutation = false;
options.n_shuffles = 5;
options.n_repetitions = 1;
options.k_fold = 5;
options.time_smooth_win = 2;
options.mode = 'cross_condition';
target_ori = [1:18];
figure;hold on;
[n_ori,n_pat,n_trial,n_ch,n_time] = size(Fit_Mat);
data1 = reshape(Fit_Mat(target_ori,:,:,:,:),[length(target_ori),n_pat*n_trial,n_ch,n_time]);
[n_ori,n_pat,n_trial,n_ch,n_time] = size(Mat_MGv_A);
data2 = reshape(Mat_MGv_A(target_ori,:,:,:,:),[length(target_ori),n_pat*n_trial,n_ch,n_time]);
results_fit = Master_Decoder(data1(:,:,channels,:),data2(:,:,channels,:),options);
plot(results_fit.acc_real_mean)

[n_ori,n_pat,n_trial,n_ch,n_time] = size(Res_Mat);
data1 = reshape(Res_Mat(target_ori,:,:,:,:),[length(target_ori),n_pat*n_trial,n_ch,n_time]);
results_res = Master_Decoder(data1(:,:,channels,:),data2(:,:,channels,:),options);
plot(results_res.acc_real_mean)


[n_ori,n_pat,n_trial,n_ch,n_time] = size(Mat_MGv_A);
data2 = reshape(Mat_MGv_A(target_ori,:,:,:,:),[length(target_ori),n_pat*n_trial,n_ch,n_time]);
[n_ori,n_pat,n_trial,n_ch,n_time] = size(Mat_MGv_B);
data1 = reshape(Mat_MGv_B(target_ori,:,:,:,:),[length(target_ori),n_pat*n_trial,n_ch,n_time]);
results_real = Master_Decoder(data1(:,:,channels,:),data2(:,:,channels,:),options);
plot(results_real.acc_real_mean)
legend('fit-real','res-real','real-real');