data.MGnv = load('D:\ensemble_coding\Project_Ensemblecoding_2024\Data\02_EpochDatabase\DG_MGnv_SSVEP_A_MUA2_Epochs_Avg.mat');
data.MGv = load('D:\ensemble_coding\Project_Ensemblecoding_2024\Data\02_EpochDatabase\DG_MGv_SSVEP_A_MUA2_Epochs_Avg.mat');
matrix.MGnv = zeros(18,6,100,121,'single');
matrix.MGv = zeros(18,6,100,121,'single');
for ori = 1:18
    for pattern = 1:6
        idx = find(data.MGnv.EpochDB.Meta.PicID == ori & data.MGnv.EpochDB.Meta.Pattern == pattern);
        matrix.MGnv(ori,pattern,:,:) = squmean(data.MGnv.EpochDB.Data(idx,:,:),1);
        idx = find(data.MGv.EpochDB.Meta.PicID == ori & data.MGv.EpochDB.Meta.Pattern == pattern);
        matrix.MGv(ori,pattern,:,:) = squmean(data.MGv.EpochDB.Data(idx,:,:),1); 
    end
end
%%
load('Yge_finalchannel.mat','sel_channel');
channels = sel_channel.QQ_old;
[min_trials, valid_counts_table] = calc_min_trials(EpochDB.Meta, {'PicID','Pattern'});
% alltrial = min_trials*6;
alltrial = 20;
data = zeros(18,alltrial,100,121,'single');
data1 = zeros(18,alltrial,100,121,'single');

for ori = 1:18
    idx = find(EpochDB.Meta.PicID==ori);
    dd = EpochDB.Data(idx([5:55,61:110,121:160]),:,:);
    data(ori,:,:,:) = trialmean(dd,20);
end
%%
options.do_permutation = false;
options.n_shuffles = 5;
options.n_repetitions = 5;
options.k_fold = 5;
options.time_smooth_win = 2;
options.mode = 'temporal';
% result_ori = Master_Decoder(data(:,:,channels,:),[],options);
result_ori1 = Master_Decoder(data(:,:,channels,:),[],options);
figure;
hold on
% plot(result_ori.acc_real_mean)
plot(result_ori1.acc_real_mean)
%%
% ----------------50hz低通滤波----------------
Fs = 500; % 采样频率 (Hz)
Fc = 50;   % 截止频率 (Hz)
Wn = Fc / (Fs/2);
N = 4; % 阶数可以根据需要调整
[b, a] = butter(N, Wn, 'low'); 

for i = 1:18
    for trial = 1:alltrial
        for channel = 1:96
            data1(i,trial,channel,:)  = filtfilt(b, a, squeeze(data(i,trial,channel,:)));
        end
    end
end
result_ori_filt50 = Master_Decoder(data1(:,:,channels,:),[],options);

% ----------------100hz低通滤波----------------
Fs = 500; % 采样频率 (Hz)
Fc = 100;   % 截止频率 (Hz)
Wn = Fc / (Fs/2);
N = 4; % 阶数可以根据需要调整
[b, a] = butter(N, Wn, 'low'); 
for i = 1:18
    for trial = 1:alltrial
        for channel = 1:96
            data1(i,trial,channel,:)  = filtfilt(b, a, squeeze(data(i,trial,channel,:)));
        end
    end
end
result_ori_filt100 = Master_Decoder(data1(:,:,channels,:),[],options);

% ----------------100hz高通滤波----------------
Fs = 500; % 采样频率 (Hz)
Fc = 100;   % 截止频率 (Hz)
Wn = Fc / (Fs/2);
N = 4; % 阶数可以根据需要调整
[b, a] = butter(N, Wn, 'high'); 

for i = 1:18
    for trial = 1:alltrial
        for channel = 1:96
            data1(i,trial,channel,:)  = filtfilt(b, a, squeeze(data(i,trial,channel,:)));
        end
    end
end
result_ori_filt100_high = Master_Decoder(data1(:,:,channels,:),[],options);

figure;hold on;

