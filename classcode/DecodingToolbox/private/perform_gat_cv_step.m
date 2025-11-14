function accuracies_reps = perform_gat_cv_step(X_train_full, y_train_full, X_test_full, y_test_full, config)
% PERFORM_GAT_CV_STEP - 执行GAT和跨条件解码的核心CV步骤。
%
% 描述:
%   此函数为 GAT/跨条件解码计算真实准确率。其逻辑是：
%   1. 在训练集 (X_train_full) 上进行 K-Fold 交叉验证，产生 K 个模型。
%   2. 将这 K 个模型分别在独立的、完整的测试集 (X_test_full) 上进行评估。
%   3. 平均这 K 次评估的准确率，作为本次重复 (repetition) 的结果。
%   4. 整个过程重复 n_repetitions 次，以获得稳定的准确率分布。
%
% 输入:
%   X_train_full:  完整的训练特征矩阵 [n_samples_train x n_features]。
%   y_train_full:  完整的训练标签向量 [n_samples_train x 1]。
%   X_test_full:   完整的测试特征矩阵 [n_samples_test x n_features]。
%   y_test_full:   完整的测试标签向量 [n_samples_test x 1]。
%   config:        包含 .n_repetitions, .k_fold 等参数的配置结构体。
%
% 输出:
%   accuracies_reps: 一个向量，包含每次重复的平均解码准确率。
%                    维度: [n_repetitions x 1]

% --- 1. 初始化 ---
accuracies_reps = zeros(config.n_repetitions, 1);

% --- 2. 多次重复的主循环 ---
for rep_idx = 1:config.n_repetitions
    
    % 每次重复都在训练集上创建新的分区
    cv = cvpartition(y_train_full, 'KFold', config.k_fold);
    fold_accuracies = zeros(1, config.k_fold);

    % --- 2.1 K-Fold 交叉验证循环 ---
    for f = 1:config.k_fold
        
        % 从完整训练集中获取当前折叠的训练子集
        trainIdx_fold = cv.training(f);
        X_train_fold = X_train_full(trainIdx_fold, :);
        y_train_fold = y_train_full(trainIdx_fold);

        % 标准化：使用当前折叠的训练数据计算均值和标准差
        mu = mean(X_train_fold, 1);
        sigma = std(X_train_fold, 0, 1);
        sigma(sigma == 0) = 1;

        X_train_fold_std = (X_train_fold - mu) ./ sigma;
        
        % !! 核心区别 !!
        % 使用相同的 mu 和 sigma 来标准化 *完整* 的测试集
        X_test_full_std  = (X_test_full - mu) ./ sigma;

        % 训练模型
        model = fitcdiscr(X_train_fold_std, y_train_fold, 'DiscrimType', 'pseudoLinear');
        
        % 在完整的独立测试集上进行预测
        pred = predict(model, X_test_full_std);

        % 计算并存储当前折叠在测试集上的准确率
        fold_accuracies(f) = mean(pred == y_test_full);
    end
    
    % 平均 K 个折叠的准确率，作为本次重复的结果
    accuracies_reps(rep_idx) = mean(fold_accuracies);
end

end