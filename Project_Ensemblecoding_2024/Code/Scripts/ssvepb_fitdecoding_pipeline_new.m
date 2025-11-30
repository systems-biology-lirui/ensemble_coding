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

% --- 2. 构建 Single 矩阵 (包含 idx 回退逻辑) ---
% 直接使用 single，不再计算缩放因子
Mat_SSGv = zeros(n_loc, n_ori, n_pat, min_trials_ssgv, nChs, nTime, 'single');

fprintf('正在重组 SSGv 并转换为 single...\n');
idx1 = []; 

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
            
            % 取出数据 -> 直接转 single (不需要缩放)
            temp_data = raw_ssgv(idx(1:min_trials_ssgv), :, :);
            Mat_SSGv(l, o, p, :, :, :) = single(temp_data);
        end
    end
end

% 保存时变量名不再带 int16 后缀
save(fullfile(save_path, 'Preprocessed_SSGv_single.mat'), ...
    'Mat_SSGv', 'meta_ssgv', 'min_trials_ssgv', '-v7.3');

fprintf('Step 1 完成: SSGv (Single) 已保存。\n');
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

% --- 2. 构建 Single 矩阵 (包含 idx_b 回退逻辑) ---
% 直接初始化为 single
Mat_MGv_B = zeros(n_ori, n_pat, min_trials_mgv_b, nChs, nTime, 'single');
Mat_MGv_A = zeros(n_ori, n_pat, min_trials_mgv_a, nChs, nTime, 'single');

fprintf('正在重组 MGv 并转换为 single...\n');
idx_b1 = []; 

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
        
        % 直接转 single
        Mat_MGv_B(o, p, :, :, :) = single(raw_mgv_b(idx_b(1:min_trials_mgv_b), 1:nChs, :));
        
        % --- MGv A (真实 Ensemble) ---
        idx_a = find(meta_mgv_a.PicID == target_ori_list(o) & meta_mgv_a.Pattern == p);
        if ~isempty(idx_a)
             Mat_MGv_A(o, p, :, :, :) = single(raw_mgv_a(idx_a(1:min_trials_mgv_a), 1:nChs, :));
        end
    end
end

save(fullfile(save_path, 'Preprocessed_MGv_single.mat'), ...
    'Mat_MGv_B', 'Mat_MGv_A', ...
    'meta_mgv_b', 'meta_mgv_a', ...
    'min_trials_mgv_b', 'min_trials_mgv_a', '-v7.3');

fprintf('Step 2 完成: MGv (Single) 已保存。\n');
% step3_fitting_decoding.m
clearvars -except macaque; clc;
temp_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\03_ResultData\Temp1\';
result_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\03_ResultData\';

fprintf('加载预处理后的 single 数据...\n');
% 使用 load 加载结构体，避免变量名污染
D_SSGv = load(fullfile(temp_path, 'Preprocessed_SSGv_single.mat'));
D_MGv  = load(fullfile(temp_path, 'Preprocessed_MGv_single.mat'));

% --- 1. 全局对齐 (Global Min-Pooling) ---
global_min_trials = min([D_SSGv.min_trials_ssgv, D_MGv.min_trials_mgv_b]);
fprintf('SSGv trials: %d, MGv_B trials: %d -> Global use: %d\n', ...
    D_SSGv.min_trials_ssgv, D_MGv.min_trials_mgv_b, global_min_trials);

% --- 2. 准备数据 (裁切) ---
% 数据已经是 single，无需还原，直接裁切 Trial 维度
Mat_SSGv = D_SSGv.Mat_SSGv(:, :, :, 1:global_min_trials, :, :); 
Mat_MGv_B = D_MGv.Mat_MGv_B(:, :, 1:global_min_trials, :, :);

% MGv A 保留原样 (它用于最后验证)
Mat_MGv_A = D_MGv.Mat_MGv_A; 

clear D_SSGv D_MGv; % 释放加载的结构体
[n_loc, n_ori, n_pat, n_trial, nChs, nTime] = size(Mat_SSGv);

% --- 3. 拟合过程 ---
Fit_Mat = zeros(n_ori, n_pat, n_trial, nChs, nTime, 'single');
method = 'linear_unconstrained';
time_segment = [40, 60];

fprintf('开始逐 Trial 拟合...\n');
tic;
for o = 1:n_ori
    for p = 1:n_pat
        
        % A. 准备 SSGv Basis
        % 已经是 single，直接取
        % Data: [12, Trial, Ch, Time]
        tmp_ssgv = squeeze(Mat_SSGv(:, o, p, :, :, :));
        
        % 计算 Trial 平均作为 Basis: [Loc, Ch, Time]
        Avg_SSGv = squeeze(mean(tmp_ssgv, 2)); 
        
        % 调整为 [Channel, Time, Loc] 用于 trial_fitting
        Basis_Input = permute(Avg_SSGv, [2, 3, 1]); 
        
        % B. 准备 MGv Target
        % 已经是 single，直接取
        tmp_mgv_b = squeeze(Mat_MGv_B(o, p, :, :, :));
        
        Target_Input_Mean = squeeze(mean(tmp_mgv_b, 1)); % [Ch, Time]
        
        % 计算权重 W: [Channel, Location+1]
        [R{o,p}, W, ~] = trial_fitting(Target_Input_Mean, Basis_Input, method, time_segment);
        
        % C. 重构 (Reconstruction)
        Weights_Loc = W(:, 2:end); % [nCh, nLoc]
        Bias = W(:, 1);            % [nCh, 1]
        
        % tmp_ssgv 是 [nLoc, nTrial, nCh, nTime]
        for ch = 1:nChs
             % 提取该 Channel 所有 Loc 的数据: [nLoc, nTrial, nTime]
             data_ch = squeeze(tmp_ssgv(:, :, ch, :)); 
             w_ch = Weights_Loc(ch, :); % [1, nLoc]
             
             % 加权求和
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

% --- 4. 这里的 Mat_MGv_B 已经是 single，无需还原 ---
% (该步骤已在 Step 2 加载时完成)

% --- 5. 后处理 (Reshaping/Averaging) ---
fprintf('正在进行后处理与平均...\n');

% 处理 Fit_Mat (MGv_B format)
[n_ori, n_pat, ntrial_b, nch, ntime] = size(Mat_MGv_B);
[n_ori, n_pat, ntrial_fit, nch, ntime] = size(Fit_Mat);

ntrial_b = 13; % 这里的 13 最好参数化，比如来自 MGv_A 的 trial 数
index = floor(ntrial_fit / ntrial_b); 
minnum = index * ntrial_b;

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

%% 6. 解码部分
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