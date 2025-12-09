function [accuracies_reps, avg_weights] = perform_cv_repetitions(X, labels, config)
% PERFORM_CV_REPETITIONS - 执行多次重复的K-Fold交叉验证。
%
% 描述:
%   此函数是解码计算的核心模块。为了获得稳定的性能估计，它会执行
%   n_repetitions 次完整的 K-Fold 交叉验证。在每次重复中，都会创建
%   全新的数据分区。
%
% 输入:
%   X:        准备好的2D数据矩阵 [样本数 x 特征数]。
%   labels:   对应的标签向量 [样本数 x 1]。
%   config:   包含 .n_repetitions, .k_fold 等参数的配置结构体。
%
% 输出:
%   accuracies_reps: 一个向量，包含每次重复的平均解码准确率。
%                    维度: [n_repetitions x 1]
%   avg_weights:     在所有重复和折叠中平均后的解码器权重。
%                    格式与 fitcdiscr 的 .Coeffs 结构一致。

% --- 1. 初始化 ---
accuracies_reps = zeros(config.n_repetitions, 1);
% 用于存储所有模型权重的临时容器
linear_weights_all = cell(config.n_repetitions, config.k_fold);

% --- 2. 多次重复的主循环 ---
for rep_idx = 1:config.n_repetitions
    % 每次重复都创建新的分区，以获得对数据不同划分的稳健估计
    cv = cvpartition(labels, 'KFold', config.k_fold);
    fold_accuracies = zeros(1, config.k_fold);

    % --- 2.1 K-Fold 交叉验证循环 ---
    for f = 1:config.k_fold
        trainIdx = cv.training(f);
        testIdx  = cv.test(f);

        X_train = X(trainIdx, :);
        X_test  = X(testIdx, :);
        y_train = labels(trainIdx);
        y_test  = labels(testIdx);

        % 在每个折叠内部，仅使用训练集数据进行标准化
        mu = mean(X_train, 1);
        sigma = std(X_train, 0, 1);
        sigma(sigma == 0) = 1; % 防止除以零

        X_train_std = (X_train - mu) ./ sigma;
        X_test_std  = (X_test - mu) ./ sigma;

        % 训练和测试分类器 (LDA)
        model = fitcdiscr(X_train_std, y_train, 'DiscrimType', 'pseudoLinear');
        pred = predict(model, X_test_std);

        % 计算并存储当前折叠的准确率和模型权重
        fold_accuracies(f) = mean(pred == y_test);
        linear_weights_all{rep_idx, f} = model.Coeffs;
    end

    % 存储本次重复的平均准确率
    accuracies_reps(rep_idx) = mean(fold_accuracies);
end

% --- 3. 平均所有解码器权重 ---
% 这个过程与您原始代码中的权重平均逻辑完全相同
avg_weights = average_model_weights(linear_weights_all, config);

end


% --- 辅助函数：平均模型权重 ---
function avg_coeffs_final = average_model_weights(all_coeffs, config)
    % 初始化累加器
    sum_coeffs_linear = cell(config.n_cluster, config.n_cluster);
    for i = 1:config.n_cluster
        for j = 1:config.n_cluster
            if i ~= j
                sum_coeffs_linear{i, j} = zeros(config.n_coil, 1);
            end
        end
    end

    % 遍历所有存储的权重并累加
    [n_reps, n_folds] = size(all_coeffs);
    for rep = 1:n_reps
        for f = 1:n_folds
            current_coeffs = all_coeffs{rep, f};
            if ~isempty(current_coeffs)
                for i = 1:config.n_cluster
                    for j = 1:config.n_cluster
                        if i < j % fitcdiscr的Coeffs是上三角/下三角矩阵
                            sum_coeffs_linear{i, j} = sum_coeffs_linear{i, j} + current_coeffs(i, j).Linear;
                            sum_coeffs_linear{j, i} = sum_coeffs_linear{j, i} + current_coeffs(j, i).Linear;
                        end
                    end
                end
            end
        end
    end

    % 计算平均值
    avg_coeffs_final = cell(config.n_cluster, config.n_cluster);
    total_models = n_reps * n_folds;
    for i = 1:config.n_cluster
        for j = 1:config.n_cluster
            if i ~= j
                avg_coeffs_final{i, j} = sum_coeffs_linear{i, j} / total_models;
            end
        end
    end
end