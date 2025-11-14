function results = run_decoding_temporal(decodingdata, config)
% RUN_DECODING_TEMPORAL - 执行标准的逐时间点MVPA解码。
%
% 描述:
%   此函数实现了时间分辨的解码分析。它遍历每一个时间点，
%   在该时间点上进行训练和测试，以评估分类器性能随时间的变化。
%   函数内部管理着真实准确率的计算、置换检验以及p值的计算。
%
% 输入:
%   decodingdata: 训练数据集。
%                 维度: [n_cluster, n_repeat, n_coil, n_time]
%   config:       由 parse_and_validate_options 生成的配置结构体。
%
% 输出:
%   results:      一个包含该模式下所有解码结果的结构体。
%                 - .acc_real_mean: 平均真实解码准确率 [1, n_time]
%                 - .p_value: p值 [1, n_time]
%                 - .perm_accuracies_mean: 平均置换准确率 [1, n_time]
%                 - .linear_weight: 解码器权重 {1, n_time}
%                 - .detailed: 包含更详细分布的结构体
%

% --- 1. 初始化和参数准备 ---
fprintf('Initializing for temporal decoding...\n');
fprintf('Settings: %d-Fold CV, %d time points, %d repetitions for real accuracy.\n', config.k_fold, config.n_time, config.n_repetitions);
if config.do_permutation
    fprintf('Permutation test is ENABLED with %d shuffles.\n', config.n_shuffles);
else
    fprintf('Permutation test is DISABLED.\n');
end
fprintf('----------------------------------------\n');

% 创建原始标签向量
labels_original = repelem((1:config.n_cluster)', config.n_repeat_train);

% 初始化输出变量
acc_real_mean = zeros(1, config.n_time);
linear_weight = cell(1, config.n_time);
p_value = [];
perm_accuracies_mean = [];
tmp_real_acc_dist = cell(1, config.n_time);
tmp_perm_acc_dist = cell(1, config.n_time);

if config.do_permutation
    p_value = ones(1, config.n_time);
    perm_accuracies_mean = zeros(1, config.n_time);
end

% --- 2. 逐时间点解码主循环 (推荐使用 parfor) ---
parfor t_idx = 1:config.n_time
    
    if mod(t_idx, 20) == 0 || t_idx == 1
        fprintf('Processing time point %d/%d...\n', t_idx, config.n_time);
    end

    % --- 2.1 数据准备 ---
    % 将数据准备逻辑封装到专门的函数中，以备GAT模式复用
    X = prepare_data_for_timepoint(decodingdata, t_idx, config.time_smooth_win);
    
    % --- 2.2 计算真实解码准确率的分布 ---
    % 这个函数将执行 n_repetitions 次交叉验证
    [real_accuracies_reps, avg_weights_t] = perform_cv_repetitions(X, labels_original, config);
    
    % 存储结果
    acc_real_mean(t_idx) = mean(real_accuracies_reps);
    linear_weight{t_idx} = avg_weights_t;
    tmp_real_acc_dist{t_idx} = real_accuracies_reps;

    % --- 2.3 条件执行排列检验 ---
    if config.do_permutation
        % 将排列检验的复杂逻辑也封装起来
        perm_accuracies_at_t = run_permutation_test(X, labels_original, config);
        
        % 存储置换结果
        perm_accuracies_mean(t_idx) = mean(perm_accuracies_at_t);
        tmp_perm_acc_dist{t_idx} = perm_accuracies_at_t;

        % 使用t检验计算p值
        [~, p] = ttest2(real_accuracies_reps, perm_accuracies_at_t, 'Tail', 'right', 'Vartype', 'unequal');
        p_value(t_idx) = p;
    end
end

% --- 3. 整合结果到输出结构体 ---
results = struct();
results.acc_real_mean = acc_real_mean;
results.p_value = p_value;
results.perm_accuracies_mean = perm_accuracies_mean;
results.linear_weight = linear_weight;
results.config = config; % 将配置信息也存入结果，方便追溯
results.detailed.real_acc_dist = tmp_real_acc_dist;
results.detailed.perm_acc_dist = tmp_perm_acc_dist;

end