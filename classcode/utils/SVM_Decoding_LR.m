function [acc_real_mean, p_value, perm_accuracies_mean,detailed_results] = SVM_Decoding_LR(decodingdata, do_permutation, n_shuffles)
% SVM_DECODING_LR - 执行MVPA解码，并可选择性地进行排列检验。
%
% 语法:
%   [acc_real_mean, p_value, perm_accuracies_mean, detailed_results] = ...
%       SVM_Decoding_LR(decodingdata, label, do_permutation, n_shuffles)
%
% 描述:
%   该函数对给定的多维数据 (decodingdata) 进行逐时间点的多变量模式分析 (MVPA)。
%   它计算了真实的解码准确率，并能选择性地通过排列检验来评估其显著性。
%
% 输入:
%   decodingdata:   数据矩阵，维度 [n_cluster, n_repeat, n_coil, n_time]。
%                   n_cluster: 类别/条件数
%                   n_repeat: 每个类别的重复次数/试验数
%                   n_coil: 特征数 (例如，通道数、体素数)
%                   n_time: 时间点数
%   do_permutation: 布尔值 (true/false)。
%                   - true: 执行排列检验，计算p值。
%                   - false: 只计算真实解码准确率，跳过排列检验 (速度快)。
%   n_shuffles:     排列检验的次数 (仅在 do_permutation 为 true 时需要)。
%                   如果 do_permutation 为 false，可以传入任意值或 []。
%
% 输出:
%   acc_real_mean:      每个时间点的平均真实解码准确率。
%                       维度: [1, n_time]
%   p_value:            每个时间点的p值。如果不执行排列检验，则返回空数组 []。
%                       维度: [1, n_time] or []
%   perm_accuracies_mean: 每个时间点上，所有排列的平均解码准确率的均值。
%                         如果不执行排列检验，则返回空数组 []。
%                         维度: [1, n_time] or []
%   detailed_results:   一个结构体，包含更详细的结果，方便后续分析：
%     .acc_real_all_folds: {1, n_time} cell, 每个cell包含k折的真实准确率。
%     .real_labels:        {1, n_time} cell, 每个cell包含k折的真实标签。
%     .real_predictions:   {1, n_time} cell, 每个cell包含k折的预测标签。
%     .perm_acc_dist:      {1, n_time} cell, 每个cell包含该时间点的排列准确率分布。
%                          (如果不执行排列，则为空)

% --- 参数校验与默认值设定 ---
if ~do_permutation
    n_shuffles = 0; % 如果不执行，将次数设为0
end

tic;

% --- 1. 初始化和参数准备 ---
k = 5; % K-Fold 交叉验证折数

[n_cluster, n_repeat, n_coil, n_time] = size(decodingdata);
num_samples = n_cluster * n_repeat;

