function [sequences, item_counts] = generateBalancedSelections(total_pool_size, items_per_sequence, num_sequences)
%CREATEBALANCEDSEQUENCES_GREEDY 使用贪心策略生成高度平衡的序列。
%
%   这个版本优先保证项计数的平衡性，而不是依赖于修复一个有缺陷的结构。

%% 1. 参数初始化
pool = 1:total_pool_size;
M = total_pool_size;
k = items_per_sequence;
N = num_sequences;
num_to_exclude_per_seq = M - k;

if k > M || k < 0
    error('items_per_sequence (k) 无效。');
end
if k == M
    sequences = repmat(pool, N, 1);
    item_counts = formatOutput(sequences, pool);
    return;
end
if k == 0
    sequences = zeros(N, 0, 'uint32');
    item_counts = formatOutput(sequences, pool);
    return;
end

%% 2. 贪心算法核心
exclusion_groups = zeros(N, num_to_exclude_per_seq, 'like', pool);
% exclusion_counts 记录池中每个项已经被用作排除项的次数
exclusion_counts = zeros(1, M); 

for i = 1:N
    % 当前序列的排除组
    current_exclusion_group = zeros(1, num_to_exclude_per_seq, 'like', pool);
    
    for j = 1:num_to_exclude_per_seq
        % 确定候选池：所有尚未在当前排除组中使用的项
        candidate_pool = setdiff(pool, current_exclusion_group(1:j-1));
        
        % 从候选池中，找到那些被排除次数最少的项
        candidate_counts = exclusion_counts(candidate_pool);
        min_count = min(candidate_counts);
        
        % best_candidates 是所有被排除次数最少的项的集合
        best_candidates = candidate_pool(candidate_counts == min_count);
        
        % 从最佳候选中随机选择一个，增加随机性
        % 如果只有一个最佳候选，randsample也能正常工作
        chosen_item = best_candidates(randi(length(best_candidates)));
        
        % 将选中的项加入当前排除组
        current_exclusion_group(j) = chosen_item;
        
        % 更新该项的总排除计数
        exclusion_counts(chosen_item) = exclusion_counts(chosen_item) + 1;
    end
    
    exclusion_groups(i, :) = current_exclusion_group;
end

%% 3. 生成最终序列
sequences = zeros(N, k, 'uint32');
for i = 1:N
    sequences(i, :) = setdiff(pool, exclusion_groups(i, :));
end
% 随机打乱最终序列的呈现顺序，避免生成顺序带来的偏差
sequences = sequences(randperm(N), :);

%% 4. 格式化输出和验证
[sequences, item_counts] = formatOutput(sequences, pool);

% 额外信息输出
if nargout > 1
    counts = item_counts.Count;
    if all(counts(1) == counts)
        fprintf('状态: 实现了完美平衡。每个项出现 %d 次。\n', counts(1));
    else
        fprintf('状态: 实现了近似平衡。项出现次数介于 %d 和 %d 之间。\n', min(counts), max(counts));
    end
    % 显示排除计数，用于调试
    % disp('每个项被排除的总次数:');
    % disp(exclusion_counts);
end

end

% 辅助函数与之前版本相同
function [sequences, item_counts] = formatOutput(sequences, pool)
    if nargout > 1
        if isempty(sequences)
            counts_raw = [pool', zeros(length(pool), 2)];
        else
            counts_raw = tabulate(sequences(:));
        end
        
        if ~isempty(pool)
            missing_items = setdiff(pool, counts_raw(:,1)');
            if ~isempty(missing_items)
                missing_data = [missing_items', zeros(length(missing_items), 2)];
                counts_raw = [counts_raw; missing_data];
                counts_raw = sortrows(counts_raw, 1);
            end
        end
        item_counts = array2table(counts_raw, 'VariableNames', {'Item', 'Count', 'Frequency'});
    else
        item_counts = [];
    end
end