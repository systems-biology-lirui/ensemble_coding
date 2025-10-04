%% --------------------- Orientation decoding------------------------------%
% 在这一步里面先后对EC，EC0，SC做出解码，并保存下model，用于后面的法向量分析

% clear;

% coil选择
coilnum = 24;
load('D:\\Ensemble coding\\data\\SNR.mat','coilSNR');
[~,coilidx] = sort(coilSNR,'descend');
coilselect = coilidx(1:coilnum);

% 分类数量
clusternum = 18;

% decoding，每个pre下进行一次
for pre = 1
    accuracymodel = struct();
    shufflemodel = struct();
    % if ori ==1
    %     preidx = 14:18;
    % else
    %     preidx = 1:18;
    % end
    tic;
    data = cell(1,clusternum);
    minnum = 200;
    % EC0
    % load('D:\\Ensembe plot\\Decoding\\SCall_data_pre3_15.mat','All_data_pre');
    for ori = 1:clusternum
        
        % EC
        % load(sprintf('D:\\Ensembe plot\\Decoding\\pattern_SVMdata\\samepre\\ori%d_preori%d.mat',ori,pre),'All_data_pre');
        % for pattern = 1:6
        %     data{ori} = cat(1,data{ori},All_data_pre{pattern,1,1});
        % end
        
        data{ori} = All_data_pre{ori,pre};
        
        % 最小的trial数量
        trialnum =size(data{ori},1);
        if trialnum <minnum
            minnum = trialnum;
        end
        
    end
    clear All_data_pre
    % 数据重组
    data_reshaped = [];
    for ori = 1:clusternum
        data_reshaped = cat(1,data_reshaped,data{ori}(1:minnum,coilselect,:));
    end

    % 创建标签向量，每个聚类重复209次
    labels = repelem(1:clusternum, minnum)';
    numTimePoints = 81;

    n_shuffles = 50; % 置换次数
    cv_folds = 3;
    [~, ~ ,n_timepoints] = size(data_reshaped);

    accuracy = zeros(1, n_timepoints);
    shuffle_acc = zeros(n_shuffles, n_timepoints);

    for t = 1:n_timepoints
        X_all = squeeze(data_reshaped(:,:,t));
        y_true = labels;
        [model, true_acc, ~] = decode_worker(X_all, y_true, cv_folds);
        accuracy(t) = true_acc;
        accuracymodel.(sprintf('time%d',t)) = model;

        % 置换检验
        temp_shuffle = zeros(n_shuffles,1);
        for s = 1:n_shuffles
            y_shuffle = y_true(randperm(length(y_true))); % 打乱标签
            [model, shuffle_acc(s,t), ~] = decode_worker(X_all, y_shuffle, cv_folds);
            shufflemodel.(sprintf('time%d',t)).(sprintf('shuffle%d',s)) = model;
        end
        disp(t);
    end
    % save(sprintf('D:\\Ensembe plot\\Decoding\\pattern_SVMdata\\patternSVM3_7day_ori%d_repeat%d.mat',ori,minnum),'shuffle_acc','accuracy');
    save(sprintf('D:\\Ensembe plot\\Decoding\\orientation_SVMdata\\samepre\\SC\\orientationSVM3_7day_preori%d.mat',pre),'shuffle_acc','accuracy');
    save(sprintf('D:\\Ensembe plot\\Decoding\\orientation_SVMdata\\samepre\\SC\\orientationSVM3_7day_preori%d_model.mat',pre),'accuracymodel','shufflemodel','-v7.3');
    clear shuffle_acc accuracy data_reshaped pattern_decoding_data
    fprintf(sprintf('complete_pre%d',pre));
    toc;

end

function [model, acc, p] = decode_worker(X, y, cv_folds)
X = zscore(X);
cv = cvpartition(y, 'KFold', cv_folds);
fold_acc = zeros(cv_folds,1);


for f = 1:cv_folds
    train_idx = training(cv,f);
    test_idx = test(cv,f);

    canUseLinear = true;
    X_train = X(train_idx, :);
    y_train = y(train_idx);

    % 检测类内方差是否为零
    for c = 1:max(y_train)
        class_data = X_train(y_train == c, :); % 获取当前类的数据
        if any(var(class_data) < 1e-10) % 检查类内方差是否接近零
            canUseLinear = false;
            break;
        end
    end

    % 检测协方差矩阵是否奇异
    if canUseLinear
        cov_matrix = cov(X_train);
        if cond(cov_matrix) > 1e15 % 条件数过大，协方差矩阵可能奇异
            canUseLinear = false;
        end
    end
    if canUseLinear
        model = fitcdiscr(X(train_idx,:), y(train_idx),...
            'DiscrimType', 'linear', 'Gamma', 0.01); % 正则化
    else
        model = fitcdiscr(X(train_idx,:), y(train_idx),...
            'DiscrimType', 'diaglinear', 'Gamma', 0.01);
    end
    pred = predict(model, X(test_idx,:));
    fold_acc(f) = sum(pred == y(test_idx)) / length(pred);
    
end

acc = mean(fold_acc);
[~, p] = ttest(fold_acc - 0.5); % 可选基础检验
end


