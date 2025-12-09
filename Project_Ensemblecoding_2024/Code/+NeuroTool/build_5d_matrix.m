function [Mat_5D, min_trials] = build_5d_matrix(EpochDB, n_ori, n_pat, target_ori_list)
% BUILD_5D_MATRIX 从 EpochDB 构建 5维数据矩阵
% 不区分 Location (或无 Location)，自动执行 idx 回退填补
%
% 输入:
%   EpochDB: 包含 .Meta (PicID, Pattern) 和 .Data
%   n_ori:   朝向数量 (如 18)
%   n_pat:   Pattern数量 (如 6)
%
% 输出:
%   Mat_5D:     single类型的5维矩阵 [nOri, nPat, nTrial, nCh, nTime]
%   min_trials: 各条件下最小的 Trial 数

    Meta = EpochDB.Meta;
    RawData = EpochDB.Data;
    [~, nChs, nTime] = size(RawData);
    

    % --- 1. 计算最小 Trial 数 ---
    valid_counts = [];
    for o = 1:n_ori
        for p = 1:n_pat
            idx = find(Meta.PicID == target_ori_list(o) & Meta.Pattern == p);
            if ~isempty(idx)
                valid_counts(end+1) = length(idx);
            end
        end
    end
    
    if isempty(valid_counts)
        error('未找到任何符合条件的数据');
    end
    min_trials = min(valid_counts);
    fprintf('检测到最小 Trial 数: %d\n', min_trials);

    % --- 2. 构建矩阵 (含 idx 回退逻辑) ---
    Mat_5D = zeros(n_ori, n_pat, min_trials, nChs, nTime, 'single');
    
    idx_prev = []; 
    
    for o = 1:n_ori
        for p = 1:n_pat
            idx = find(Meta.PicID == target_ori_list(o) & Meta.Pattern == p);
            
            % --- 回退逻辑 ---
            if isempty(idx)
                if isempty(idx_prev)
                    error('第一个 Condition 为空，无法回退');
                end
                idx = idx_prev;
            end
            idx_prev = idx;
            % ------------------
            
            current_data = RawData(idx(1:min_trials), :, :);
            Mat_5D(o, p, :, :, :) = single(current_data);
        end
    end
end