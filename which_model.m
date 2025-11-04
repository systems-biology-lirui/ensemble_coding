%% 1. 生成模拟的真实数据 (用你的真实数据替换这部分)
% =========================================================================

rng('default'); % for reproducibility

n_orientations = 2;
n_repeats = 87;
n_channels = 20;
channel1 =[74,67,68,72,45,38,40,86,7,87,58,91,92,25,94,29,64,61,56,30];
X_raw = cat(1,squeeze(SG(1).Data(1:87,channel1,45)),squeeze(SG(9).Data(1:87,channel1,45)));
Y = [zeros(87,1);ones(87,1)];
% 2. 准备不同模型所需的数据
% =========================================================================
% 用于BNB的二值化数据
% X = round(X_raw);
X_binary = double(X_raw > 0); 
X = X_raw;

% 3. 设置和运行交叉验证
% =========================================================================
fprintf('--- 开始10折交叉验证 ---\n');
kFolds = 10;
cv = cvpartition(Y, 'KFold', kFolds);

% --- 模型1: 伯努利朴素贝叶斯 (BNB) ---
% 'mvmn' 在这里处理二值数据时就是伯努利
model_bnb = fitcnb(X_binary, Y, 'DistributionNames', 'mvmn', 'CrossVal', 'on', 'CVPartition', cv);
accuracy_bnb = 1 - kfoldLoss(model_bnb);

% --- 模型2: 泊松朴素贝叶斯 (PNB) ---
% fitcnb没有内置泊松，我们手动实现交叉验证
Y_pred_pnb = zeros(size(Y));
for i = 1:kFolds
    % 获取当前折的训练和测试索引
    idx_train = training(cv, i);
    idx_test = test(cv, i);
    
    % 手动训练PNB
    X_train_fold = X(idx_train, :);
    Y_train_fold = Y(idx_train, :);
    lambda_params_fold = [
        mean(X_train_fold(Y_train_fold==0, :)); % C_0
        mean(X_train_fold(Y_train_fold==1, :))  % C_1
    ];
    
    % --- 关键修正：拉普拉斯平滑 ---
    % 将所有为0的lambda替换为一个非常小的正数，以防止log(0)错误
    epsilon = 1e-9; % 一个极小值
    lambda_params_fold(lambda_params_fold == 0) = epsilon; 

    % 在测试集上预测
    X_test_fold = X(idx_test, :);
    for j = 1:size(X_test_fold, 1)
        x_test = X_test_fold(j, :);
        % 使用修正后的lambda参数进行计算
        log_likelihood_0 = sum(log(poisspdf(x_test, lambda_params_fold(1, :))));
        log_likelihood_1 = sum(log(poisspdf(x_test, lambda_params_fold(2, :))));
        
        % 检查是否有-Inf，以防万一（例如x_test值极大）
        if isinf(log_likelihood_0) && isinf(log_likelihood_1)
            % 如果两者都崩溃，我们无法决策，可以随机猜或保持原样
            % 这里我们保持预测为0，但这种情况在平滑后几乎不会发生
            Y_pred_pnb(idx_test(j)) = 0; 
        elseif log_likelihood_1 > log_likelihood_0
            Y_pred_pnb(idx_test(j)) = 1;
        else
            Y_pred_pnb(idx_test(j)) = 0;
        end
    end
end
accuracy_pnb = sum(Y_pred_pnb == Y) / length(Y);

%
% --- 模型3: 高斯朴素贝叶斯 (GNB) ---

model_gnb = fitcnb(X, Y, 'DistributionNames', 'normal', 'CrossVal', 'on', 'CVPartition', cv);
accuracy_gnb = 1 - kfoldLoss(model_gnb);

% --- 模型4: 线性判别分析 (LDA) ---
% 'fitcdiscr' 用于训练判别分析模型
model_lda = fitcdiscr(X, Y, 'CrossVal', 'on', 'CVPartition', cv);
accuracy_lda = 1 - kfoldLoss(model_lda);

% --- 模型5: 支持向量机 (SVM) ---
% 我们使用带有线性核函数的SVM，使其与LDA具有可比性
% 'fitcsvm' 用于训练SVM模型
% 'KernelFunction','linear' 指定了线性SVM
model_svm = fitcsvm(X, Y, 'KernelFunction', 'linear', 'CrossVal', 'on', 'CVPartition', cv);
accuracy_svm = 1 - kfoldLoss(model_svm);

% 4. 结果展示
% =========================================================================
fprintf('\n--- 交叉验证解码准确率 ---\n');
fprintf('  伯努利 NB: %.4f (%.2f%%)\n', accuracy_bnb, accuracy_bnb * 100);
fprintf('  泊松 NB:   %.4f (%.2f%%)\n', accuracy_pnb, accuracy_pnb * 100);
fprintf('  高斯 NB:   %.4f (%.2f%%)\n', accuracy_gnb, accuracy_gnb * 100);
fprintf('  LDA:       %.4f (%.2f%%)\n', accuracy_lda, accuracy_lda * 100);
fprintf('  SVM (Linear): %.4f (%.2f%%)\n', accuracy_svm, accuracy_svm * 100); % <-- 新增行

% 可视化
figure;
accuracies = [accuracy_bnb, accuracy_pnb, accuracy_gnb, accuracy_lda, accuracy_svm]; % <-- 新增 accuracy_svm
bar(accuracies);
set(gca, 'XTickLabel', {'Bernoulli NB', 'Poisson NB', 'Gaussian NB', 'LDA', 'SVM (Linear)'}); % <-- 新增 'SVM (Linear)'
ylabel('Accuracy');
title('不同解码器在真实数据上的性能比较');
ylim_min = min(accuracies) - 0.05;
ylim_max = max(accuracies) + 0.05;
if ylim_min < 0, ylim_min=0; end
if ylim_max > 1, ylim_max=1; end
ylim([ylim_min, ylim_max]);
grid on;
text(1:5, accuracies, num2str(accuracies', '%.4f'), ... % <-- 修改 1:4 为 1:5
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');