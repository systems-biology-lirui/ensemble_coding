function [acc_real_mean, p_value, perm_accuracies_mean, detailed_results, linear_weight] = SVM_Decoding_LR(decodingdata, do_permutation, n_shuffles, n_repetitions)
% SVM_DECODING_LR_V2 - 执行MVPA解码，通过多次重复提高稳定性，并使用t检验计算p值。
%
% 语法:
%   [acc_real_mean, p_value, perm_accuracies_mean, detailed_results] = ...
%       SVM_Decoding_LR_v2(decodingdata, do_permutation, n_shuffles, n_repetitions)
%
% 描述:
%   此函数对数据进行逐时间点的MVPA。与原始版本相比，它进行了两项关键改进：
%   1.  为了处理试次间(repeat)的高变异性，函数对每个时间点的真实准确率计算执行多次重复
%       (n_repetitions)，每次重复都使用全新的交叉验证分区。最终的真实准确率是这些
%       重复的平均值。
%   2.  p值的计算方法被修改为独立的双样本t检验。它比较了“真实准确率分布”
%       (来自n_repetitions次重复)与“置换准确率分布”(来自n_shuffles次排列)的差异，
%       从而评估解码效果的显著性。这对于当机会水平附近的数据分布非正态或
%       当真实准确率分布本身也有变异时，是更稳健的方法。
%
% 输入:
%   decodingdata:   数据矩阵，维度 [n_cluster, n_repeat, n_coil, n_time]。
%   do_permutation: 布尔值 (true/false)。
%                   - true: 执行排列检验，计算p值。
%                   - false: 只计算真实解码准确率。
%   n_shuffles:     排列检验的次数 (当 do_permutation=true 时)。
%   n_repetitions:  【新增】为稳定真实准确率而进行的重复次数。建议值为10-100。
%
% 输出:
%   acc_real_mean:      每个时间点的平均真实解码准确率 (n_repetitions次重复的均值)。
%                       维度: [1, n_time]
%   p_value:            每个时间点的p值 (通过t检验计算)。如果不执行排列，则返回[]。
%                       维度: [1, n_time] or []
%   perm_accuracies_mean: 每个时间点的平均置换准确率 (n_shuffles次排列的均值)。
%                         如果不执行排列，则返回[]。
%   detailed_results:   一个结构体，包含更详细的结果：
%     .real_acc_dist:     {1, n_time} cell, 每个cell包含n_repetitions次重复的真实准确率。
%     .perm_acc_dist:     {1, n_time} cell, 每个cell包含n_shuffles次排列的置换准确率分布。
%     .acc_real_all_folds: (已移除以简化，可根据需要加回)

% --- 参数校验与默认值设定 ---
if nargin < 4
    n_repetitions = 10; % 为重复次数设置一个默认值
    fprintf('n_repetitions not specified, using default value: %d\n', n_repetitions);
end
if ~do_permutation
    n_shuffles = 0;
end

tic;

% --- 1. 初始化和参数准备 ---
k = 3; % K-Fold 交叉验证折数

[n_cluster, n_repeat, n_coil, n_time] = size(decodingdata);
num_samples = n_cluster * n_repeat;

