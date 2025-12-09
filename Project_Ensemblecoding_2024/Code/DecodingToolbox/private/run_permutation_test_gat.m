function perm_accuracies = run_permutation_test_gat(X_train_full, y_train_full, X_test_full, y_test_full, config)
% RUN_PERMUTATION_TEST_GAT - (已修正) 支持训练集和测试集大小不一致
%
% 输入增加了一个: y_test_full (真实的测试集标签)

% --- 1. 初始化 ---
perm_accuracies = zeros(config.n_shuffles, 1);
num_samples_train = size(X_train_full, 1);

% 在置换测试内部，为所有 shuffle 使用同一套CV分区以减少噪音
cv_perm = cvpartition(y_train_full, 'KFold', config.k_fold);

% --- 2. 置换检验主循环 ---
for p_idx = 1:config.n_shuffles
    
    % --- 2.1 打乱训练标签 ---
    % 关键步骤：只打乱训练集的标签顺序来建立零分布
    shuffled_train_labels = y_train_full(randperm(num_samples_train));
    
    fold_accuracies_perm = zeros(1, config.k_fold);
    
    % --- 2.2 K-Fold 交叉验证循环 ---
    for f = 1:config.k_fold
        trainIdx_fold = cv_perm.training(f);
        
        X_train_fold = X_train_full(trainIdx_fold, :);
        
        % 使用当前折叠对应部分的 *打乱后* 的训练标签
        y_train_fold_shuffled = shuffled_train_labels(trainIdx_fold);
        
        % 标准化：仍然基于原始训练数据
        mu = mean(X_train_fold, 1);
        sigma = std(X_train_fold, 0, 1);
        sigma(sigma == 0) = 1;
        
        X_train_fold_std = (X_train_fold - mu) ./ sigma;
        X_test_full_std  = (X_test_full - mu) ./ sigma;
        
        % 使用打乱后的训练标签训练模型
        model_perm = fitcdiscr(X_train_fold_std, y_train_fold_shuffled, 'DiscrimType', 'pseudoLinear');
        
        % 在独立的测试集上预测
        pred_perm = predict(model_perm, X_test_full_std);
        
        % --- 评估逻辑 (已修正) ---
        % 使用传入的真实测试集标签进行对比
        fold_accuracies_perm(f) = mean(pred_perm == y_test_full);
    end
    
    perm_accuracies(p_idx) = mean(fold_accuracies_perm);
end
end