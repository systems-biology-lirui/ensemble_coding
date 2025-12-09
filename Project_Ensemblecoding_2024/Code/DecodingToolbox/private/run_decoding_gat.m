function results = run_decoding_gat(decodingdata, config)
% RUN_DECODING_GAT - 执行跨时间泛化 (GAT) 解码分析。
%
% 描述:
%   此函数构建一个 [n_time x n_time] 的解码准确率矩阵。矩阵中的每个元素
%   (t_train, t_test) 代表在一个时间点 t_train 上训练解码器，然后在
%   另一个时间点 t_test 上测试其性能。对角线结果等同于标准的时间点解码。
%
% 输入:
%   decodingdata: 训练数据集。
%                 维度: [n_cluster, n_repeat, n_coil, n_time]
%   config:       由 parse_and_validate_options 生成的配置结构体。
%
% 输出:
%   results:      一个包含GAT解码结果的结构体。
%                 - .acc_matrix: [n_time, n_time] 的平均真实准确率矩阵。
%                 - .p_value_matrix: [n_time, n_time] 的 p 值矩阵。
%                 - .perm_acc_mean_matrix: [n_time, n_time] 的平均置换准确率矩阵。
%

% --- 1. 初始化和参数准备 ---
fprintf('Initializing for Generalization Across Time (GAT) decoding...\n');
n_time = config.n_time;

% 创建原始标签向量
labels_original = repelem((1:config.n_cluster)', config.n_repeat_train);

% 初始化输出矩阵
acc_matrix = zeros(n_time, n_time); % 行: 训练时间, 列: 测试时间
p_value_matrix = [];
perm_acc_mean_matrix = [];

if config.do_permutation
    p_value_matrix = ones(n_time, n_time);
    perm_acc_mean_matrix = zeros(n_time, n_time);
end

% --- 2. GAT 主循环 (外层 parfor 遍历训练时间点) ---
parfor t_train_idx = 1:n_time
    
    fprintf('GAT: Training on time point %d/%d...\n', t_train_idx, n_time);
    
    % --- 2.1 准备训练数据 (复用!) ---
    % 训练数据在内层循环中是固定的
    X_train_all = prepare_data_for_timepoint(decodingdata, t_train_idx, config.time_smooth_win);
    
    % 初始化用于存储当前训练时间点结果的临时行向量
    temp_acc_row = zeros(1, n_time);
    temp_p_val_row = ones(1, n_time);
    temp_perm_acc_row = zeros(1, n_time);
    
    % --- 2.2 内层循环遍历测试时间点 ---
    for t_test_idx = 1:n_time
        
        if t_train_idx == t_test_idx
            % --- 对角线情况：使用 Temporal 模式的严格交叉验证 ---
            
            % 2.2.1 计算真实准确率 (调用 temporal 的核心函数)
            % 注意：这里不需要解码器权重，所以第二个输出参数用 ~ 忽略
            [real_accuracies_reps, ~] = perform_cv_repetitions(X_train_all, labels_original, config);
            temp_acc_row(t_test_idx) = mean(real_accuracies_reps);

            % 2.2.2 条件执行置换检验 (调用 temporal 的置换函数)
            if config.do_permutation
                perm_accuracies = run_permutation_test(X_train_all, labels_original, config);
                temp_perm_acc_row(t_test_idx) = mean(perm_accuracies);
                [~, p] = ttest2(real_accuracies_reps, perm_accuracies, 'Tail', 'right', 'Vartype', 'unequal');
                temp_p_val_row(t_test_idx) = p;
            end
        else
            % --- 非对角线情况：使用 GAT 模式的独立测试集逻辑 ---

            % 2.2.3 准备测试数据 (复用!)
            X_test_all = prepare_data_for_timepoint(decodingdata, t_test_idx, config.time_smooth_win);

            % 2.2.4 计算真实解码准确率 (调用 GAT 的核心函数)
            real_accuracies_reps = perform_gat_cv_step(X_train_all, labels_original, X_test_all, labels_original, config);
            temp_acc_row(t_test_idx) = mean(real_accuracies_reps);
            
            % 2.2.5 条件执行置换检验 (调用 GAT 的置换函数)
            if config.do_permutation
                perm_accuracies = run_permutation_test_gat(X_train_all, labels_original, X_test_all, config);
                temp_perm_acc_row(t_test_idx) = mean(perm_accuracies);
                [~, p] = ttest2(real_accuracies_reps, perm_accuracies, 'Tail', 'right', 'Vartype', 'unequal');
                temp_p_val_row(t_test_idx) = p;
            end
        end
    end
    
    % 将当前训练时间点的结果存入最终矩阵
    acc_matrix(t_train_idx, :) = temp_acc_row;
    if config.do_permutation
        p_value_matrix(t_train_idx, :) = temp_p_val_row;
        perm_acc_mean_matrix(t_train_idx, :) = temp_perm_acc_row;
    end
end

% --- 3. 整合结果 ---
results = struct();
results.acc_matrix = acc_matrix;
results.p_value_matrix = p_value_matrix;
results.perm_acc_mean_matrix = perm_acc_mean_matrix;
results.config = config;
results.info = 'Dimension order: [t_train, t_test]';

end