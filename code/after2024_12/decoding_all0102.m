conditions = ["Patch","Patch","Patch","Patch","Patch","Patch","Patch","Patch","Patch","Patch","Patch","Patch","Patch","EC","SC","EC0"];
for type =16
    tic;
    %% data pre
    load(sprintf('/home/dclab2/0106MUA/data%d.mat',type));
    
    window = 1:121; % 窗口范围
    num_trials = 18; % 每组的试验数
    num_repeats = 6; % 每个试验组的重复数
    minrepeat = 200; % 初始化最小重复数
    
    condition = conditions(type);
    fprintf('正在处理条件 %s，...\n', condition);

    
    if strcmp(condition, "EC")

        num = arrayfun(@(i) sum(cell2mat(all_data_new(2, (i-1)*3+1 : i*3))), 1:108);
    else
        if strcmp(condition, "Patch")
            b = (type-1)*108;
        else
            b = 0;
        end
        % 计算索引数组 idx
        idx1 = repmat(1:num_trials, num_repeats, 1)';
        idx2 = repmat(0:num_trials:num_trials * (num_repeats - 1), num_trials, 1);
        idx = reshape((idx1 + idx2)', 1, []); % 转换为行向量
        
        % 提取 `num` 数据，并重新排列顺序
        num = cellfun(@(x) x, all_data_new(2, (b+1):(b+108))); % 提取数据
        num = num(idx); % 按照索引重新排序
    end
    
    % 计算每组的重复次数，并找到最小重复数
    repeat_counts = arrayfun(@(i) sum(num((i - 1) * num_repeats + 1:i * num_repeats)), 1:num_trials);
    minrepeat = min([repeat_counts, minrepeat]); % 更新最小重复数
    
    % 初始化结果矩阵
    data = zeros(num_trials, minrepeat, 96, length(window));
    
    % 组装数据
    if strcmp(condition, "EC")
        for i = 1:num_trials
            data1 = [];
            for m = 1:18
                idx = (i-1)*18+m;
                current_data = squeeze(all_data_new{1, idx}(:, window, :)); % 提取当前片段
                
                if isempty(data1)
                    data1 = current_data; % 初始化 data1
                else
                    data1 = cat(3, data1, current_data); % 沿第 3 维拼接
                end
            end
            data1 = permute(data1,[3,1,2]);
            data(i, :, :, :) = data1(1:minrepeat, :, :);%第4维是窗口
        end
    else
        for i = 1:num_trials
            data1 = [];
            for m = 1:num_repeats
                idx = b + (m - 1) * num_trials + i; % 索引计算
                current_data = squeeze(all_data_new{1, idx}(:, window, :)); % 提取当前片段
                
                if isempty(data1)
                    data1 = current_data; % 初始化 data1
                else
                    data1 = cat(3, data1, current_data); % 沿第 3 维拼接
                end
            end
            % 选取前 minrepeat 个重复
            data1 = permute(data1,[3,1,2]);
            data(i, :, :, :) = data1(1:minrepeat, :, :);%第4维是窗口
        end
    end
    
    %% 通道筛选
    load('/home/dclab2/SNR.mat','coilSNR');
    [~,coilidx] = sort(coilSNR,'descend');
    coilselect = coilidx(1:96);
%     if strcmp(condition, "EC0")
%         coilselect = [7, 11, 14, 15, 16, 17, 19, 20, 21, 22, 23, 24,...
%             25, 26, 27, 28, 29, 30, 31, 51, 54, 53, 55, 56, 57, 58, 59,...
%             60, 61, 62, 63, 90, 92, 93, 94, 95]+1;
%     else
%          coilselect = [11, 15, 17, 19, 20, 21, 22, 23, 24, 25, ...
%              26, 27, 28, 93, 94, 95, 29, 30, 31, 51, 58, 59,...
%              60, 61, 62, 63, 92]+1;
%     end
%     coilselect = [11, 15, 17, 19, 20, 21, 22, 23, 24, 25, ...
%              26, 27, 28, 93, 94, 95, 29, 30, 31, 51, 58, 59,...
%              60, 61, 62, 63, 92]+1;
    data0 = zeros(18,140,length(coilselect),length(window));
    for coil = 1:length(coilselect)
        data0(:,:,coil,:) =data(:,:,coilselect(coil),:) ;
    end
    % 找到全局最小值和最大值
    min_val = min(data0(:));
    max_val = max(data0(:));
    
    % 执行归一化，范围缩放到 [0, 1]
    A_normalized = (data0 - min_val) / (max_val - min_val);
    data0 = A_normalized;
    %% PID
    clearvars -except data0 condition conditions type data0Copy
    fprintf('正在处理条件 %s，PID...\n', condition);

    % 参数设置
    num_orientations = 18;
    num_iterations = 50; % 交叉验证的重复次数
    k = 5; % K折交叉验证
    
    
    [~, num_trials, ~, num_time_points] = size(data0); % 数据维度
    
    % 初始化存储每次交叉验证的解码准确率
    accuracy_all = zeros(num_iterations, num_time_points);
    accuracy_chance = zeros(num_iterations, num_time_points);
    chancelevel = zeros(num_iterations, num_time_points);
    predictions = cell(num_time_points,num_iterations);
    predictions_chance = cell(num_time_points,num_iterations);
    true_labels = cell(num_time_points,num_iterations);
    
    % 100次交叉验证
    for iter = 1:num_iterations
        fprintf('正在进行第 %d 次交叉验证...\n', iter);
        
        % K折交叉验证分组
        indices = crossvalind('Kfold', num_trials, k);
        
        % 对每个时间点进行解码
        for t = 1:num_time_points
            % 记录每次交叉验证的预测和真实标签
            predictions{t,iter} = [];
            true_labels{t,iter} = [];
            
            for fold = 1:k
                % 划分训练集和测试集（取当前时间点的数据）
                train_data = data0(:, indices ~= fold, :, t);
                test_data = data0(:, indices == fold, :, t);
                
                % 计算调谐曲线
                f_theta_est = squeeze(mean(train_data, 2));
                
                f_theta_est = imgaussfilt(f_theta_est, 1);
                f_theta_est = max(f_theta_est, 1e-6); % 避免对数问题
                f_theta_est_chance = f_theta_est(randperm(size(f_theta_est,1)),:);
                % 对测试集进行解码
                for theta = 1:num_orientations
                    for trial = 1:sum(indices == fold)
                        response = squeeze(test_data(theta, trial, :))';
                        log_likelihoods = compute_log_likelihood_poisson(response, f_theta_est);
                        [~, predicted_orientation] = max(log_likelihoods);
                        predictions{t,iter} = [predictions{t,iter},predicted_orientation];
                        true_labels{t,iter} = [true_labels{t,iter},theta];
                        %chance-level
                        response_chance = squeeze(test_data(theta, trial, :))';
                        log_likelihoods_chance = compute_log_likelihood_poisson(response_chance, f_theta_est_chance);
                        [~, predicted_orientation_chance] = max(log_likelihoods_chance);
                        predictions_chance{t,iter} =  [predictions_chance{t,iter},predicted_orientation_chance];
                    end
                end
            end
            
            % 存储当前时间点的解码准确率
            accuracy_all(iter, t) = mean(predictions{t,iter} == true_labels{t,iter});
            accuracy_chance(iter, t) = mean(predictions_chance{t,iter} == true_labels{t,iter});
            %         vector = true_labels{t,iter};
            %         chancelevel(iter,t) = mean(predictions{t,iter} == vector(randperm(2520)));
        end
    end
    save(sprintf('/home/dclab2/0115MUA/%s%dPID50decoding%s.mat',condition,type,condition),'accuracy_all','predictions','true_labels','accuracy_chance')
    toc;
    %% svm
%     clearvars -except data0 condition conditions type
%     fprintf('正在处理条件 %s，SVM...\n', condition);
%     tic;
%     % 假设数据矩阵为 data0
%     [numOrientations, numRepeats, numChannels, numTimePoints] = size(data0);
%     XRepeats = 8;
%     labels = repelem((1:numOrientations)', numRepeats); % 标签
%     SVMModel = cell(numTimePoints,XRepeats);
%     accuracy = zeros(numTimePoints,XRepeats);
%     chance_level = zeros(numTimePoints,XRepeats);
%     %chanceLevelDist = zeros(1, numTimePoints); % 记录随机打乱标签的准确率分布
%     
%     % 定义用于交叉验证的参数
%     numFolds = 5; % K 折交叉验证
%     numShuffles = 100; % 随机打乱标签的次数
%     %YTrain = cell(numTimePoints,XRepeats);
%     YTest = cell(numTimePoints,XRepeats);
%     Y_chanceTest = cell(numTimePoints,XRepeats);
%     YPred = cell(numTimePoints,XRepeats);
%     % 数据准备和训练
%     for t = 1:numTimePoints
%         fprintf('时间点 %d，SVM...\n', t);
%         decodingdata = squeeze(data0(:, :, :, t)); % 提取每个时间点的数据
%         
%         % 数据重塑
%         reshapedData = reshape(permute(decodingdata, [2, 1, 3]), [], numChannels);
%         
%         % 交叉验证的初始划分
%         cv = cvpartition(labels, 'KFold', numFolds);
%         foldAccuracy = zeros(1, numFolds);
%         foldchanceAccuracy = zeros(1, numFolds);
%         for mm = 1:XRepeats % 外层重复循环
%             % 创建交叉验证划分
%             YTest{t,mm}=[];
%             Y_chanceTest{t,mm} = [];
%             YPred{t,mm}=[];
%             cv = cvpartition(labels, 'KFold', numFolds);
%             foldAccuracy = zeros(1, numFolds); % 每次重复的每折准确率
%             % 交叉验证训练和评估
%             for fold = 1:numFolds
%                 trainIdx = training(cv, fold);
%                 testIdx = test(cv, fold);
%                 
%                 XTrain = reshapedData(trainIdx, :);
%                 YTrain = labels(trainIdx);
%                 XTest = reshapedData(testIdx, :);
%                 YTest{t,mm}(fold,:) = labels(testIdx);
%                 dd = YTest{t,mm}(fold,:);
%                 Y_chanceTest{t,mm}(fold,:) = dd(randperm(length(dd)));
%                 % 训练 SVM 模型
%                 SVMModel{t, mm}{fold} = fitcecoc(XTrain, YTrain, 'Learners', templateSVM('KernelFunction', 'linear'));
%                 
%                 % 测试模型
%                 YPred{t,mm}(fold,:) = predict(SVMModel{t, mm}{fold}, XTest);
%                 foldAccuracy(fold) = sum(YPred{t,mm}(fold,:) == YTest{t,mm}(fold,:)) / length(YTest{t,mm}(fold,:)) * 100;
%                 foldchanceAccuracy(fold) = sum(YPred{t,mm}(fold,:) == Y_chanceTest{t,mm}(fold,:)) / length(Y_chanceTest{t,mm}(fold,:)) * 100;
%             end
%             % 保存交叉验证的平均准确率
%             accuracy(t,mm) = mean(foldAccuracy);
%             chance_level(t,mm) = mean(foldchanceAccuracy);
%         end
%         
%         
%         disp(mean(accuracy(t,:),2));
%         
%         % 计算随机打乱标签的 chance-level
%         
%     end
%     save(sprintf('/home/dclab2/data_1231/%sSVMdecoding%s.mat',condition,condition),'SVMModel','accuracy','chance_level','YTest','Y_chanceTest','YPred')
    clearvars -except condition conditions type
    toc;
    
end














function log_likelihoods = compute_log_likelihood_poisson(response, f_theta_est)
    % 计算对数似然值
    % response: 单次测试的神经元响应 (1 x num_neurons)
    % f_theta_est: 估计的调谐曲线 (num_orientations x num_neurons)
    
    log_f = log(f_theta_est); % 对调谐曲线取对数
    log_likelihoods = response * log_f' - sum(f_theta_est, 2)'; % 计算对数似然
end

% 数据更新逻辑的实现函数
function all_data = updateAllData(all_data, session_idxreal, orientation_data, update_mode)
    for y = 1:1405  
            % 根据更新模式选择更新方式
            if update_mode == "add"
                % 加法更新
                if isempty(all_data{session_idxreal}{1, y})
                    all_data{session_idxreal}{1, y} = orientation_data{1, y};
                else
                    all_data{session_idxreal}{1, y} = all_data{session_idxreal}{1, y} + orientation_data{1, y};
                end
            elseif update_mode == "cat"
                % 拼接更新
                if isempty(all_data{session_idxreal}{1, y})
                    all_data{session_idxreal}{1, y} = orientation_data{1, y};
                else
                    all_data{session_idxreal}{1, y} = cat(3, all_data{session_idxreal}{1, y}, orientation_data{1, y});
                end
            end
            % 更新计数
            all_data{session_idxreal}{2, y} = all_data{session_idxreal}{2, y} + orientation_data{2, y};
    end
end
% 处理
function ori = processStimID(StimID, session_idx)
    ori = [];
    if session_idx < 14
        % 处理 EC 类型
        for x = 1:52
            for y = 1:133
                if StimID(x, y) ~= 1405
                    ori(x, y) = mod(StimID(x, y) - (session_idx - 1) * 108, 18);
                    if ori(x, y) == 0
                        ori(x, y) = 18;
                    end
                else
                    ori(x, y) = 19;
                end
            end
        end
    elseif session_idx == 14
        % 处理 EC 类型
        for x = 1:52
            for y = 1:133
                if StimID(x, y) ~= 325
                    ori(x, y) = floor((StimID(x, y) - 1) / 18 + 1);
                else
                    ori(x, y) = 19;
                end
            end
        end
    else
        % 处理 SC 类型
        for x = 1:52
            for y = 1:133
                if StimID(x, y) ~= 109
                    ori(x, y) = mod(StimID(x, y), 18);
                    if ori(x, y) == 0
                        ori(x, y) = 18;
                    end
                else
                    ori(x, y) = 19;
                end
            end
        end
    end
end
