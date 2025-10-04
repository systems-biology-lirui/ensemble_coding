%% ---------------------------整体与个体的先后------------------------------%
% 先要说明EC与EC0信号的显著差异时间点
% 然后再说明对于朝向的解码甚至早于出现差异的时间点
clear;
clc;

EC = load('D:\\Ensembe plot\\PicData\\experiment3_EC_140trial.mat');
ECdata = EC.All_data_pre;
EC0 = load('D:\\Ensembe plot\\PicData\\experiment3_EC0_140trial.mat');
EC0data = EC0.All_data_pre;
SC = load('D:\\Ensembe plot\\PicData\\experiment3_SC_140trial.mat');
SCdata = SC.All_data_pre;
Patch = load('D:\\Ensembe plot\\PicData\\experiment3_Patch_140trial.mat');
Patchdata = Patch.All_data_pre;
clear EC SC Patch EC0

% coil SNR
coilnum = 24;
load('D:\\Ensemble coding\\data\\SNR.mat','coilSNR');
[~,coilidx] = sort(coilSNR,'descend');
coilselect = coilidx(1:coilnum);

% patch_sumdata
Patch_sumdata = cell(1,18);
for ori = 1:18
    Patch_sumdata{ori} = zeros(140,96,91);
    for location = 1:12
        Patch_sumdata{ori} = Patch_sumdata{ori}+Patchdata{location,ori};
    end
end


% 减基线
for ori = 1:18
    ECdata{ori} = ECdata{ori}-mean(ECdata{ori}(:,:,1:10),3);
    EC0data{ori} = EC0data{ori}-mean(EC0data{ori}(:,:,1:10),3);
    SCdata{ori} = SCdata{ori}-mean(SCdata{ori}(:,:,1:10),3);
    Patchdata{13,ori} = Patchdata{13,ori}-mean(Patchdata{13,ori}(:,:,1:10),3);
    Patch_sumdata{ori} = Patch_sumdata{ori}-mean(Patch_sumdata{ori}(:,:,1:10),3);
end

%% -----------------------------条件解码-----------------------------------%
% 解码EC和EC0
cond1 = [];                                                                 % zeros(2520,24,91)
cond2 = [];
for ori = 1
    cond1 = cat(1,cond1,ECdata{ori}(:,63,:));
    cond2 = cat(1,cond2,EC0data{ori}(:,63,:));
end

n_shuffles = 100; % 置换次数
cv_folds = 5;
[n_subjects, ~ ,n_timepoints] = size(cond1);

accuracy = zeros(1, n_timepoints);
shuffle_acc = zeros(n_shuffles, n_timepoints);

% 解码
for t = 1:n_timepoints
    
    X_all = [squeeze(cond1(:,:,t)); squeeze(cond2(:,:,t))];
    y_true = [ones(n_subjects,1); 2*ones(n_subjects,1)];
    
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


%% -------------------------------pattern解码-------------------------------%%
% 更详细解码请转到
%[All_data_pre,All_data,All_num_pre] = pattern_pre_analyse(All_data, Meta_data,window);
for patternclu = 1:6
    pattern_trial_num(patternclu) = size(All_data_pre{patternclu,3,1},1);
end

% 最小repeat数量
min_trialnum = min(pattern_trial_num);

coilnum = 24;
load('D:\\Ensemble coding\\data\\SNR.mat','coilSNR');
[~,coilidx] = sort(coilSNR,'descend');
coilselect = coilidx(1:coilnum);

% []
pattern_decoding_data = zeros(6,min_trialnum,coilnum,size(All_data_pre{1,9,1},3));
for patternclu = 1:6
    pattern_decoding_data(patternclu,:,:,:) = All_data_pre{patternclu,9,1}(1:min_trialnum,coilselect,:);
end
clear All_data_pre

data_reshaped = reshape(pattern_decoding_data, [], 24, 81); % 转换为 (6*209)×24×81

% 创建标签向量，每个聚类重复209次
labels = repelem(1:6, min_trialnum)';
numTimePoints = 81;

n_shuffles = 100; % 置换次数
cv_folds = 5;
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





function [acc, p] = decode_worker(X, y, cv_folds)
    X = zscore(X);
    cv = cvpartition(y, 'KFold', cv_folds);
    fold_acc = zeros(cv_folds,1);
    
    for f = 1:cv_folds
        train_idx = training(cv,f);
        test_idx = test(cv,f);
        
        model = fitcdiscr(X(train_idx,:), y(train_idx),...
            'DiscrimType', 'linear', 'Gamma', 0.01); % 正则化
        pred = predict(model, X(test_idx,:));
        fold_acc(f) = sum(pred == y(test_idx)) / length(pred);
    end
    
    acc = mean(fold_acc);
    [~, p] = ttest(fold_acc - 0.5); % 可选基础检验
end