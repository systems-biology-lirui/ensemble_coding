function results = run_decoding_cross_gat(data_train, data_test, config)
% RUN_DECODING_CROSS_GAT - 执行跨条件且跨时间的GAT解码。
%
% 描述:
%   此函数构建一个 [n_time x n_time] 的解码准确率矩阵。矩阵中的每个元素
%   (t_train, t_test) 代表在数据集A的一个时间点 t_train 上训练解码器，
%   然后在数据集B的另一个时间点 t_test 上测试其性能。
%
% 输入:
%   data_train: 训练数据集 (数据集A)。
%               维度: [n_cluster, n_repeat_train, n_coil, n_time]
%   data_test:  测试数据集 (数据集B)。
%               维度: [n_cluster, n_repeat_test, n_coil, n_time]
%   config:     由 parse_and_validate_options 生成的配置结构体。
%
% 输出:
%   results:    一个包含跨条件GAT解码结果的结构体。
%               - .acc_matrix: [n_time, n_time] 的平均真实准确率矩阵。
%               - .p_value_matrix: [n_time, n_time] 的 p 值矩阵。
%

% --- 1. 初始化和参数准备 ---
fprintf('Initializing for Cross-Condition GAT decoding...\n');
n_time = config.n_time;

% 创建训练集和测试集的标签向量
[~, n_repeat_train, ~, ~] = size(data_train);
[~, n_repeat_test, ~, ~] = size(data_test);
labels_train = repelem((1:config.n_cluster)', n_repeat_train);
labels_test = repelem((1:config.n_cluster)', n_repeat_test);

% 初始化输出矩阵
acc_matrix = zeros(n_time, n_time); % 行: 训练时间, 列: 测试时间
p_value_matrix = [];

if config.do_permutation
    p_value_matrix = ones(n_time, n_time);
end

% --- 2. GAT 主循环 (外层 parfor 遍历训练时间点) ---
parfor t_train_idx = 1:n_time
    
    fprintf('Cross-GAT: Training on time point %d/%d of dataset A...\n', t_train_idx, n_time);
    
    % --- 2.1 准备训练数据 (复用!) ---
    % 从数据集A中准备训练数据
    X_train_all = prepare_data_for_timepoint(data_train, t_train_idx, config.time_smooth_win);
    
    % 初始化临时行向量
    temp_acc_row = zeros(1, n_time);
    temp_p_val_row = ones(1, n_time);
    
    % --- 2.2 内层循环遍历测试时间点 ---
    for t_test_idx = 1:n_time
        
        % --- 2.2.1 准备测试数据 (复用!) ---
        % 从数据集B中准备测试数据
        X_test_all = prepare_data_for_timepoint(data_test, t_test_idx, config.time_smooth_win);

        % --- 2.2.2 计算真实准确率 (复用!) ---
        % 直接调用为GAT模式创建的核心函数，它的设计完美适用于此场景
        real_accuracies_reps = perform_gat_cv_step(X_train_all, labels_train, X_test_all, labels_test, config);
        temp_acc_row(t_test_idx) = mean(real_accuracies_reps);
        
        % --- 2.2.3 条件执行置换检验 (复用!) ---
        if config.do_permutation
            % 同样，直接复用GAT模式的置换函数
            perm_accuracies = run_permutation_test_gat(X_train_all, labels_train, X_test_all, config);
            
            [~, p] = ttest2(real_accuracies_reps, perm_accuracies, 'Tail', 'right', 'Vartype', 'unequal');
            temp_p_val_row(t_test_idx) = p;
        end
    end
    
    % 将当前训练时间点的结果存入最终矩阵
    acc_matrix(t_train_idx, :) = temp_acc_row;
    if config.do_permutation
        p_value_matrix(t_train_idx, :) = temp_p_val_row;
    end
end

% --- 3. 整合结果 ---
results = struct();
results.acc_matrix = acc_matrix;
results.p_value_matrix = p_value_matrix;
results.config = config;
results.info = 'Dimension order: [t_train_on_A, t_test_on_B]';

end