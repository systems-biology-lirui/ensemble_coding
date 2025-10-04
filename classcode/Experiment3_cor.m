%% -------------------------------提取矩阵----------------------------------%
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

% 实际来讲，基线阶段是一个混乱的阶段，相似性本身就会很差，所以不应该从这里开始
% coil SNR
coilnum = 24;
load('D:\\Ensemble coding\\data\\SNR.mat','coilSNR');
[~,coilidx] = sort(coilSNR,'descend');
coilselect = coilidx(1:coilnum);

%% []
correlationData = zeros(90,96,100);
coilselect =[7,9,13,17,18,19,21,22,23,24,25,27,35,38,39,41,51,61,73,74,80,82,84,87,89]+1;
% input
for ori = 1:18

    correlationData(ori,:,:) = squmean(MGv(ori).Data,1);            % EC
    correlationData(ori+18,:,:) = squmean(MGnv(ori).Data,1);        % EC0
    correlationData(ori+36,:,:) = squmean(SG(ori).Data,1);         % SC
    correlationData(ori+54,:,:) = squmean(SSGnv(ori+216).Data,1);   % Patch_center
    for location = 1:12
        dd = squmean(SSGnv(ori+(location-1)*18).Data,1).*W{ori}(:,location+1);
        correlationData(ori+72,:,:) = correlationData(ori+72,:,:) + reshape(dd,[1,96,100]);         % Patch_num
    end
    correlationData(ori+72,:,:) = correlationData(ori+72,:,:)+ W{ori}(:,1)';
end
correlationData = correlationData - mean(correlationData(:,:,1:20),3);


%% repeat的normalize
% 会破坏朝向之间的差异
% for repeat = 1:90
%     data = squeeze(correlationData(repeat,:,:));
%     correlationData(repeat,:,:) = (data - min(data(:)))/(max(data(:))-min(data(:)));
% end

% 条件的norm
for condition = 1:4
    idx = ((condition-1)*18+1):condition*18;
    data = correlationData(idx,:,:);
    correlationData(idx,:,:) = (data - min(data(:)))/(max(data(:))-min(data(:)));
end

% 减基线
correlationData = correlationData - mean(correlationData(:,:,1:10),3);

% 尝试一下z-score,不行，放弃norm
% for condition = 1:5
%     idx = ((condition-1)*18+1):condition*18;
%     data = squeeze(correlationData(idx,:,:));
%     correlationData(idx,:,:) = (data-mean(data(:)))./std(data(:));
% end

% smooth(减少基线位置的相关性)
% for repeat = 1:90
%     for coil = 1:coilnum
%         correlationData(repeat,coil,:) = smooth(correlationData(repeat,coil,:));
%     end
% end

% 直接前面都为0，不行，MDS会出错
% correlationData(:,:,1:25) = 0;
%% ---------------------------相关性计算---------------------------------%
correlationData = correlationData(:,coilselect,:);
num_repeats = size(correlationData, 1);
num_coils = size(correlationData, 2);
num_time_points = size(correlationData, 3);

similarity_matrix = zeros(num_repeats, num_repeats, num_time_points);               % corr
p_value_matrix = zeros(num_repeats, num_repeats, num_time_points);                  % p_value

timeidx = 1:2:(num_time_points-1);
for t = 1:(length(timeidx)-1)
    tt = timeidx(t);
    current_time_data = squeeze(mean(correlationData(:, :, tt:tt+5),3));
        
    [correlation_matrix,p_values] = corr(current_time_data');
    
    similarity_matrix(:, :, t) = correlation_matrix;
    p_value_matrix(:, :, t) = p_values;
end

%% --------------------------timebin&跨时间------------------------------------%
% 5 to 1,time*repeat
correlationData_timebin = [];                                              % 90*18,coilnum
for timebin = 1:18
    binidx = ((timebin-1)*5+1) :timebin*5;
    correlationData_timebin = cat(1,correlationData_timebin,squeeze(mean(correlationData(:,:,binidx),3)));
end

[correlation_matrix_timebin,p_values_time_bin] = corr(correlationData_timebin');


