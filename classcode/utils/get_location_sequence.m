function [sequences, item_counts] = get_location_sequence(total_pool_size, items_per_sequence, num_sequences)
%CREATEBALANCEDSEQUENCES 生成计数平衡或近似平衡的序列（修正版）。
%
%   输入:
%       total_pool_size     - 池中所有可选项的总数 (M)。
%       items_per_sequence  - 每个生成的序列应包含的项数 (k)。
%       num_sequences       - 希望生成的序列总数 (N)。
%
%   输出:
%       sequences           - 一个 [N x k] 的矩阵，每一行是一个生成的序列。
%       item_counts         - 用于验证平衡性的统计表。

%% 1. 计算核心参数
% =========================================================================
pool = 1:total_pool_size;
M = total_pool_size;
k = items_per_sequence;
N = num_sequences;

num_to_exclude_per_seq = M - k; % E: 每个序列需要排除的项数

if num_to_exclude_per_seq == 0
    % (处理无需排除的情况，保持原样)
    sequences = repmat(pool, N, 1);
    sequences = sequences(randperm(N), :);
    [sequences, item_counts] = formatOutput(sequences, pool);
    return;
end

total_exclusions_needed = N * num_to_exclude_per_seq;

%% 2. 【修正】构建主排除列表：使用连接的随机排列
% =========================================================================
% 我们需要确保用于构建排除组的列表是通过连接多个完整的随机排列生成的。

% 计算需要多少个完整的随机排列
num_full_permutations = ceil(total_exclusions_needed / M);

master_exclusion_list = [];
for i = 1:num_full_permutations
    % 生成一个完整的、随机打乱的池子排列
    random_perm = pool(randperm(M));
    master_exclusion_list = [master_exclusion_list, random_perm];
end

% 截取所需的总排除数
% 由于我们是按顺序从随机排列中获取的，这保证了最佳的平衡性
master_exclusion_list = master_exclusion_list(1:total_exclusions_needed);

%% 3. 【关键】生成排除组 (Reshape)
% =========================================================================
% 将主排除列表重塑为 E x N 的矩阵。
% 由于 master_exclusion_list 是由随机排列连接而成，reshape 按列填充时，
% 只要 E <= M (这是必须的)，列内就不会有重复项。
try
    % reshape 按列填充：[排除组1的元素; 排除组2的元素; ...]
    exclusion_matrix = reshape(master_exclusion_list, num_to_exclude_per_seq, N);

    % 转置，使得每一行代表一个序列的排除组
    exclusion_groups = exclusion_matrix';
    
catch ME
    % 理论上如果输入参数有效，这里不应出错，但保留错误处理
    error('无法将排除列表 (%d个元素) 塑形为 %d x %d 的矩阵。参数可能无效。 Error: %s', ...
          total_exclusions_needed, num_to_exclude_per_seq, N, ME.message);
end

%% 4. 生成最终序列 (Generate Final Sequences)
% =========================================================================
sequences = zeros(N, k, 'uint32');

for i = 1:N
    current_exclusion_group = exclusion_groups(i, :);
    
    % 验证排除组内是否有重复 (理论上不应发生)
    if length(unique(current_exclusion_group)) ~= length(current_exclusion_group)
        error('内部错误：在序列 %d 的排除组中发现了重复项。', i);
    end
    
    % 使用 setdiff 得到最终包含的项
    sequences(i, :) = setdiff(pool, current_exclusion_group);
end

% 随机打乱最终序列的呈现顺序
sequences = sequences(randperm(N), :);

%% 5. 验证平衡性并格式化输出
% =========================================================================
[sequences, item_counts] = formatOutput(sequences, pool);

% 额外信息输出 (用于调试和确认)
if mod(total_exclusions_needed, M) == 0
    reps_per_item = total_exclusions_needed / M;
    fprintf('状态: 实现了完美平衡。每个项出现 %d 次。\n', N - reps_per_item);
else
    fprintf('状态: 实现了近似平衡。\n');
end

end

%% 辅助函数：格式化输出和计算统计
function [sequences, item_counts] = formatOutput(sequences, pool)
    if nargout > 1
        counts_raw = tabulate(sequences(:));
        % 检查是否有项从未出现过，并补全它们
        missing_items = setdiff(pool, counts_raw(:,1)');
        if ~isempty(missing_items)
            missing_data = [missing_items', zeros(length(missing_items), 2)];
            counts_raw = [counts_raw; missing_data];
            counts_raw = sortrows(counts_raw, 1);
        end
        item_counts = array2table(counts_raw, 'VariableNames', {'Item', 'Count', 'Frequency'});
    else
        item_counts = [];
    end
end