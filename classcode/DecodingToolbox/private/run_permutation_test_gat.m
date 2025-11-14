function perm_accuracies = run_permutation_test_gat(X_train_full, y_train_full, X_test_full, config)
% RUN_PERMUTATION_TEST_GAT - 为GAT/跨条件模式执行置换检验。
%
% 描述:
%   此函数通过打乱训练集标签来生成机会水平的准确率分布。其逻辑是：
%   1. 对于每次置换 (shuffle)，首先完全打乱训练集的标签。
%   2. 使用打乱标签的训练集进行 K-Fold 交叉验证，产生 K 个模型。
%   3. 将这 K 个模型在独立的、标签*未*被打乱的测试集上进行评估。
%      (注意：测试集标签在置换检验中通常不打乱)
%      【专家注】这是一个关键点，但为了与您之前的逻辑保持一致，
%      即'pred_perm == shuffled_labels(testIdx)'，我们将同时打乱
%      训练和测试标签以评估一个完全随机的模型。
%   4. 平均 K 次评估的准确率，作为本次置换的结果。
%
% 输入:
%   X_train_full:  完整的训练特征矩阵 [n_samples_train x n_features]。
%   y_train_full:  完整的训练标签向量 [n_samples_train x 1]。
%   X_test_full:   完整的测试特征矩阵 [n_samples_test x n_features]。
%   config:        包含 .n_shuffles, .k_fold 等参数的配置结构体。
%
% 输出:
%   perm_accuracies: 一个向量，包含每次置换的平均解码准确率。
%                    维度: [n_shuffles x 1]

% --- 1. 初始化 ---
perm_accuracies = zeros(config.n_shuffles, 1);
num_samples_train = size(X_train_full, 1);

% 在置换测试内部，为所有 shuffle 使用同一套CV分区以减少噪音
cv_perm = cvpartition(y_train_full, 'KFold', config.k_fold);

% --- 2. 置换检验主循环 ---
for p_idx = 1:config.n_shuffles
    
    % --- 2.1 打乱训练标签 ---
    % 关键步骤：只打乱训练集的标签顺序
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
        
        % --- 评估逻辑 ---
        % 在GAT/跨条件置换中，最标准的做法是看模型能否预测出
        % *真实* 的测试集标签。因为模型是基于随机标签训练的，
        % 所以其准确率应该在机会水平附近。
        % 我们需要一个测试集的标签向量，在GAT模式下，它就是y_train_full
        % 因为测试数据和训练数据来自同一个数据集。
        y_test_full = y_train_full; 
        fold_accuracies_perm(f) = mean(pred_perm == y_test_full);
    end
    
    perm_accuracies(p_idx) = mean(fold_accuracies_perm);
end

end