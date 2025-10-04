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
[~, p] = ttest(fold_acc - 0.05); % 可选基础检验
end