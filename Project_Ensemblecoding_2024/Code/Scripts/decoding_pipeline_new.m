% step1_process_ssgv.m
clear; clc;
macaques = {'DG','QQ_new','QQ_old'};
labels = {'MGv'};
base_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\02_EpochDatabase\';
target_ori_list = 1:18;
n_ori = length(target_ori_list);
n_pat = 6;

options.do_permutation = true;
options.n_shuffles = 20;
options.n_repetitions = 20;
options.k_fold = 5;
options.time_smooth_win = 2;
options.mode = 'temporal';
load('Yge_finalchannel.mat')
% target_ori = [1:18];
for m = 1:length(macaques)

    channels = sel_channel.(macaques{m});
    for l = 1:length(labels)
        fprintf('正在加载 %s 数据...\n',labels{l});
        data = load(fullfile(base_path, sprintf('%s_%s_SSVEP_A_MUA2_Epochs_Avg.mat',macaques{m},labels{l})));
        clear data_ssgv;

        [Mat_5D, min_trials] = build_5d_matrix(data.EpochDB, n_ori, n_pat, target_ori_list);
        [nOri, nPat, nTrial, nCh, nTime] = size(Mat_5D);
        Mat_5D1 = reshape(Mat_5D,[nOri,nPat*nTrial,nCh,nTime]);
        results_ori = Master_Decoder(Mat_5D1(:,:,channels,:),[],options);
        acc = reshape(cat(2,results_ori.detailed.real_acc_dist{:}),[1,options.n_repetitions,length(results_ori.acc_real_mean)]);
        shufflechance = cat(2,results_ori.detailed.perm_acc_dist{:});
        p = results_ori.p_value;
        
        plot_decoding_timecourse(acc_matrix, chance_matrix, p_matrix, 1:121, varargin)
        
        for ori = 1:18
            Mat_5D2 = squeeze(Mat_5D(ori,:,:,:,:));
            results_pattern = Master_Decoder(Mat_5D1(:,:,channels,:),[],options);
        end
    end
end
%% SSVEP_A_decoding_MGv
clear; clc;
macaques = {'DG','QQ_new','QQ_old'};
labels = {'MGv'};
base_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\02_EpochDatabase\';
target_ori_list = 1:18;
n_ori = length(target_ori_list);
n_pat = 6;

options.do_permutation = true;
options.n_shuffles = 5;
options.n_repetitions = 5;
options.k_fold = 5;
options.time_smooth_win = 2;
options.mode = 'temporal';
load('Yge_finalchannel.mat')
% target_ori = [1:18];
result_18ori_plot = cell(length(macaques),length(labels));
result_2ori_plot = cell(length(macaques),length(labels));
result_pattern_plot = cell(length(macaques),length(labels));
for m = 1:length(macaques)

    channels = sel_channel.(macaques{m});
    for l = 1:length(labels)
        fprintf('正在加载 %s 数据...\n',labels{l});
        data = load(fullfile(base_path, sprintf('%s_%s_SSVEP_A_MUA2_Epochs_Avg.mat',macaques{m},labels{l})));
        clear data_ssgv;

        [Mat_5D, min_trials] = build_5d_matrix(data.EpochDB, n_ori, n_pat, target_ori_list);
        [nOri, nPat, nTrial, nCh, nTime] = size(Mat_5D);
        Mat_5D1 = reshape(Mat_5D,[nOri,nPat*nTrial,nCh,nTime]);
        % 18 ori
        results_ori = Master_Decoder(Mat_5D1(:,:,channels,:),[],options);
        acc = reshape(cat(2,results_ori.detailed.real_acc_dist{:}),[1,options.n_repetitions,length(results_ori.acc_real_mean)]);
        shufflechance = cat(2,results_ori.detailed.perm_acc_dist{:});
        p = results_ori.p_value;
        result_18ori_plot{m,l}.acc = acc;
        result_18ori_plot{m,l}.shufflechance = shufflechance;
        result_18ori_plot{m,l}.p = p;

        % 2ori
        results_ori = Master_Decoder(Mat_5D1(:,:,channels,:),[],options);
        acc = reshape(cat(2,results_ori.detailed.real_acc_dist{:}),[1,options.n_repetitions,length(results_ori.acc_real_mean)]);
        shufflechance = cat(2,results_ori.detailed.perm_acc_dist{:});
        p = results_ori.p_value;
        result_2ori_plot{m,l}.acc = acc;
        result_2ori_plot{m,l}.shufflechance = shufflechance;
        result_2ori_plot{m,l}.p = p;

        % pattern
        acc = [];
        shufflechance = [];
        for ori = 1:18
            Mat_5D2 = squeeze(Mat_5D(ori,:,:,:,:));
            results_pattern = Master_Decoder(Mat_5D1(:,:,channels,:),[],options);
            acc(ori,:,:) = cat(2,results_pattern.detailed.real_acc_dist{:});
            shufflechance(ori,:,:) = cat(2,results_pattern.detailed.perm_acc_dist{:});
        end
        result_pattern_plot{m,l}.acc = acc;
        result_pattern_plot{m,l}.shufflechance = shufflechance;

    end
end
save('d:/ensemble_coding/Project_Ensemblecoding_2024/Results/Figures/SSVEP_A_decoding/SSVEP_A_decoding_MGv.mat', ...
    'result_pattern_plot',"result_2ori_plot",'result_18ori_plot');

%%
