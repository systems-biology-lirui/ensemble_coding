function avg_dist_t = calc_group_avg_distance(data_matrix, cond_indices, dim_mode)
% CALC_GROUP_AVG_DISTANCE 计算指定的一组条件之间所有两两距离的平均值
%
% 输入参数:
%   data_matrix:  [nTotalConds, nTime, 3] 的矩阵
%   cond_indices: [1, n] 的向量，包含需要参与计算的条件索引 (例如 [1 3 4])
%   dim_mode:     字符串, '2d' 或 '3d'
%
% 输出参数:
%   avg_dist_t:   [nTime, 1] 的向量，表示每一时刻的平均距离

    %% 1. 输入检查与数据预处理
    num_selected = length(cond_indices);
    if num_selected < 2
        error('必须至少输入 2 个条件索引才能计算距离。');
    end

    % 根据 dim_mode 截取需要的坐标轴数据
    switch lower(dim_mode)
        case '2d'
            % 取所有时间点，仅前2个坐标 (X, Y)
            % 提取后大小为: [num_selected, nTime, 2]
            group_data = data_matrix(cond_indices, :, 1:2);
        case '3d'
            if size(data_matrix, 3) < 3
                error('数据缺少第3维，无法计算3D距离');
            end
            % 提取后大小为: [num_selected, nTime, 3]
            group_data = data_matrix(cond_indices, :, 1:3);
        otherwise
            error('dim_mode 参数错误，请输入 ''2d'' 或 ''3d''');
    end

    %% 2. 生成所有两两组合 (Pairwise Combinations)
    % 生成组合索引，例如输入索引有3个，生成: [1 2; 1 3; 2 3]
    % 注意：这里使用的是 1:num_selected 的局部索引
    pairs = nchoosek(1:num_selected, 2);
    num_pairs = size(pairs, 1);

    %% 3. 循环计算距离并累加
    [~, nTime, ~] = size(group_data);
    total_dist = zeros(nTime, 1);

    for k = 1:num_pairs
        idx_a = pairs(k, 1);
        idx_b = pairs(k, 2);
        
        % 提取两个轨迹 (squeeze 确保变成 nTime x nAxes)
        traj_a = squeeze(group_data(idx_a, :, :));
        traj_b = squeeze(group_data(idx_b, :, :));
        
        % 计算欧氏距离: sqrt(sum((a-b)^2))
        % sum(..., 2) 表示沿着坐标轴维度求和
        pair_dist = sqrt(sum((traj_a - traj_b).^2, 2));
        
        % 累加
        total_dist = total_dist + pair_dist;
    end

    %% 4. 计算平均值
    avg_dist_t = total_dist / num_pairs;

end