plot(result_ori.acc_real_mean)
plot(result_ori_filt50.acc_real_mean)
plot(result_ori_filt100.acc_real_mean)
plot(result_ori_filt100_high.acc_real_mean)
legend({'no filt','low50','low100','high100'})
title('DG MUA ori')
%%
[min_trials, valid_counts_table] = calc_min_trials(EpochDB.Meta, {'PicID','Pattern'});
%%
result_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Results\Figures\EVENT_decoding\';
curr_strat_name = 'Strategy1';
macaque = 'QQ_old';
fprintf('  [Step 4] 开始解码 (Train: MGnv/Fit/Res -> Test: MGv)\n');
load('Yge_finalchannel.mat','sel_channel');
channels = sel_channel.(sprintf('%s',macaque));

options.do_permutation = false;
options.n_shuffles = 5;
options.n_repetitions = 5;
options.k_fold = 5;
options.time_smooth_win = 8;
options.mode = 'cross_condition';

[n_ori, n_pat, n_trial, n_ch, n_time] = size(Fit_Mat);
[~, ~, n_trial_test, ~, ~] = size(Mat_MGv);

DecodingResults = struct();

% === Task 1: 18 Orientations ===
target_ori_18 = 1:18;
d_fit  = reshape(Fit_Mat(target_ori_18,:,:,:,:),   [18, n_pat*n_trial, n_ch, n_time]);
d_res  = reshape(Res_Mat(target_ori_18,:,:,:,:),   [18, n_pat*n_trial, n_ch, n_time]);
d_real = reshape(Mat_MGnv(target_ori_18,:,:,:,:),  [18, n_pat*n_trial, n_ch, n_time]);
d_test = reshape(Mat_MGv(target_ori_18,:,:,:,:),   [18, n_pat*n_trial_test, n_ch, n_time]);

DecodingResults.Ori18.Fit  = Master_Decoder(d_fit(:,:,channels,:),   d_test(:,:,channels,:), options);
DecodingResults.Ori18.Res  = Master_Decoder(d_res(:,:,channels,:),   d_test(:,:,channels,:), options);
DecodingResults.Ori18.Real = Master_Decoder(d_real(:,:,channels,:),  d_test(:,:,channels,:), options);

% === Task 2: [1, 9] Orientations ===
target_ori_19 = [1, 9];
d_fit  = reshape(Fit_Mat(target_ori_19,:,:,:,:),   [2, n_pat*n_trial, n_ch, n_time]);
d_res  = reshape(Res_Mat(target_ori_19,:,:,:,:),   [2, n_pat*n_trial, n_ch, n_time]);
d_real = reshape(Mat_MGnv(target_ori_19,:,:,:,:),  [2, n_pat*n_trial, n_ch, n_time]);
d_test = reshape(Mat_MGv(target_ori_19,:,:,:,:),   [2, n_pat*n_trial_test, n_ch, n_time]);

DecodingResults.Ori19.Fit  = Master_Decoder(d_fit(:,:,channels,:),   d_test(:,:,channels,:), options);
DecodingResults.Ori19.Res  = Master_Decoder(d_res(:,:,channels,:),   d_test(:,:,channels,:), options);
DecodingResults.Ori19.Real = Master_Decoder(d_real(:,:,channels,:),  d_test(:,:,channels,:), options);

% === 保存与绘图 ===
save(fullfile(result_path, sprintf('%s_Event_Decoding_Results_%s.mat', macaque, curr_strat_name)), 'DecodingResults');

figure('Name', sprintf('%s - %s', macaque, curr_strat_name), 'NumberTitle', 'off', 'Position', [100, 100, 1000, 400]);

subplot(1, 2, 1); hold on;
plot(DecodingResults.Ori18.Fit.acc_real_mean, 'r', 'LineWidth', 1.5);
plot(DecodingResults.Ori18.Res.acc_real_mean, 'b', 'LineWidth', 1.5);
plot(DecodingResults.Ori18.Real.acc_real_mean, 'k', 'LineWidth', 1.5);
title(sprintf('Task: 18 Ori (%s)', curr_strat_name));
legend('Fit','Res','Real(MGnv)'); grid on;

subplot(1, 2, 2); hold on;
plot(DecodingResults.Ori19.Fit.acc_real_mean, 'r', 'LineWidth', 1.5);
plot(DecodingResults.Ori19.Res.acc_real_mean, 'b', 'LineWidth', 1.5);
plot(DecodingResults.Ori19.Real.acc_real_mean, 'k', 'LineWidth', 1.5);
title(sprintf('Task: 1 vs 9 (%s)', curr_strat_name)); grid on;

