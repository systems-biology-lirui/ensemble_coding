function results = run_decoding_cross_condition(data_train, data_test, config)
% RUN_DECODING_CROSS_CONDITION - 执行跨条件/数据集的MVPA解码。
%
% 描述:
%   此函数实现了在一个数据集 (data_train) 上训练解码器，然后在另一个
%   独立的数据集 (data_test) 上进行测试的分析流程。这个过程会针对
%   每一个时间点独立进行。
%
% 输入:
%   data_train: 训练数据集。
%               维度: [n_cluster, n_repeat_train, n_coil, n_time]
%   data_test:  测试数据集。
%               维度: [n_cluster, n_repeat_test, n_coil, n_time]
%   config:     由 parse_and_validate_options 生成的配置结构体。
%
% 输出:
%   results:    一个包含该模式下所有解码结果的结构体。
%               与 'temporal' 模式的输出结构类似。
%

% --- 1. 初始化和参数准备 ---
fprintf('Initializing for cross-condition decoding...\n');
fprintf('Training on dataset A, testing on dataset B.\n');

% 创建训练集和测试集的标签向量
[~, n_repeat_train, ~, ~] = size(data_train);
[~, n_repeat_test, ~, ~] = size(data_test);
labels_train = repelem((1:config.n_cluster)', n_repeat_train);
labels_test = repelem((1:config.n_cluster)', n_repeat_test);

% 初始化输出变量
acc_real_mean = zeros(1, config.n_time);
p_value = [];
perm_accuracies_mean = [];
tmp_real_acc_dist = cell(1, config.n_time);
tmp_perm_acc_dist = cell(1, config.n_time);

if config.do_permutation
    p_value = ones(1, config.n_time);
    perm_accuracies_mean = zeros(1, config.n_time);
end

% --- 2. 逐时间点解码主循环 (parfor) ---
parfor t_idx = 1:config.n_time

    if mod(t_idx, 20) == 0 || t_idx == 1
        fprintf('Processing time point %d/%d...\n', t_idx, config.n_time);
    end

    % --- 2.1 数据准备 (复用!) ---
    % 分别为训练集和测试集准备当前时间点的数据
    X_train_t = prepare_data_for_timepoint(data_train, t_idx, config.time_smooth_win);
    X_test_t = prepare_data_for_timepoint(data_test, t_idx, config.time_smooth_win);

    % --- 2.2 计算真实解码准确率 (复用!) ---
    % 直接调用为GAT模式创建的函数，因为逻辑完全相同
    real_accuracies_reps = perform_gat_cv_step(X_train_t, labels_train, X_test_t, labels_test, config);
    
    acc_real_mean(t_idx) = mean(real_accuracies_reps);
    tmp_real_acc_dist{t_idx} = real_accuracies_reps;

    % --- 2.3 条件执行排列检验 (复用!) ---
    if config.do_permutation
        % 直接调用为GAT模式创建的函数
        perm_accuracies_at_t = run_permutation_test_gat(X_train_t, labels_train, X_test_t, config);
        
        perm_accuracies_mean(t_idx) = mean(perm_accuracies_at_t);
        tmp_perm_acc_dist{t_idx} = perm_accuracies_at_t;

        % 计算p值
        [~, p] = ttest2(real_accuracies_reps, perm_accuracies_at_t, 'Tail', 'right', 'Vartype', 'unequal');
        p_value(t_idx) = p;
    end
end

% --- 3. 整合结果 ---
results = struct();
results.acc_real_mean = acc_real_mean;
results.p_value = p_value;
results.perm_accuracies_mean = perm_accuracies_mean;
results.config = config;
results.detailed.real_acc_dist = tmp_real_acc_dist;
results.detailed.perm_acc_dist = tmp_perm_acc_dist;
% 注意：在这种模式下，解码器权重没有明确的“平均”意义，因为模型
% 是在数据A上训练的。如果需要，可以单独输出训练模型的权重。
results.info = 'Decoder trained on data_train, tested on data_test.';

end