% 创建原始标签向量
labels_original = repelem((1:n_cluster)', n_repeat); % 更稳健的标签创建方式

% 提前创建交叉验证分区，确保真实解码和排列检验使用相同的分区
rng('default'); % 保证可复现性
cv = cvpartition(labels_original, 'KFold', k);

% 初始化主要输出变量
acc_real_mean = zeros(1, n_time);

% 根据 do_permutation 初始化可选输出变量
if do_permutation
    p_value = zeros(1, n_time);
    perm_accuracies_mean = zeros(1, n_time);
else
    p_value = [];
    perm_accuracies_mean = [];
end

% 初始化用于存储详细结果的临时容器
tmp_acc_real_all_folds = cell(1, n_time);
tmp_real_labels = cell(1, n_time);
tmp_real_predictions = cell(1, n_time);
if do_permutation
    tmp_perm_acc_dist = cell(1, n_time);
end

fprintf('Starting decoding...\n');
fprintf('Settings: %d-Fold CV, %d time points.\n', k, n_time);
if do_permutation
    fprintf('Permutation test is ENABLED with %d shuffles.\n', n_shuffles);
else
    fprintf('Permutation test is DISABLED.\n');
end
fprintf('----------------------------------------\n');

% --- 2. 逐时间点解码循环 (使用 parfor 加速) ---
for t_idx = 1:n_time
    
    % 在 parfor 内部使用 disp/fprintf 需要特殊处理，这里使用一个简单的计数器
    if mod(t_idx, 20) == 0 || t_idx == 1
        fprintf('Processing time point %d/%d...\n', t_idx, n_time);
    end
    
    % 提取并重塑当前时间点的数据
    X_time_t = squeeze(decodingdata(:, :, :, t_idx));
    X = reshape(permute(X_time_t, [2, 1, 3]), num_samples, n_coil);
    
    % --- 2.1 计算真实解码准确率 ---
    fold_acc_real = zeros(1, k);
    current_time_labels = cell(1, k);
    current_time_predictions = cell(1, k);
    
    for f = 1:k
        trainIdx = cv.training(f);
        testIdx  = cv.test(f);
        
        % 在每个折叠内部，仅使用训练集数据进行标准化
        mu = mean(X(trainIdx, :), 1);
        sigma = std(X(trainIdx, :), 0, 1);
        sigma(sigma == 0) = 1; % 防止除以零

        X_train_std = (X(trainIdx, :) - mu) ./ sigma;
        X_test_std  = (X(testIdx, :) - mu) ./ sigma;

        % 训练和测试分类器
        model = fitcdiscr(X_train_std, labels_original(trainIdx), 'DiscrimType', 'pseudoLinear');
        % model = fitcecoc(X_train_std, labels_original(trainIdx), 'Learners', templateSVM('KernelFunction', 'linear'), 'Coding', 'onevsall');
        pred = predict(model, X_test_std);
        
        fold_acc_real(f) = mean(pred == labels_original(testIdx));
        current_time_labels{f} = labels_original(testIdx);
        current_time_predictions{f} = pred;
    end
    
    acc_real_mean(t_idx) = mean(fold_acc_real);
    
    % 在parfor循环中将结果存储到临时变量
    tmp_acc_real_all_folds{t_idx} = fold_acc_real;
    tmp_real_labels{t_idx} = current_time_labels;
    tmp_real_predictions{t_idx} = current_time_predictions;

    % --- 2.2 条件执行排列检验 ---
    if do_permutation
        perm_accuracies_at_t = zeros(n_shuffles, 1);
        
        for p_idx = 1:n_shuffles
            % 打乱标签。注意：在交叉验证框架内打乱标签是严谨的做法
            labels_shuffled = labels_original(randperm(num_samples));
            
            fold_acc_perm = zeros(1, k);
            for f = 1:k
                trainIdx = cv.training(f);
                testIdx  = cv.test(f);

                % 标准化步骤与真实解码完全相同
                mu = mean(X(trainIdx, :), 1);
                sigma = std(X(trainIdx, :), 0, 1);
                sigma(sigma == 0) = 1;
                X_train_std = (X(trainIdx, :) - mu) ./ sigma;
                X_test_std  = (X(testIdx, :) - mu) ./ sigma;
                
                % 使用打乱后的标签进行训练
                model_perm = fitcdiscr(X_train_std, labels_shuffled(trainIdx), 'DiscrimType', 'diaglinear');
                
                % 预测并与打乱后的测试标签比较
                pred_perm = predict(model_perm, X_test_std);
                fold_acc_perm(f) = mean(pred_perm == labels_shuffled(testIdx));
            end
            perm_accuracies_at_t(p_idx) = mean(fold_acc_perm);
        end
        
        % 存储该时间点的排列检验结果
        perm_accuracies_mean(t_idx) = mean(perm_accuracies_at_t);
        p_value(t_idx) = (sum(perm_accuracies_at_t >= acc_real_mean(t_idx)) + 1) / (n_shuffles + 1);
        tmp_perm_acc_dist{t_idx} = perm_accuracies_at_t;
    end
end

% 在parfor循环结束后，将临时变量整合到输出结构体中
detailed_results = struct();
detailed_results.acc_real_all_folds = tmp_acc_real_all_folds;
detailed_results.real_labels = tmp_real_labels;
detailed_results.real_predictions = tmp_real_predictions;
if do_permutation
    detailed_results.perm_acc_dist = tmp_perm_acc_dist;
end

% 如果需要详细结果作为输出，可以将函数定义修改为：
% [acc_real_mean, p_value, perm_accuracies_mean, detailed_results] = ...

toc;
fprintf('----------------------------------------\n');
fprintf('Decoding finished.\n');

end