saveas(gcf, fullfile(result_path, sprintf('%s_Event_Decoding_Plot_%s.png', macaque, curr_strat_name)));

fprintf('  [Step 4] 解码完成 (%s)\n', curr_strat_name);
%%
figure;
subplot(1,3,1)
hold on;
plot(smooth(DecodingResults.SSVEP.Ori18.Real.acc_real_mean),'Color',[0,0,0],'LineWidth',2);
plot(smooth(DecodingResults.SSVEP.Ori18.Fit.acc_real_mean),'Color',[0.7,0.5,0.5],'LineWidth',2);
plot(smooth(DecodingResults.SSVEP.Ori18.Res.acc_real_mean),'Color',[0.5,0.5,0.7],'LineWidth',2);
xticks([1:10:121])
xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160'})

subplot(1,3,2)
hold on;
plot(smooth(DecodingResults.SSVEP.Ori19.Real.acc_real_mean),'Color',[0,0,0],'LineWidth',2);
plot(smooth(DecodingResults.SSVEP.Ori19.Fit.acc_real_mean),'Color',[0.7,0.5,0.5],'LineWidth',2);
plot(smooth(DecodingResults.SSVEP.Ori19.Res.acc_real_mean),'Color',[0.5,0.5,0.7],'LineWidth',2);
xticks([1:10:121])
xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160','180','200'})

subplot(1,3,3)
hold on;
plot(smooth(DecodingResults.SSVEP.Pattern.Real_Avg),'Color',[0,0,0],'LineWidth',2);
plot(smooth(DecodingResults.SSVEP.Pattern.Fit_Avg),'Color',[0.7,0.5,0.5],'LineWidth',2);
plot(smooth(DecodingResults.SSVEP.Pattern.Res_Avg),'Color',[0.5,0.5,0.7],'LineWidth',2);
xticks([1:10:121])
xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160'})

%%
MGv_data = squmean(Mat_MGv_A_EVENT,3);
load('Yge_finalchannel.mat')
channels = sel_channel.QQ_old;
corrdata = zeros(18,6,6,121);
for ori = 1:18
    for pattern1 = 1:6
        for pattern2 = 1:6
            for t = 1:121
                corrdata(ori,pattern1,pattern2,t) = corr2(squeeze(MGv_data(ori,pattern1,channels,t)),squeeze(MGv_data(ori,pattern2,channels,t)));
            end
        end
    end
end
data_cor_mean = squmean(corrdata,[2,3]);
NeuroPlot.plot_orierp_diffcolor(data_cor_mean);

%%
MGv_data = squmean(Mat_MGv_A_SSVEP,3);
load('Yge_finalchannel.mat')
channels = sel_channel.DG;
corrdata = zeros(18,18,121);
for ori1 = 1:18
    for ori2 = 1:18
        for t = 1:121
            corrdata(ori1,ori2,t) = corr2(squmean(MGv_data(ori1,:,channels,t),2),squmean(MGv_data(ori2,:,channels,t),2));
        end
    end
end
data_cor_mean = squmean(corrdata,[1,2]);
plot(data_cor_mean)
% NeuroPlot.plot_orierp_diffcolor(data_cor_mean);
%%
clearvars -except Mat_MGv_A_SSVEP
load('Yge_finalchannel.mat')

channels = sel_channel.DG;
% channels = [74,75,43,39,88,23,19,62,22,26];
options.do_permutation = true;
options.n_shuffles = 5;
options.n_repetitions = 5;
options.k_fold = 5;
options.time_smooth_win = 8;
options.mode = 'temporal';
target_ori = 1:18;
data = reshape(Mat_MGv_A_SSVEP,[18,6*72,100,121]);
data1 = zeros(18,84,100,121);
for ori = 1:18
    idx = randperm(6*72);
    data1(ori,:,:,:) = data(ori,idx(1:84),:,:);
