function [accuracies_cv_train, accuracies_test] = generalizationDecoding(trainData, testData, decodingMode)
%generalizationDecoding 对 M/EEG 数据进行时间泛化解码分析
%
%   用法:
%       [cv_acc_vector, test_acc_vector] = generalizationDecoding(trainData, testData, 'temporal')
%       [cv_acc_matrix, test_acc_matrix] = generalizationDecoding(trainData, testData, 'cross-temporal')
%
%   输入:
%       trainData    - 训练数据 (4D 矩阵: 朝向 x 重复 x 通道 x 时间点)
%       testData     - 测试数据 (4D 矩阵: 朝向 x 重复 x 通道 x 时间点)
%       decodingMode - 解码模式 (字符串):
%                      'temporal' (默认): 在每个时间点t上训练，并在相同时间点t上测试。
%                                          输出均为 1 x nTimePoints 的向量。
%                      'cross-temporal': 在每个时间点t_train上训练，并在所有时间点t_test上测试。
%                                        输出均为 nTimePoints x nTimePoints 的矩阵。
%
%   输出:
%       accuracies_cv_train - 训练集上的交叉验证正确率。
%       accuracies_test     - 独立测试集上的泛化正确率。
%                             输出维度由 decodingMode 决定。

% --- Step 0: 参数检查与默认值设定 ---
if nargin < 3
    decodingMode = 'temporal';
end

% --- Step 1: 准备工作 ---
disp('Step 1: Initializing variables...');

% 定义数据维度
[nOrientations, nTrainRepeats, nChannels, nTimePoints] = size(trainData);
[~, nTestRepeats, ~, ~] = size(testData);

% 计算样本总数
nTrainSamples = nOrientations * nTrainRepeats;
nTestSamples = nOrientations * nTestRepeats;

