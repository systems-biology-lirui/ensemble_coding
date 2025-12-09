function [traj_data, explained, extra_info] = compute_pca_trajectory(data_matrix, varargin)
% COMPUTE_PCA_TRAJECTORY 计算神经群体轨迹 (Neural Population Trajectory)
%
% 功能:
%   1. 对输入数据进行时域平滑
%   2. 将数据重塑 (Reshape) 并进行 PCA 降维
%   3. 返回用于绘制轨迹的低维投影数据
%
% 输入:
%   data_matrix: [nCond, nCh, nTime] 数值矩阵
%
% 可选参数 (Name-Value):
%   'SmoothWin'    : (默认 10) 平滑窗口大小 (数据点数)。设为 0 或 1 不平滑。
%   'NumComponents': (默认 3) 输出的维度数 (2 或 3)
%   'SmoothMethod' : (默认 'gaussian') 平滑方法，参考 smoothdata
%
% 输出:
%   traj_data : [nCond, nTime, NumComponents] 降维后的轨迹数据
%   explained : 各主成分解释的方差百分比
%   extra_info: 包含 coeff (载荷), mu (均值) 等 PCA 详细信息
%
% 示例:
%   [traj, expl] = NeuroAlgo.compute_pca_trajectory(data, 'SmoothWin', 20, 'NumComponents', 3);

    %% 1. 参数解析
    p = inputParser;
    addRequired(p, 'data_matrix', @isnumeric);
    addParameter(p, 'SmoothWin', 10, @isnumeric);
    addParameter(p, 'NumComponents', 3, @(x) ismember(x, [2, 3]));
    addParameter(p, 'SmoothMethod', 'gaussian', @ischar);
    parse(p, data_matrix, varargin{:});
    
    win_size = p.Results.SmoothWin;
    n_comps  = p.Results.NumComponents;
    smooth_method = p.Results.SmoothMethod;
    
    [nCond, nCh, nTime] = size(data_matrix);
    
    %% 2. 数据预处理 (平滑)
    % 即使 win_size 很小，smoothdata 也可以处理
    smooth_data = zeros(size(data_matrix), 'like', data_matrix);
    
    if win_size > 1
        fprintf('  [PCA Trajectory] 正在进行时域平滑 (Win=%d, Method=%s)...\n', win_size, smooth_method);
        % 对 Time 维度 (dim 3) 进行平滑
        smooth_data = smoothdata(data_matrix, 3, smooth_method, win_size);
    else
        smooth_data = data_matrix;
    end
    
    %% 3. 数据重塑 (Prepare for PCA)
    % PCA 需要 [Observations x Variables]
    % 我们希望将 Channels 降维，所以 Variables = Channels
    % Observations = All Time Points across All Conditions
    % 形状: [nCond * nTime, nCh]
    
    % permute to [nCond, nTime, nCh] then reshape
    data_perm = permute(smooth_data, [1, 3, 2]); % -> [nCond, nTime, nCh]
    X_for_pca = reshape(data_perm, [nCond * nTime, nCh]);
    
    % 检查 NaN
    if any(isnan(X_for_pca(:)))
        warning('数据中包含 NaN，将自动替换为 0 (或考虑插值)');
        X_for_pca(isnan(X_for_pca)) = 0;
    end
    
    %% 4. 执行 PCA
    fprintf('  [PCA Trajectory] 执行 PCA (Input Size: %dx%d)...\n', size(X_for_pca,1), size(X_for_pca,2));
    
    % coeff: [nCh x nCh] 主成分载荷
    % score: [nSamples x nCh] 投影后的数据
    % latent: 特征值
    [coeff, score, ~, ~, explained_all, mu] = pca(X_for_pca);
    
    % 截取前 N 个分量
    if size(score, 2) < n_comps
        error('通道数 (%d) 小于请求的主成分数 (%d)', size(score, 2), n_comps);
    end
    
    score_cut = score(:, 1:n_comps);
    explained = explained_all(1:n_comps);
    
    fprintf('  [PCA Result] 前 %d 个主成分解释方差: %.2f%%\n', n_comps, sum(explained));
    
    %% 5. 重塑回轨迹格式
    % Input score: [nCond * nTime, nComps]
    % Output: [nCond, nTime, nComps]
    
    traj_data = reshape(score_cut, [nCond, nTime, n_comps]);
    
    %% 6. 打包额外信息
    extra_info.coeff = coeff(:, 1:n_comps);
    extra_info.mu = mu;
    extra_info.explained_all = explained_all;

end