end
DecodingResults = Master_Decoder(data(:,:,channels,:), [], options);
% for i = 1:length(target_ori)
%     data = squeeze(Mat_MGv_A_SSVEP(target_ori(i),:,:,:,:));
%     DecodingResults = Master_Decoder(data(:,:,channels,:), [], options);
%     acc(i,:) = DecodingResults.acc_real_mean;
%     shuffle(i,:) = DecodingResults.perm_accuracies_mean;
% end
%%
figure;
for i = 1:3
    subplot(2,3,i);

    data1 = squmean(result_pattern_plot{i}.acc,2);
    NeuroPlot.plot_orierp_diffcolor(gca, data1);
    hold on
    plot(squmean(data1,1),'LineWidth',5,'Color',[0,0,0])
    xticks(1:10:121)
    xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160','180','200'})
    ylabel('ACC')
    subtitle('Pattern decoding')
    subplot(2,3,i+3);hold on
    plot(squmean(result_18ori_plot{i}.acc,2),'LineWidth',5,'Color',[0.7,0,0]);
    plot(event_acc(i,:),'LineWidth',5,'Color',[0,0,0.7])
    xlim([1,121])
    grid on
    xticks(1:10:121)
    xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160','180','200'})
    subtitle('Orientation decoding')
    if i == 1
        legend({'SSVEP MGv','EVENT MGv'})
    end
end

%%
macaques = {'DG','QQ_old','QQ_new'};
for m = 1:length(macaques)
    load(sprintf('D:/ensemble_coding/Project_Ensemblecoding_2024/Data/02_EpochDatabase/%s_MGv_EVENT_LFP_Epochs_Avg.mat',macaques{m}));
    [min_trials, valid_counts_table] = calc_min_trials(EpochDB.Meta, {'PicID','Pattern'});
    data = zeros(18,6,min_trials,100,121,'single');
    load('Yge_finalchannel.mat')
    channels = sel_channel.(macaques{m});
    options.do_permutation = false;
    options.n_shuffles = 5;
    options.n_repetitions = 5;
    options.k_fold = 5;
    options.time_smooth_win = 4;
    options.mode = 'temporal';
    target_ori = 1:18;
    for ori = 1:18
        for pattern = 1:6
            idx = find(EpochDB.Meta.PicID==ori&EpochDB.Meta.Pattern==pattern);
            data(ori,pattern,:,:,:) = EpochDB.Data(idx(1:min_trials),:,:);
        end
    end
    for ori = 1:18
        data1 = squeeze(data(ori,:,:,:,:));
        DecodingResults = Master_Decoder(data1(:,:,channels,:), [], options);
        acc{m}(ori,:) = DecodingResults.acc_real_mean;
        % shuffle(ori,:) = DecodingResults.perm_accuracies_mean;
    end
end
%%
for i = 1:3
    subplot(1,3,i);

    data1 = acc{i};
    NeuroPlot.plot_orierp_diffcolor(gca, data1);
    hold on
    plot(squmean(data1,1),'LineWidth',5,'Color',[0,0,0])
    xticks(1:10:121)
    xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160','180','200'})
    ylabel('ACC')
    subtitle('Pattern decoding')
end
%%
macaques = {'DG','QQ_old','QQ_new'};
figure;
for m = 1:length(macaques)
    load(sprintf('D:/ensemble_coding/Project_Ensemblecoding_2024/Results/Figures/EVENTMGnv2MGv/%s_Event_Decoding_Results_Strategy1.mat',macaques{m}))
    subplot(3,2,1+(m-1)*2)
    acc_fit = cat(2,DecodingResults.Ori18.Fit.detailed.real_acc_dist{:});
    acc_res = cat(2,DecodingResults.Ori18.Res.detailed.real_acc_dist{:});
    acc_real = cat(2,DecodingResults.Ori18.Real.detailed.real_acc_dist{:});
    acc = cat(3,acc_fit,acc_res,acc_real);
    NeuroPlot.plot_multicondition_decoding(gca,acc,1/18,1:20);
    xticks(1:10:121)
    xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160','180','200'})


    subplot(3,2,2+(m-1)*2)
    acc_fit = cat(2,DecodingResults.Ori19.Fit.detailed.real_acc_dist{:});
    acc_res = cat(2,DecodingResults.Ori19.Res.detailed.real_acc_dist{:});
    acc_real = cat(2,DecodingResults.Ori19.Real.detailed.real_acc_dist{:});
    acc = cat(3,acc_fit,acc_res,acc_real);
    NeuroPlot.plot_multicondition_decoding(gca,acc,1/18,1:20);
    xticks(1:10:121)
    xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160','180','200'})

    % subplot(3,3,3+(m-1)*3)
    % acc_fit = DecodingResults.EVENT.Pattern.Fit_Avg;
    % acc_res = DecodingResults.EVENT.Pattern.Res_Avg;
    % acc_real = DecodingResults.EVENT.Pattern.Real_Avg;
    % acc = cat(1,acc_fit,acc_res,acc_real);
    % NeuroPlot.plot_simple_decoding(gca,acc,1/6,1:20,1:121);
    % xticks(1:10:121)
    % xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160','180','200'})

    % subplot(3,4,4+(m-1)*4)
    % acc = squmean(result_pattern_plot{m}.acc([1,9],:,:),1);
    % NeuroPlot.plot_decoding_timecourse(gca,acc,1/18,1:20);
    % xticks(1:10:121)
    % xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160','180','200'})