% 创建标签向量
Y_train = repelem((1:nOrientations)', nTrainRepeats, 1);
Y_test  = repelem((1:nOrientations)', nTestRepeats, 1);

% 定义分类器模板和交叉验证参数
kFolds = 5;
template = templateDiscriminant('DiscrimType', 'pseudoLinear');

% 预分配内存
switch decodingMode
    case 'temporal'
        disp('Mode: Temporal Decoding (Train at t, Test at t)');
        accuracies_cv_train = zeros(1, nTimePoints);
        accuracies_test = zeros(1, nTimePoints);
    case 'cross-temporal'
        disp('Mode: Cross-Temporal Decoding (Train at t_train, Test at t_test)');
        accuracies_cv_train = zeros(nTimePoints, nTimePoints); % 结果将是 T x T 矩阵
        accuracies_test = zeros(nTimePoints, nTimePoints); % 结果将是 T x T 矩阵
    otherwise
        error("Invalid decodingMode. Choose 'temporal' or 'cross-temporal'.");
end

% 创建一个固定的交叉验证分区，以确保在所有时间点上样本的划分方式都相同
% 这是实现跨时间点交叉验证的关键！
cvp = cvpartition(Y_train, 'KFold', kFolds);

disp(['Total training samples: ', num2str(nTrainSamples)]);
disp(['Total testing samples: ', num2str(nTestSamples)]);
disp('Initialization complete.');
disp('-----------------------------------');

% --- Step 2: 根据选择的模式执行解码循环 ---
disp(['Step 2: Starting classification loop (Mode: ', decodingMode, ')...']);
delay = 2;
switch decodingMode
    
    case 'temporal' % 原始功能：高效的对角线解码
        parfor t = 1:nTimePoints
            if t <=  delay
                idx = 1:(t+delay)
            elseif t> 100-delay
                idx = t:100;
            else
                idx = (t-delay):(t+delay);
            end

               
            % 提取和重塑当前时间点的数据
            X_train_t = reshape(permute(squmean(trainData(:, :, :, idx),4), [2, 1, 3]), [nTrainSamples, nChannels]);
            X_test_t  = reshape(permute(squmean(testData(:, :, :, idx),4), [2, 1, 3]), [nTestSamples, nChannels]);
            
            % Part A: 交叉验证 (使用高效的内置函数)
            cv_model = fitcecoc(X_train_t, Y_train, 'Learners', template, 'CVPartition', cvp);
            cv_loss = kfoldLoss(cv_model);
            accuracies_cv_train(t) = 1 - cv_loss;
            
            % Part B: 在独立测试集上测试
            % final_model = fitcecoc(X_train_t, Y_train, 'Learners', template);
            % predictions = predict(final_model, X_test_t);
            % accuracies_test(t) = sum(predictions == Y_test) / nTestSamples;
            
            if mod(t, 20) == 0
                fprintf('Temporal Decoding - Time point %d/%d processed.\n', t, nTimePoints);
            end
        end

    case 'cross-temporal' % 新功能：完全的跨时间点解码
        disp('Performing full cross-temporal analysis. This may take a while...');
        % 优化：预先重塑所有数据，避免在循环内重复操作
        X_train_all_times = reshape(permute(trainData, [2, 1, 3, 4]), [nTrainSamples, nChannels, nTimePoints]);
        X_test_all_times  = reshape(permute(testData,  [2, 1, 3, 4]), [nTestSamples,  nChannels, nTimePoints]);
        
        parfor t_train = 1:nTimePoints
            % 获取当前训练时间点的数据
            X_train_current = X_train_all_times(:, :, t_train);
            
            % 初始化临时行向量以适应 parfor
            temp_cv_row = zeros(1, nTimePoints);
            temp_test_row = zeros(1, nTimePoints);
            
            % --- Part B: 训练一个用于独立测试集的最终模型 (在循环外完成) ---
            final_model = fitcecoc(X_train_current, Y_train, 'Learners', template);

            for t_test = 1:nTimePoints
                % --- Part A: 手动执行跨时间点交叉验证 ---
                fold_accuracies = zeros(kFolds, 1);
                for k = 1:kFolds
                    % 获取当前折的训练和测试样本索引
                    train_idx = training(cvp, k);
                    test_idx  = test(cvp, k);
                    
                    % 准备训练数据 (来自 t_train)
                    X_train_fold = X_train_current(train_idx, :);
                    Y_train_fold = Y_train(train_idx);
                    
                    % 准备测试数据 (来自 t_test)
                    X_test_fold = X_train_all_times(test_idx, :, t_test);
                    Y_test_fold = Y_train(test_idx); % 标签是不变的
                    
                    % 训练单折模型
                    model_fold = fitcecoc(X_train_fold, Y_train_fold, 'Learners', template);
                    
                    % 预测并计算该折的准确率
                    predictions_fold = predict(model_fold, X_test_fold);
                    fold_accuracies(k) = sum(predictions_fold == Y_test_fold) / numel(Y_test_fold);
                end
                % 对所有折的准确率求平均，得到 (t_train, t_test) 的CV准确率
                temp_cv_row(t_test) = mean(fold_accuracies);
                
                % --- Part B: 在独立测试集上进行泛化测试 ---
                % 获取当前测试时间点的数据
                X_test_current = X_test_all_times(:, :, t_test);
                % 使用之前训练好的 final_model 进行预测
                predictions = predict(final_model, X_test_current);
                temp_test_row(t_test) = sum(predictions == Y_test) / nTestSamples;
            end
            
            % 将计算好的一整行结果赋给最终矩阵
            accuracies_cv_train(t_train, :) = temp_cv_row;
            accuracies_test(t_train, :) = temp_test_row;
            
            if mod(t_train, 10) == 0
                fprintf('Cross-Temporal - Training time point %d/%d processed.\n', t_train, nTimePoints);
            end
        end
end

disp('-----------------------------------');
disp('Decoding complete.');
end