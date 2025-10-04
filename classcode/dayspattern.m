clear;
session_idx_path = 'D:\\Ensemble coding\\data\\SessionIdx.mat';
load(session_idx_path);

Days = 3:9;                % day
Conditions = 3;          % condition(1-dataidx; 2-date; 3-EC;
% 4-EC0; 5-SC; 6-Patch; 7-变化；8-ECPatch)
Type = 'trial_MUA';                % trial_LFP/trial_MUA

pattern = 1;                    % 是否需要pattern的计算


for dd = Days

    [stimID_data, Meta_data,All_data] ...
        = load_data(dd,Conditions,Type,sessionIdx,pattern);


    factor1 = 1;             % 1-pic;2-trail
    window = -10:70;

    if pattern ~= 1
        [All_data_pre,All_num,All_data] ...
            = pre_analyse(All_data, Meta_data,dd,Conditions,factor1,window);
    else
        [All_data_pre,All_data,All_num_pre] = pattern_pre_analyse(All_data, Meta_data,window);
    end
  
    save(sprintf('D:\\Ensembe plot\\Decoding\\pattern_SVMdata\\all_data_pre%d.mat',dd),'All_data_pre');
    clear All_data_pre All_data
end
    %%
    clear;
    for ori = 1:18
        if ori ==1
            preidx = 14:18;
        else
            preidx = 1:18;
        end
        for pre = preidx
            tic;
            data = cell(1,6);
            load(sprintf('D:\\Ensembe plot\\Decoding\\pattern_SVMdata\\samepre\\ori%d_preori%d.mat',ori,pre),'All_data_pre');
            minnum = 10000;
            for pattern = 1:6
                for preori = 1
                    data{pattern} = cat(1,data{pattern},All_data_pre{pattern,1,1});
                end
                trialnum =size(data{pattern},1);
                if trialnum <minnum
                    minnum = trialnum;
                end
            end
            clear All_data_pre
            coilnum = 24;
            load('D:\\Ensemble coding\\data\\SNR.mat','coilSNR');
            [~,coilidx] = sort(coilSNR,'descend');
            coilselect = coilidx(1:coilnum);

          
            for pattern = 1:6
                pattern_decoding_data(pattern,:,:,:) = data{pattern}(1:minnum,coilselect,:);
            end

            clear data
            data_reshaped = [];
            for pattern = 1:6
                data_reshaped = cat(1,data_reshaped,squeeze(pattern_decoding_data(pattern,:,:,:)));
            end


            % 创建标签向量，每个聚类重复209次
            labels = repelem(1:6, minnum)';
            numTimePoints = 81;

            n_shuffles = 50; % 置换次数
            cv_folds = 3;
            [~, ~ ,n_timepoints] = size(data_reshaped);

            accuracy = zeros(1, n_timepoints);
            shuffle_acc = zeros(n_shuffles, n_timepoints);

            for t = 1:n_timepoints
                X_all = squeeze(data_reshaped(:,:,t));
                y_true = labels;
                [true_acc, ~] = decode_worker(X_all, y_true, cv_folds);
                accuracy(t) = true_acc;

                % 置换检验
                temp_shuffle = zeros(n_shuffles,1);
                for s = 1:n_shuffles
                    y_shuffle = y_true(randperm(length(y_true))); % 打乱标签
                    [shuffle_acc(s,t), ~] = decode_worker(X_all, y_shuffle, cv_folds);
                end
                disp(t);
            end
            % save(sprintf('D:\\Ensembe plot\\Decoding\\pattern_SVMdata\\patternSVM3_7day_ori%d_repeat%d.mat',ori,minnum),'shuffle_acc','accuracy');
            save(sprintf('D:\\Ensembe plot\\Decoding\\pattern_SVMdata\\samepre\\patternSVM3_7day_ori%d_preori%d_repeat%d.mat',ori,pre,minnum),'shuffle_acc','accuracy');
            clear shuffle_acc accuracy data_reshaped pattern_decoding_data
            fprintf(sprintf('completeori%d_pre%d',ori,pre));
            toc;
        end
    end
%% 用于多天的合并
All_data_pre = cell(6,18,18);
for d = 3:7
    a = load(sprintf('D:\\Ensembe plot\\Decoding\\pattern_SVMdata\\all_data_pre%d.mat',d));
    for x = 1:6
        for y = 1:18
            for z = 1:18
                All_data_pre{x,y,z} = cat(1,All_data_pre{x,y,z},a.All_data_pre{x,y,z});
            end
        end
    end
    clear a;
end
%% 用于固定前一张图片的合并
a = load('D:\\Ensembe plot\\Decoding\\pattern_SVMdata\\all_data_pre3_7.mat');
for y = 1:18
    for z = 1:18
        All_data_pre = cell(6,1,1);
        for x= 1:6
            All_data_pre{x,1,1} = a.All_data_pre{x,y,z};
        end
        save(sprintf('D:\\Ensembe plot\\Decoding\\pattern_SVMdata\\samepre\\ori%d_preori%d.mat',y,z),'All_data_pre');
        fprintf(sprintf('pre%d',z));
    end

    fprintf(sprintf('ori%d',y));
end





function [acc, p] = decode_worker(X, y, cv_folds)
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