end
%%
macaques = {'DG','QQ_old','QQ_new'};

options.do_permutation = false;
options.n_shuffles = 5;
options.n_repetitions = 5;
options.k_fold = 5;
options.time_smooth_win = 2;
options.mode = 'cross_condition';

[n_ori, n_pat, n_trial, n_ch, n_time] = size(Fit_Mat);
DecodingResults = struct();
result_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Results\Figures\SSVEP_B2EVENT\';
% 定义两种测试模式
test_types = {'SSVEP', 'EVENT'};
for m = 1:3
    macaque = macaques{m};
    load('Yge_finalchannel.mat','sel_channel');
    channels = sel_channel.(sprintf('%s',macaque));
    load(sprintf('D:/ensemble_coding/Project_Ensemblecoding_2024/Results/Figures/SSVEP_B2EVENT/%s_SSVEP_FitResults_Strategy1.mat',macaque))
    for t_idx = 1:length(test_types)
        curr_type = test_types{t_idx};

        % 确定测试数据 (Ground Truth)
        if strcmp(curr_type, 'SSVEP')
            Real_Test_Data = Mat_MGv_A_SSVEP;
        else
            Real_Test_Data = Mat_MGv_A_EVENT;
        end

        [~, ~, n_trial_test, ~, n_time_test] = size(Real_Test_Data);

        % % --- Task 1: 18 Orientations ---
        % target_ori_18 = [1,9];
        % d_fit  = reshape(Fit_Mat(target_ori_18,:,:,:,:),       [18, n_pat*n_trial, n_ch, n_time]);
        % d_res  = reshape(Res_Mat_SSVEP(target_ori_18,:,:,:,:), [18, n_pat*n_trial, n_ch, n_time]);
        % d_real = reshape(Mat_MGv_B(target_ori_18,:,:,:,:),     [18, n_pat*n_trial, n_ch, n_time]);
        % d_test = reshape(Real_Test_Data(target_ori_18,:,:,:,:),[18, n_pat*n_trial_test, n_ch, n_time_test]);
        %
        % DecodingResults.(curr_type).Ori18.Fit  = Master_Decoder(d_fit(:,:,channels,:),   d_test(:,:,channels,:), options);
        % DecodingResults.(curr_type).Ori18.Res  = Master_Decoder(d_res(:,:,channels,:),   d_test(:,:,channels,:), options);
        % DecodingResults.(curr_type).Ori18.Real = Master_Decoder(d_real(:,:,channels,:),  d_test(:,:,channels,:), options);
        %
        % % --- Task 2: [1, 9] Orientations ---
        % target_ori_19 = [1, 9];
        % d_fit  = reshape(Fit_Mat(target_ori_19,:,:,:,:),       [2, n_pat*n_trial, n_ch, n_time]);
        % d_res  = reshape(Res_Mat_SSVEP(target_ori_19,:,:,:,:), [2, n_pat*n_trial, n_ch, n_time]);
        % d_real = reshape(Mat_MGv_B(target_ori_19,:,:,:,:),     [2, n_pat*n_trial, n_ch, n_time]);
        % d_test = reshape(Real_Test_Data(target_ori_19,:,:,:,:),[2, n_pat*n_trial_test, n_ch, n_time_test]);
        %
        % DecodingResults.(curr_type).Ori19.Fit  = Master_Decoder(d_fit(:,:,channels,:),   d_test(:,:,channels,:), options);
        % DecodingResults.(curr_type).Ori19.Res  = Master_Decoder(d_res(:,:,channels,:),   d_test(:,:,channels,:), options);
        % DecodingResults.(curr_type).Ori19.Real = Master_Decoder(d_real(:,:,channels,:),  d_test(:,:,channels,:), options);

        % --- Task 3: Pattern Decoding ---
        acc_fit_sum = 0; acc_res_sum = 0; acc_real_sum = 0;
        for o = [1,9]
            d_fit_sl = squeeze(Fit_Mat(o, :, :, channels, :));
            d_res_sl = squeeze(Res_Mat_SSVEP(o, :, :, channels, :));
            d_real_sl = squeeze(Mat_MGv_B(o, :, :, channels, :));
            d_test_sl = squeeze(Real_Test_Data(o, :, :, channels, :));

            res_fit = Master_Decoder(d_fit_sl, d_test_sl, options);
            res_res = Master_Decoder(d_res_sl, d_test_sl, options);
            res_real = Master_Decoder(d_real_sl, d_test_sl, options);

            acc_fit_sum = acc_fit_sum + res_fit.acc_real_mean;
            acc_res_sum = acc_res_sum + res_res.acc_real_mean;
            acc_real_sum = acc_real_sum + res_real.acc_real_mean;
        end
        DecodingResults.(curr_type).Pattern.Fit_Avg  = acc_fit_sum / 2;
        DecodingResults.(curr_type).Pattern.Res_Avg  = acc_res_sum / 2;
        DecodingResults.(curr_type).Pattern.Real_Avg = acc_real_sum / 2;
    end
    % === 保存与绘图 ===
    save(fullfile(result_path, sprintf('%s_SSVEP_Decoding_Results_pattern19_%s.mat', macaque, 'Strategy1')), 'DecodingResults');
