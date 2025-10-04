function [Accuracy_all, Chance_level, True_labels, Predictions] = alldecodingcode(All_data_pre,condition, model, coilnum, window)
% 加载数据
minnum = inf;

% 找到最小数据量
for ori = 1:18
    minnum = min(minnum, size(All_data_pre{condition, ori}, 1));
end


data0 = zeros(18,minnum,coilnum,length(window));

load('/home/dclab2/Ensemble coding/data/SNR.mat','coilSNR');
[~,coilidx] = sort(coilSNR,'descend');
coilselect = coilidx(1:coilnum);
% 数据量匹配
for ori = 1:18
    a = size(All_data_pre{condition,ori},1);
    selected_numbers = randperm(a, minnum);
    for i = 1:length(selected_numbers)
        for coil = 1:length(coilselect)
            data0(ori,i,coil,:) = squeeze(All_data_pre{condition,ori}(selected_numbers(i),coilselect(coil),:));
        end
    end
end

% coil筛选


% 选择解码模型
if strcmp(model, "PID")
    [Accuracy_all, Chance_level, True_labels, Predictions] = PIDdecoding(data0);
else
    [Accuracy_all, Chance_level, True_labels, Predictions] = SVMdecoding(data0);
end
end

function [Accuracy_all, Chance_level, True_labels, Predictions] = PIDdecoding(data0)
% PIDdecoding - 采用泊松似然估计进行解码
%
% 输入:
%   data0 - 4D 数据矩阵, 维度为 [18朝向 x 280重复 x 20线圈 x 120时间点]
%
% 输出:
%   Accuracy_all - 每次迭代、每个时间点的解码准确率 (numIterations x numTimePoints)
%   Chance_level - 随机预测的解码准确率 (numIterations x numTimePoints)
%   True_labels  - cell 数组，存储每个时间点的真实标签
%   Predictions  - cell 数组，存储每个时间点的预测标签

%% 参数设置
[numOrientations, numRepeats, numCoils, numTimePoints] = size(data0);  % [18, 280, 20, 120]
numIterations = 50;  % 交叉验证重复次数
numFolds = 5;        % K折交叉验证

%% 预分配结果变量
Accuracy_all = zeros(numIterations, numTimePoints);
Chance_level = zeros(numIterations, numTimePoints);
True_labels  = cell(numTimePoints, numIterations);
Predictions  = cell(numTimePoints, numIterations);

%% 交叉验证循环
for iter = 1:numIterations
    fprintf('第 %d/%d 次迭代...\n', iter, numIterations);
    
    % 生成 K-fold 交叉验证索引
    foldIndices = cell(numOrientations, 1);
    for ori = 1:numOrientations
        foldIndices{ori} = crossvalind('Kfold', numRepeats, numFolds);
    end
    
    % 遍历所有时间点
    for t = 1:numTimePoints
        pred_all = [];      % 存储所有测试试次的预测结果
        true_all = [];      % 存储所有测试试次的真实标签
        pred_chance_all = [];  % 存储随机猜测的标签
        
        % 交叉验证
        for fold = 1:numFolds
            % 计算所有朝向的调谐曲线
            tuning_curves = zeros(numOrientations, numCoils);
            for ori = 1:numOrientations
                train_idx = foldIndices{ori} ~= fold; % 训练集索引
                tuning_curves(ori, :) = mean(squeeze(data0(ori, train_idx, :, t)), 1);
            end
            
            % 避免对数计算中的数值问题
            tuning_curves = max(tuning_curves, 1e-6);
            
            % 处理测试数据
            for ori = 1:numOrientations
                test_idx = find(foldIndices{ori} == fold);
                test_data = squeeze(data0(ori, test_idx, :, t)); % [numTestTrials x numCoils]
                
                % 计算泊松对数似然
                log_likelihoods = test_data * log(tuning_curves)' - sum(tuning_curves, 2)';
                [~, pred_labels] = max(log_likelihoods, [], 2);  % 选取最大似然的朝向
                
                % 随机基线预测
                random_oris = randi(numOrientations, length(pred_labels), 1);
                
                % 存储结果
                pred_all = [pred_all; pred_labels];
                true_all = [true_all; ori * ones(length(pred_labels), 1)];
                pred_chance_all = [pred_chance_all; random_oris];
            end
        end
        
        % 计算准确率
        Accuracy_all(iter, t) = mean(pred_all == true_all);
        Chance_level(iter, t) = mean(pred_chance_all == true_all);
        
        % 存储标签
        Predictions{t, iter} = pred_all;
        True_labels{t, iter} = true_all;
    end
end
end

function [Accuracy_all, Chance_level, True_labels, Predictions, SVM_models] = SVMdecoding(data0)
tic;

[numOrientations, numRepeats, numChannels, numTimePoints] = size(data0);
labels = repelem((1:numOrientations)', numRepeats);

Accuracy_all = zeros(1, numTimePoints);
Chance_level = zeros(1, numTimePoints);
True_labels = cell(1, numTimePoints);
Predictions = cell(1, numTimePoints);
SVM_models = cell(numTimePoints, 5);  % 用于存储每个时间点每折的 SVM 模型

numFolds = 5;
cv = cvpartition(labels, 'KFold', numFolds, 'Stratify', true);

for t = 1:numTimePoints  % 并行计算加速
    decodingdata = squeeze(data0(:, :, :, t));
    reshapedData = reshape(permute(decodingdata, [2, 1, 3]), [], numChannels);
    
    foldAccuracy = zeros(1, numFolds);
    foldChanceAccuracy = zeros(1, numFolds);
    YPred_all = [];
    YTrue_all = [];

    for fold = 1:numFolds
        trainIdx = training(cv, fold);
        testIdx = test(cv, fold);
        
        XTrain = reshapedData(trainIdx, :);
        YTrain = labels(trainIdx);
        XTest = reshapedData(testIdx, :);
        YTest = labels(testIdx);
        YChanceTest = YTest(randperm(length(YTest)));
        
        % 训练 SVM
        SVMModel = fitcecoc(XTrain, YTrain, 'Learners', templateSVM('KernelFunction', 'linear'), 'Coding', 'onevsall');
        
        % 保存 SVM 模型
        SVM_models{t, fold} = SVMModel;  

        % 预测
        YPred = predict(SVMModel, XTest);
        
        foldAccuracy(fold) = mean(YPred == YTest) * 100;
        foldChanceAccuracy(fold) = mean(YPred == YChanceTest) * 100;
        
        YPred_all = [YPred_all; YPred];
        YTrue_all = [YTrue_all; YTest];
    end
    
    Accuracy_all(t) = mean(foldAccuracy);
    Chance_level(t) = mean(foldChanceAccuracy);
    True_labels{t} = YTrue_all;
    Predictions{t} = YPred_all;
    disp(t);
end

% 保存模型到文件
save('SVM_models.mat', 'SVM_models');

toc;
end