% 创建原始标签向量
labels_original = repelem((1:n_cluster)', n_repeat);

rng('default'); % 保证可复现性

% 初始化主要输出变量
acc_real_mean = zeros(1, n_time);
if do_permutation
    p_value = ones(1, n_time); % 初始化为1
    perm_accuracies_mean = zeros(1, n_time);
else
    p_value = [];
    perm_accuracies_mean = [];
end

% 初始化用于存储详细结果的临时容器
tmp_real_acc_dist = cell(1, n_time);
if do_permutation
    tmp_perm_acc_dist = cell(1, n_time);
end

fprintf('Starting decoding...\n');
fprintf('Settings: %d-Fold CV, %d time points, %d repetitions for real accuracy.\n', k, n_time, n_repetitions);
if do_permutation
    fprintf('Permutation test is ENABLED with %d shuffles.\n', n_shuffles);
else
    fprintf('Permutation test is DISABLED.\n');
end
fprintf('----------------------------------------\n');

% --- 2. 逐时间点解码循环 (推荐使用 parfor 加速) ---
% 注意: 如果要使用parfor，请确保你的MATLAB安装了 Parallel Computing Toolbox
% for t_idx = 1:n_time
linear_weight = cell(1,n_time);
parfor t_idx = 1:n_time

    if mod(t_idx, 20) == 0 || t_idx == 1
        fprintf('Processing time point %d/%d...\n', t_idx, n_time);
    end

    % --- 数据准备 ---
    delay = 1; % 时间平滑窗口的半径
    if t_idx  <= delay
        t_win = 1:t_idx;
    elseif t_idx+delay > n_time
        t_win = t_idx:n_time;
    else
        t_win =  (t_idx-delay):(t_idx+delay);
    end

    X_time_t = squeeze(mean(decodingdata(:, :, :,t_win),4));
    X = reshape(permute(X_time_t, [2, 1, 3]), num_samples, n_coil);

    % --- 2.1 计算真实解码准确率 (多次重复) ---
    % 这一步的目的是得到一个真实准确率的分布，用于后续的t检验
    real_accuracies_reps = zeros(n_repetitions, 1);
    linear_weights = cell(n_repetitions,k);
    for rep_idx = 1:n_repetitions
        cv = cvpartition(labels_original, 'KFold', k); % 每次重复都创建新的分区
        fold_acc_real = zeros(1, k);
        for f = 1:k
            trainIdx = cv.training(f);
            testIdx  = cv.test(f);

            % 在每个折叠内部，仅使用训练集数据进行标准化
            mu = mean(X(trainIdx, :), 1);
            sigma = std(X(trainIdx, :), 0, 1);
            sigma(sigma == 0) = 1;

            X_train_std = (X(trainIdx, :) - mu) ./ sigma;
            X_test_std  = (X(testIdx, :) - mu) ./ sigma;

            % 训练和测试分类器 (注意：函数名是SVM，但这里用的是LDA)
            % 为了与你的代码保持一致，继续使用fitcdiscr
            model = fitcdiscr(X_train_std, labels_original(trainIdx), 'DiscrimType', 'pseudoLinear');
            % idx = tril(true(n_cluster),-1);
            linear_weights{rep_idx,f} = model.Coeffs;
            pred = predict(model, X_test_std);

            fold_acc_real(f) = mean(pred == labels_original(testIdx));
        end
        % 存储本次重复的平均准确率
        real_accuracies_reps(rep_idx) = mean(fold_acc_real);
    end
    % --- 专家建议：在此处进行权重平均 (在时间点循环的末尾) ---

    % 初始化累加器
    sum_coeffs_linear = cell(n_cluster, n_cluster);
    for i = 1:n_cluster
        for j = 1:n_cluster
            if i ~= j
                sum_coeffs_linear{i, j} = zeros(n_coil, 1); % 使用列向量
            end
        end
    end

    % 遍历当前时间点的所有权重并累加
    for rep = 1:n_repetitions
        for f = 1:k
            current_coeffs = linear_weights{rep, f};
            if ~isempty(current_coeffs)
                for i = 1:n_cluster
                    for j = 1:n_cluster
                        if i ~= j && ~isempty(current_coeffs(i,j).Linear)
                            sum_coeffs_linear{i, j} = sum_coeffs_linear{i, j} + current_coeffs(i, j).Linear;
                        end
                    end
                end
            end
        end
    end

    % 计算平均值并构建最终结构
    avg_coeffs_t = cell(n_cluster, n_cluster);
    total_models = n_repetitions * k;
    for i = 1:n_cluster
        for j = 1:n_cluster
            if i ~= j
                avg_weights_vector = sum_coeffs_linear{i, j} / total_models;
                % 将平均后的权重存入与原始 Coeffs 单元格相似的结构体中
                avg_coeffs_t{i, j} = avg_weights_vector;
            end
        end
    end

    % 将此时间点的最终平均权重存入输出变量
    linear_weight{1,t_idx} = avg_coeffs_t;

    % 计算该时间点最终的平均真实准确率，并存储其分布
    acc_real_mean(t_idx) = mean(real_accuracies_reps);
    tmp_real_acc_dist{t_idx} = real_accuracies_reps;

    % --- 2.2 条件执行排列检验 ---
    if do_permutation
        perm_accuracies_at_t = zeros(n_shuffles, 1);

        % 同样地，为排列测试创建一个固定的交叉验证分区，以减少随机性
        % 注意：严格来说，每次打乱都应独立于真实数据分析。
        % 这里的cvpartition仅为排列测试的内部k-fold服务。
        cv_perm = cvpartition(labels_original, 'KFold', k);

        for p_idx = 1:n_shuffles
            % 在整个数据集上打乱标签一次
            shuffled_labels = labels_original(randperm(num_samples));

            fold_acc_perm = zeros(1, k);
            for f = 1:k
                trainIdx = cv_perm.training(f);
                testIdx  = cv_perm.test(f);

                % 标准化与真实解码完全相同
                mu = mean(X(trainIdx, :), 1);
                sigma = std(X(trainIdx, :), 0, 1);
                sigma(sigma == 0) = 1;
                X_train_std = (X(trainIdx, :) - mu) ./ sigma;
                X_test_std  = (X(testIdx, :) - mu) ./ sigma;

                % 使用打乱后的标签进行训练和测试
                model_perm = fitcdiscr(X_train_std, shuffled_labels(trainIdx), 'DiscrimType', 'pseudoLinear');
                pred_perm = predict(model_perm, X_test_std);
                fold_acc_perm(f) = mean(pred_perm == shuffled_labels(testIdx));
            end
            % 存储本次排列的平均准确率
            perm_accuracies_at_t(p_idx) = mean(fold_acc_perm);
        end

        % 存储该时间点的置换准确率均值和分布
        perm_accuracies_mean(t_idx) = mean(perm_accuracies_at_t);
        tmp_perm_acc_dist{t_idx} = perm_accuracies_at_t;

        % --- 2.3 【核心修改】使用t检验计算p值 ---
        % 我们比较两个独立的分布：
        % 1. real_accuracies_reps: n_repetitions个真实准确率
        % 2. perm_accuracies_at_t: n_shuffles个置换准确率
        % 检验的假设是：真实准确率显著高于置换准确率。
        % 因此，我们使用单尾t检验 (right-tailed)。
        [~, p] = ttest2(real_accuracies_reps, perm_accuracies_at_t, 'Tail', 'right', 'Vartype', 'unequal');
        p_value(t_idx) = p;
    end
end

% --- 3. 整合结果 ---
detailed_results = struct();
detailed_results.real_acc_dist = tmp_real_acc_dist;
if do_permutation
    detailed_results.perm_acc_dist = tmp_perm_acc_dist;
else
    detailed_results.perm_acc_dist = {};
end


toc;
fprintf('----------------------------------------\n');
fprintf('Decoding finished.\n');


end
