function filtered_data = bandstop_50hz_100hz(trial_data)

    % bandstop_50hz_100hz 对多维数据应用陷波滤波器
    %
    % 输入参数:
    %   trial_data - 三维数组，维度为 (trials, channels, time)
    %   fs - 采样频率 (Hz)
    %   notch_freqs - 陷波频率的向量 (Hz)
    %   bw - 带宽 (Hz)
    %
    % 输出:
    %   filtered_data - 经过陷波处理的三维数组
    
    fs = 500;
    notch_freqs = [50,100];
    bw = 5;
    
    [n_trial,n_channel,n_time] = size(trial_data);
    filtered_data = single(zeros(n_trial,n_channel,n_time));
    for trial = 1:n_trial
        for channel = 1:n_channel
            for freq = notch_freqs
                % 设计陷波滤波器
                d = designfilt('bandstopiir', ...
                               'FilterOrder', 2, ...
                               'HalfPowerFrequency1', freq - bw/2, ...
                               'HalfPowerFrequency2', freq + bw/2, ...
                               'DesignMethod', 'butter', ...
                               'SampleRate', fs);
                
                % 对数据进行陷波滤波
                % 使用 filtfilt 进行无相位延迟滤波
                data_trial_channel = squeeze(trial_data(trial, channel, :)); 
                filtered_data(trial, channel, :) = filtfilt(d, data_trial_channel);
            end
        end
        fprintf('complete trial%s\n',trial);
    end