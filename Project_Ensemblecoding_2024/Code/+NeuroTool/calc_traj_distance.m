function dist_t = calc_traj_distance(data_matrix, cond1_idx, cond2_idx, dim_mode)
% CALC_TRAJ_DISTANCE 计算两个条件在随时间变化上的欧氏距离
%
% 输入参数:
%   data_matrix: 大小为 [nConditions, nTime, 3] 的矩阵 (X, Y, Z)
%   cond1_idx:   第一个条件的索引 (整数)
%   cond2_idx:   第二个条件的索引 (整数)
%   dim_mode:    计算模式, 输入 '2d' 或 '3d' (字符串)
%                - '2d': 仅使用前两列 (x, y) 计算距离
%                - '3d': 使用所有三列 (x, y, z) 计算距离
%
% 输出参数:
%   dist_t:      大小为 [nTime, 1] 的向量，表示每一时刻的距离

    % 1. 输入校验
    if size(data_matrix, 3) < 2
        error('输入矩阵的第3维必须至少包含2个坐标轴数据');
    end

    % 2. 提取两个条件的数据
    % squeeze 将 [1, Time, 3] 压缩为 [Time, 3]
    traj1 = squeeze(data_matrix(cond1_idx, :, :));
    traj2 = squeeze(data_matrix(cond2_idx, :, :));

    % 3. 根据参数选择维度
    switch lower(dim_mode) % lower转换为小写，兼容 '2D', '2d'
        case '2d'
            % 仅取前两列 (X, Y)
            p1 = traj1(:, 1:2);
            p2 = traj2(:, 1:2);
        case '3d'
            % 取所有三列 (X, Y, Z)
            if size(data_matrix, 3) < 3
                error('请求计算3D距离，但数据第3维不足3列');
            end
            p1 = traj1(:, 1:3);
            p2 = traj2(:, 1:3);
        otherwise
            error('dim_mode 参数错误，请使用 ''2d'' 或 ''3d''');
    end

    % 4. 计算欧几里得距离
    % 公式: sqrt(sum((p1 - p2)^2))
    diff_sq = (p1 - p2) .^ 2;       % 计算差值的平方
    sum_sq = sum(diff_sq, 2);       % 沿第2维度(坐标轴)求和
    dist_t = sqrt(sum_sq);          % 开根号

end