end
%%
macaques = {'DG','QQ_old','QQ_new'};
for m = 1:length(macaques)
    macaque = macaques{m};
    load(sprintf('D:/ensemble_coding/Project_Ensemblecoding_2024/Results/Figures/SSVEP_B2EVENT/%s_SSVEP_Decoding_Results_pattern19_Strategy1.mat',macaque))
    subplot(3,1,1+(m-1)*1)
    acc_fit = DecodingResults.EVENT.Pattern.Fit_Avg;
    acc_res = DecodingResults.EVENT.Pattern.Res_Avg;
    acc_real = DecodingResults.EVENT.Pattern.Real_Avg;
    acc = cat(1,acc_fit,acc_res,acc_real);
    NeuroPlot.plot_simple_decoding(gca,acc,1/6,1:20,1:121);
    xticks(1:10:121)
    xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160','180','200'})


    % subplot(3,1,2+(m-1)*1)
    % acc_fit = cat(2,DecodingResults.Ori19.Fit.detailed.real_acc_dist{:});
    % acc_res = cat(2,DecodingResults.Ori19.Res.detailed.real_acc_dist{:});
    % acc_real = cat(2,DecodingResults.Ori19.Real.detailed.real_acc_dist{:});
    % acc = cat(3,acc_fit,acc_res,acc_real);
    % NeuroPlot.plot_multicondition_decoding(gca,acc,1/18,1:20);
    % xticks(1:10:121)
    % xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160','180','200'})

    % subplot(3,3,3+(m-1)*3)
    % acc_fit = DecodingResults.EVENT.Pattern.Fit_Avg;
    % acc_res = DecodingResults.EVENT.Pattern.Res_Avg;
    % acc_real = DecodingResults.EVENT.Pattern.Real_Avg;
    % acc = cat(1,acc_fit,acc_res,acc_real);
    % NeuroPlot.plot_simple_decoding(gca,acc,1/6,1:20,1:121);
    % xticks(1:10:121)
    % xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160','180','200'})

    % subplot(3,4,4+(m-1)*4)
    % acc = squmean(result_pattern_plot{m}.acc([1,9],:,:),1);
    % NeuroPlot.plot_decoding_timecourse(gca,acc,1/18,1:20);
    % xticks(1:10:121)
    % xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160','180','200'})
end


