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
alltrial = min_trials*6;
data = zeros(18,alltrial,100,121,'single');
data1 = zeros(18,alltrial,100,121,'single');

for ori = 1:18
    idx = find(EpochDB.Meta.PicID==ori);
    data(ori,:,:,:) = EpochDB.Data(idx(1:alltrial),:,:);
end
%%
options.do_permutation = false;
options.n_shuffles = 5;
options.n_repetitions = 5;
options.k_fold = 5;
options.time_smooth_win = 2;
options.mode = 'temporal';
result_ori = Master_Decoder(data(:,:,channels,:),[],options);

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
