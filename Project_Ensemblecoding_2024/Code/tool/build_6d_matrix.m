function [Mat_6D, min_trials] = build_6d_matrix(EpochDB, n_loc, n_ori, n_pat)
% BUILD_6D_MATRIX 从 EpochDB 构建 6维数据矩阵
% 包含 Location 维度，并自动执行 idx 回退填补
%
% 输入:
%   EpochDB: 包含 .Meta (Location, PicID, Pattern) 和 .Data
%   n_loc:   位置数量 (如 12)
%   n_ori:   朝向数量 (如 18)
%   n_pat:   Pattern数量 (如 6)
%
% 输出:
%   Mat_6D:     single类型的6维矩阵 [nLoc, nOri, nPat, nTrial, nCh, nTime]
%   min_trials: 各条件下最小的 Trial 数

    Meta = EpochDB.Meta;
    RawData = EpochDB.Data;
    [~, nChs, nTime] = size(RawData);
    
    target_ori_list = 1:n_ori; % 假设 PicID 对应 1:18

    % --- 1. 计算最小 Trial 数 ---
    valid_counts = [];
    for l = 1:n_loc
        for o = 1:n_ori
            for p = 1:n_pat
                idx = find(Meta.Location == l & ...
                           Meta.PicID == target_ori_list(o) & ...
                           Meta.Pattern == p);
                if ~isempty(idx)
                    valid_counts(end+1) = length(idx);
                end
            end
        end
    end
    
    if isempty(valid_counts)
        error('未找到任何符合条件的数据，请检查 n_loc/n_ori/n_pat 设置');
    end
    min_trials = min(valid_counts);
    fprintf('检测到最小 Trial 数: %d\n', min_trials);

    % --- 2. 构建矩阵 (含 idx 回退逻辑) ---
    Mat_6D = zeros(n_loc, n_ori, n_pat, min_trials, nChs, nTime, 'single');
    
    idx_prev = []; % 用于记录上一次有效的 idx
    
    for l = 1:n_loc
        for o = 1:n_ori
            for p = 1:n_pat
                idx = find(Meta.Location == l & ...
                           Meta.PicID == target_ori_list(o) & ...
                           Meta.Pattern == p);
                
                % --- 回退逻辑 ---
                if isempty(idx)
                    if isempty(idx_prev)
                        error('第一个 Condition 为空，无法进行 idx 回退，请检查数据完整性');
                    end
                    % warning('Loc %d, Ori %d, Pat %d 为空，使用上一个索引回退', l, o, p);
                    idx = idx_prev;
                end
                idx_prev = idx; % 更新缓存
                % ------------------
                
                % 截取数据并填入
                % 注意：这里直接取前 min_trials 个
                current_data = RawData(idx(1:min_trials), :, :);
                Mat_6D(l, o, p, :, :, :) = single(current_data);
            end
        end
    end
end