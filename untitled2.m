
clear;
% 1. 加载数据与预处理
base_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\02_EpochDatabase';
data.SSGv  = load(fullfile(base_path, 'DG_SSGv_SSVEP_B_MUA2_Epochs_Avg.mat'));
data.MGv_b = load(fullfile(base_path, 'DG_MGv_SSVEP_B_MUA2_Epochs_Avg.mat'));
data.MGv_a = load(fullfile(base_path, 'DG_MGv_SSVEP_A_MUA2_Epochs_Avg.mat'));

% 提取 Meta 和 Data
meta_ssgv  = data.SSGv.EpochDB.Meta;
meta_mgv_b = data.MGv_b.EpochDB.Meta;
meta_mgv_a = data.MGv_a.EpochDB.Meta;

raw_ssgv   = data.SSGv.EpochDB.Data;
raw_mgv_b  = data.MGv_b.EpochDB.Data;
raw_mgv_a  = data.MGv_a.EpochDB.Data;

[~, nChs, nTime] = size(raw_mgv_b);
target_ori_list = [1, 9]; % Ori 对应 PicID
n_ori = 18;
n_pat = 6;
n_loc = 12;

% 2. 计算最小 Trial 数并构建矩阵 (Min-Pooling)
% 目的：为了后续能整齐地放入矩阵，丢弃多余的 Trial
counts_ssgv = splitapply(@numel, meta_ssgv.Location, ...
findgroups(meta_ssgv.Location, meta_ssgv.PicID, meta_ssgv.Pattern));
counts_mgv_b  = splitapply(@numel, meta_mgv_b.PicID, ...
findgroups(meta_mgv_b.PicID, meta_mgv_b.Pattern));
counts_mgv_a  = splitapply(@numel, meta_mgv_a.PicID, ...
findgroups(meta_mgv_a.PicID, meta_mgv_a.Pattern));

min_trials_mgv_b = min(counts_mgv_b);
min_trials_mgv_a = min(counts_mgv_a);
min_trials_ssgv = min(counts_ssgv);
% fprintf('所有条件中最小 Trial 数为: %d. 将据此构建矩阵。\n', min_trials);

% --- 预分配大矩阵 ---
% 维度: [Ori, Pattern, Trial, Channel, Time]
% SSGv 额外多一个 Location: [Loc, Ori, Pat, Trial, Ch, Time]
Mat_SSGv  = zeros(n_loc, n_ori, n_pat, min_trials_ssgv, nChs, nTime);
Mat_MGv_B = zeros(n_ori, n_pat, min_trials_mgv_b, nChs, nTime);
Mat_MGv_A = zeros(n_ori, n_pat, min_trials_mgv_a, nChs, nTime);

fprintf('正在重组数据到矩阵...\n');

% 填充 SSGv
for l = 1:n_loc
for o = 1:n_ori
for p = 1:n_pat
idx = find(meta_ssgv.Location == l & ...
meta_ssgv.PicID == target_ori_list(o) & ...
meta_ssgv.Pattern == p);
Mat_SSGv(l, o, p, :, :, :) = raw_ssgv(idx(1:min_trials_ssgv), :, :);
end
end
end

% 填充 MGv (B 和 A)
for o = 1:n_ori
for p = 1:n_pat
% MGv_B (拟合目标)
idx_b = find(meta_mgv_b.PicID == target_ori_list(o) & ...
meta_mgv_b.Pattern == p);
Mat_MGv_B(o, p, :, :, :) = raw_mgv_b(idx_b(1:min_trials_mgv_b), :, :);

code
Code
download
content_copy
expand_less
% MGv_A (真实 Ensemble, 用于对比)
idx_a = find(meta_mgv_a.PicID == target_ori_list(o) & ...
meta_mgv_a.Pattern == p);
% 确保 A 的数据量足够
Mat_MGv_A(o, p, :, :, :) = raw_mgv_a(idx_a(1:min_trials_mgv_a), :, :);
end

end

