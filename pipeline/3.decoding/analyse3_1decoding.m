%% ----------------------------Decoding------------------------------------%%
% readme（用于进行解码的前期处理）


%% ---------------------Exp2（Event）的解码------------------------%%
% 可以看作6个repeat是一个session
clear;
clc;
load('D:/Ensemble coding/QQdata/tooldata/QQchannelselect.mat','selected_coil_final');

repeatmean = 1;                         % 6：也即6个进行平均
labels = {'MGv'};
ori = 1:18;
channelsall = selected_coil_final;
decoder = 'pnb';
accuracy=[];
for i = 1:length(labels)
    fprintf('start decoding %s\n',labels{i});
    fprintf('Orientation contain %s, decoder is %s \n',num2str(ori),decoder);
    data =  load(sprintf('D:/Ensemble coding/QQdata/Processed_Event/QQ_EVENT_Days2_27_MUA2_%s.mat',labels{i}));
    [n_repeats,n_channels,n_times] = size(data.(labels{i})(1).Data);
    
    % 进行合并平均（类似于session内进行平均）
    decodingdata = zeros(length(ori),n_repeats/repeatmean,length(channelsall),n_times);
    for o = 1:length(ori)
        data1 = data.(labels{i})(ori(o)).Data(:,channelsall,:);
        meaned_num = n_repeats/repeatmean;
        
        % ------------------------ 进行合并-------------------------%
            for m = 1:meaned_num
                idx = ((m-1)*repeatmean+1):(m*repeatmean);
                data2(m,:,:) = squmean(data1(idx,:,:),1);
            end
            decodingdata(o,:,:,:) = data2;
        % ---------------------- ----------------------------------------%
    end
    
    % ----------------------尝试全转换为整数值--------------------%
%     threshold = 0.5;
%     decodingdata = decodingdata >= threshold;
    % ----------------------------------------------------------------------%
    % [accuracy, ~, ~,~] = SVM_Decoding_LR(decodingdata, true, 50);
    [accuracy(i,:), peak_time_index, decoder_model] = PID_Decoding_LR(decodingdata);
end
figure;
for i = 1:length(labels)
    hold on
    plot(smooth(accuracy(i,:)));
end

%% -------------------------------EXP1 fig-------------------------------------%%
clear;
clc;
load('F:\Ensemble coding\QQdata\Processed_Event\SSVEP_PIC_DATA_1A_QQ_MUA2_SG.mat')
% selected_coil_final =  [17, 19, 21, 22, 23, 25, 27, 28, 31, 42, 45, 55, 60, 61, 62, 63, 66, 73, 74, 75, 78, 79, 80, 82, 83, 84, 87, 89, 91, 94];
selected_coil_final =  [4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 16, 17, 18, ...
    19, 20, 21, 22, 23, 24, 25, 27, 30, 31, 34, 35, 36, 38, 42, 45, 47, ...
    48, 51, 53, 54, 55, 57, 58, 59, 60, 61, 62, 63, 66, 71, 73, 74, 75, ...
    76, 77, 79, 80, 82, 83, 84, 87, 88, 89, 91, 92, 94];

channelnum = length(selected_coil_final);
repeatmean = 5;
repeatnumall = 1000;
% ----------------- 数量通道筛选-----------------------%
for i = 1:324
    a = size(SSVEP_PIC_DATA{i},1);
    num = floor(a/repeatmean)*repeatmean;
    SSVEP_PIC_DATA{i} = SSVEP_PIC_DATA{i}(1:num,selected_coil_final,:);
end

% ---------------- 合并------------------%
for ori = 1:18
    for preori = 1:18     
        newdim = size(SSVEP_PIC_DATA{ori,preori},1)/repeatmean;
        data1 =SSVEP_PIC_DATA{ori,preori};
        data2 = [];
        for m = 1:newdim
                idx = ((m-1)*repeatmean+1):(m*repeatmean);
                data2(m,:,:) = squmean(data1(idx,:,:),1);
        end
        ssvep_mean{ori,preori} = data2;
    end
end
clear SSVEP_PIC_DATA
% ----------------------加入前一个图片作为特征 -------------------------%
for ori = 1:18
    for preori = 1:18
        ssvep_mean{ori,preori}(:,channelnum+(1:18),:) = 0;
        ssvep_mean{ori,preori}(:,channelnum+preori,:) = 1;
    end
end

% -------------------重构数据 -----------------------%
for ori = 1:18
    data{ori} = cat(1,ssvep_mean{ori,:});
    data{ori} = data{ori}(1:repeatnumall,:,:);
end
decodingdata = single(zeros(18,repeatnumall,channelnum+18,100));
for ori = 1:18
    decodingdata(ori,:,:,:) = data{ori};
end
clear data ssvep_mean

% ------------------decoding-------------------%
[accuracy_over_time, ~, ~] = PID_Decoding_LR(decodingdata);
[accuracy_over_time1, peak_time_index, decoder_model] = PID_Decoding_LR(decodingdata(:,:,1:channelnum,:));
% [accuracy_over_time, p_value, perm_accuracies_mean,detailed_results] = SVM_Decoding_LR(decodingdata, true, 50);
% [accuracy_over_time1, p_value, perm_accuracies_mean1,detailed_results] = SVM_Decoding_LR(decodingdata(:,:,1:channelnum,:), true, 50);
figure;
hold on;
plot(accuracy_over_time);
plot(accuracy_over_time1);
title(sprintf('Repeatmeannum: %s  Channelnum: %s ',repeatmean,channelnum))
legend('WITH pre','NO pre');
% saveas(gcf,sprintf('Repeatmeannum_%d_Channelnum_%d.png ',repeatmean,channelnum))
