function [min_trials, valid_counts_table] = calc_min_trials(meta_data, group_vars)
% CALC_MIN_TRIALS 计算指定分组条件下的 Trial 数及其最小值
%
% 输入:
%   meta_data  - 包含实验元数据的 Table (例如 meta_ssgv)
%   group_vars - 一个包含列名的 cell 数组，决定考虑哪些因素
%                例如: {'Location', 'PicID', 'Pattern'}
%
% 输出:
%   min_trials - 所有组合中最小的 trial 数
%   valid_counts_table - 详细的统计表，包含每种组合的计数

    % 1. 检查输入是否为 Table 类型 (建议将 struct 转换为 table)
    if ~istable(meta_data)
        error('输入数据 meta_data 必须是 table 类型。请使用 struct2table 转换。');
    end

    % 2. 检查 group_vars 是否存在于表中
    if ~all(ismember(group_vars, meta_data.Properties.VariableNames))
        error('指定的 group_vars 中有部分列名在 meta_data 中不存在。');
    end

    % 3. 使用 groupsummary 进行分组统计 (替代嵌套循环)
    % 这会自动计算指定变量的所有唯一组合，并统计数量
    summary_result = groupsummary(meta_data, group_vars);
    
    % 4. 提取计数 (GroupCount 是 groupsummary 自动生成的计数列)
    valid_counts = summary_result.GroupCount;
    
    % 5. 计算最小值
    if isempty(valid_counts)
        min_trials = 0;
        warning('未找到任何有效的数据组合。');
    else
        min_trials = min(valid_counts);
    end
    
    % 6. (可选) 返回详细统计表，方便检查
    valid_counts_table = summary_result;

    % 打印结果
    fprintf('------------------------------------------------\n');
    fprintf('分组条件: %s\n', strjoin(group_vars, ', '));
    fprintf('有效组合数: %d\n', length(valid_counts));
    fprintf('内部最小 Trial 数: %d\n', min_trials);
    fprintf('------------------------------------------------\n');
end