% 3. 调用 trial_fitting 进行拟合
% 预分配结果矩阵: [Ori, Pat, Trial, Channel, Time]
Fit_Mat = zeros(n_ori, n_pat, min_trials_ssgv, nChs, nTime); % 拟合信号 C
Res_Mat = zeros(n_ori, n_pat, min_trials_ssgv, nChs, nTime); % 残差信号 R
% Weights 矩阵稍微复杂点，取决于 trial_fitting 返回的 W 维度
% 假设 W 是 [Channel, Location+1]，我们先不存 W，或者你需要的话再加

%%
method = 'linear_unconstrained';
time_segment = [1,121];

fprintf('开始逐 Trial 拟合 (调用用户自定义函数)...\n');
tic;

for o = 1:n_ori
for p = 1:n_pat

code
Code
download
content_copy
expand_less
% --- 步骤 A: 准备基准信号 (Basis) ---
% SSGv 必须使用平均值，因为 Location 1 的 Trial 1 和 Location 2 的 Trial 1 无关
% 取出该 Condition 下所有 12 个位置的数据 -> 求 Trial 平均
% 维度变化: [Loc, Trial, Ch, Time] -> [Loc, Ch, Time]
Avg_SSGv = squmean(Mat_SSGv(:, o, p, :, :, :), 4);

code
Code
download
content_copy
expand_less
% 调整维度以适配 trial_fitting 的输入要求: [Channel, Time, 12]
% 原始 Avg_SSGv 是 [Loc, Ch, Time] -> permute -> [Ch, Time, Loc]
Basis_Input = permute(Avg_SSGv, [2, 3, 1]); 
Target_Input = squmean(Mat_MGv_B(o, p, :, :, :),3);
[R{o,p}, W{o,p}, Fit_out] = trial_fitting(Target_Input, Basis_Input, method, time_segment);
for channel = 1:nChs
    for location = 1:12
        dd = Mat_SSGv(location, o, p, :, channel, :)*W{o,p}(channel,location+1);
        [~,~,~,tt,~,t1] = size(dd);
        Fit_Mat(o,p,:,channel,:) = Fit_Mat(o,p,:,channel,:)+reshape(dd,[1,1,tt,1,t1]);
    end
    Fit_Mat(o,p,:,channel,:) = Fit_Mat(o,p,:,channel,:)+W{o,p}(channel,1);
    Res_Mat(o,p,:,channel,:) = reshape(repmat(Fit_out(channel,:),[tt,1]),[1,1,tt,1,t1]) - Fit_Mat(o,p,:,channel,:);
end

end
fprintf('完成 Ori %d / %d\n', o, n_ori);

end
toc;

%%
save('d:/ensemble_coding/Project_Ensemblecoding_2024/Data/03_ResultData/DG_fitmgv.mat','Mat_MGv_A','Mat_MGv_B','Mat_SSGv', ...
'meta_mgv_a','meta_mgv_b','meta_ssgv',"Fit_Mat",'Res_Mat');
%% 5. 运行解码 (示例)
clearvars -except Mat_MGv_A Fit_Mat Res_Mat
load('sel_channel_Yge.mat','sel_channel')
channels = sel_channel.DG;
options.do_permutation = false;
options.n_shuffles = 5;
options.n_repetitions = 100;
options.k_fold = 5;
options.time_smooth_win = 2;
options.mode = 'cross_condition';

figure;hold on;
data1 = reshape(Fit_Mat,[2,661,100,121]);
data2 = reshape(Mat_MGv_A,[2,672,100,121]);
results_res = Master_Decoder(data1(:,:,channels,:),data2(:,:,channels,:),options);
plot(results_res.acc_real_mean)

data1 = reshape(Res_Mat,[2,6*61,100,121]);
results_res = Master_Decoder(data1(:,:,channels,:),data2(:,:,channels,:),options);
plot(results_res.acc_real_mean)

data3 = squeeze(Res_Mat(2,:,:,:,:));
data4 = squeeze(Mat_MGv_A(2,:,:,:,:));
results_res = Master_Decoder(data3(:,:,channels,:),data4(:,:,channels,:),options);
plot(smooth(results_res.acc_real_mean))

options.mode = 'temporal';
results_res = Master_Decoder(data2(:,:,channels,:),[],options);
plot(results_res.acc_real_mean)

% 解码残差
% disp('Running Decoding on Residuals...');
% results_res = Master_Decoder(Data_Res_Decode, Labels, options);
% legend('fit-real','res-real','real-real');