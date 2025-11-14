function perm_accuracies = run_permutation_test(X, labels, config)
% RUN_PERMUTATION_TEST - 执行置换检验以生成机会水平的准确率分布。
%
% 描述:
%   此函数通过多次打乱训练标签来模拟机会水平的解码性能。
%   在每次置换中，它都执行一次完整的 K-Fold 交叉验证。
%   返回的结果是一个包含了所有置换准确率的向量，用于后续的统计检验。
%
% 输入:
%   X:        准备好的2D数据矩阵 [样本数 x 特征数]。
%   labels:   原始的、未被打乱的标签向量 [样本数 x 1]。
%   config:   包含 .n_shuffles, .k_fold 等参数的配置结构体。
%
% 输出:
%   perm_accuracies: 一个向量，包含每次置换的平均解码准确率。
%                    维度: [n_shuffles x 1]

% --- 1. 初始化 ---
perm_accuracies = zeros(config.n_shuffles, 1);
num_samples = size(X, 1);

% 为了置换测试内部的稳定性，我们可以为所有 shuffle 使用同一套CV分区。
% 这可以减少因CV分区不同带来的额外噪音。
cv_perm = cvpartition(labels, 'KFold', config.k_fold);

% --- 2. 置换检验主循环 ---
for p_idx = 1:config.n_shuffles
    
    % --- 2.1 打乱标签 ---
    % 关键步骤：在整个数据集上随机打乱标签的顺序
    shuffled_labels = labels(randperm(num_samples));
    
    fold_accuracies_perm = zeros(1, config.k_fold);

    % --- 2.2 K-Fold 交叉验证循环 ---
    for f = 1:config.k_fold
        trainIdx = cv_perm.training(f);
        testIdx  = cv_perm.test(f);

        X_train = X(trainIdx, :);
        X_test  = X(testIdx, :);
        
        % 使用打乱后的标签
        y_train_shuffled = shuffled_labels(trainIdx);
        y_test_shuffled  = shuffled_labels(testIdx);

        % 标准化（与真实解码完全相同，基于原始训练集）
        mu = mean(X_train, 1);
        sigma = std(X_train, 0, 1);
        sigma(sigma == 0) = 1;

        X_train_std = (X_train - mu) ./ sigma;
        X_test_std  = (X_test - mu) ./ sigma;

        % 使用打乱后的标签进行训练和测试
        model_perm = fitcdiscr(X_train_std, y_train_shuffled, 'DiscrimType', 'pseudoLinear');
        pred_perm = predict(model_perm, X_test_std);
        
        % 评估时，与对应的打乱后的测试标签比较
        fold_accuracies_perm(f) = mean(pred_perm == y_test_shuffled);
    end
    
    % 存储本次置换的平均准确率
    perm_accuracies(p_idx) = mean(fold_accuracies_perm);
end

end