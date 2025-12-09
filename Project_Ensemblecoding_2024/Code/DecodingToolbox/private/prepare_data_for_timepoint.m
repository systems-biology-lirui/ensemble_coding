function X = prepare_data_for_timepoint(decodingdata, t_idx, time_smooth_win)
% PREPARE_DATA_FOR_TIMEPOINT - 为单个时间点准备解码数据
%
% 描述:
%   此辅助函数从原始的4D数据矩阵中提取数据，应用时间平滑，
%   并将其重塑为标准的 [样本数 x 特征数] 格式，以供解码器使用。
%
% 输入:
%   decodingdata:      原始数据矩阵。
%                      维度: [n_cluster, n_repeat, n_coil, n_time]
%   t_idx:             当前要处理的目标时间点的索引。
%   time_smooth_win:   时间平滑窗口的半径。例如，1 表示一个3点的窗口
%                      (t-1, t, t+1)。0表示不平滑。
%
% 输出:
%   X:                 准备好的2D数据矩阵。
%                      维度: [n_cluster * n_repeat, n_coil]

% --- 1. 获取数据维度 ---
[n_cluster, n_repeat, n_coil, n_time] = size(decodingdata);
num_samples = n_cluster * n_repeat;

% --- 2. 定义时间平滑窗口 ---
% 处理边界情况，确保窗口索引不超出范围
start_win = max(1, t_idx - time_smooth_win);
end_win = min(n_time, t_idx + time_smooth_win);
t_win = start_win:end_win;

% --- 3. 提取、平滑、并选择数据 ---
% squeeze: 移除单维度条目
% mean(..., 4): 沿着第四个维度（时间）求平均，实现平滑
X_time_t = squeeze(mean(decodingdata(:, :, :, t_win), 4));

% 如果平滑后只有一个时间点，squeeze可能会把n_coil维度也去掉，这里需要处理一下
if n_coil == 1 && isvector(X_time_t)
    X_time_t = X_time_t(:); % 确保是列向量
end

% --- 4. 重塑数据为 [样本 x 特征] 格式 ---
% permute: 交换维度顺序，将 n_repeat 和 n_cluster 放在前面
% reshape: 将前两个维度合并成一个样本维度
X = reshape(permute(X_time_t, [2, 1, 3]), num_samples, n_coil);

end