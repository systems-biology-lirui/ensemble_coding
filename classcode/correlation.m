%% -----------------------条件之间的相似性表征---------------------------%%
% 这里主要先放EC和EC0
% 需要用pic做提取了

for ori = 1:18
    target_size = 50;
    data = EC{ori};
    % 计算每个分块的大小
    chunk_size = size(data, 1) / target_size;

    % 使用 reshape 和 mean 进行平均
    data_avg = mean(reshape(data, [chunk_size, target_size, size(data, 2), size(data, 3)]), 1);

    % 去除多余的维度
    EC{ori} = squeeze(data_avg);
end  
%%
EC_combined = cat(1, EC{:}); 
EC0_combined = cat(1, EC0{:}); 
for trial = 1:900
    for coil = 1:96
        EC_combined(trial,coil,:) = normalize(squeeze(EC_combined(trial,coil,:)));
        EC0_combined(trial,coil,:) = normalize(squeeze(EC0_combined(trial,coil,:)));
    end
end

%%
for trial = 1:900
    for coil = 1:96
        EC_combined(trial,coil,:) = normalize(squeeze(EC_combined(trial,coil,:)),'range');
        EC0_combined(trial,coil,:) = normalize(squeeze(EC0_combined(trial,coil,:)),'range');
    end
end
load('/home/dclab2/Ensemble coding/data/SNR.mat','coilSNR');
[~,coilidx] = sort(coilSNR,'descend');
coilselect = coilidx(1:24);
all_cordata = cat(1,EC_combined,EC0_combined);
for time = 1:81
    corrtime = corr(squeeze(all_cordata(:,:,time))',squeeze(all_cordata(:,:,time))');
    EC_EC0cor(:,:,time) = corrtime;
end
%%

% group1: 900×96 矩阵
% group2: 900×96 矩阵


% 定义函数：将 trials 按行计算相关性矩阵
calc_corr_matrix = @(data) corr(data');  % 输入为 trials×coils，输出为 trials×trials

corr_matrix_group1 = calc_corr_matrix(squeeze(EC_combined(:,:,41)));
corr_matrix_group2 = calc_corr_matrix(squeeze(EC0_combined(:,:,41)));


%% 1. 数据准备与标准化
% 假设两组数据已加载为 group1 和 group2 (均为900×96)


% 合并两组数据（合并后1800×96）
combined_data = [squeeze(EC_combined(:,:,45)); squeeze(EC0_combined(:,:,45))]; 

% 计算完整的相关性矩阵（1800×1800）
full_corr = corr(combined_data'); 

% 提取子矩阵：
% - group1内部相关性（1:900,1:900）
% - group2内部相关性（901:1800,901:1800）
% - 跨组相关性（1:900,901:1800）
corr_within_group1 = full_corr(1:900, 1:900);
corr_within_group2 = full_corr(901:1800, 901:1800);
corr_between_groups = full_corr(1:900, 901:1800);

% 组内距离矩阵
distance_within_group1 = 1 - corr_within_group1;
distance_within_group2 = 1 - corr_within_group2;

% 跨组距离矩阵
distance_between_groups = 1 - corr_between_groups;

% 合并为全局距离矩阵
global_distance = [distance_within_group1, distance_between_groups; 
                   distance_between_groups', distance_within_group2];

% 确保对称性
global_distance = max(global_distance, global_distance');


Y = mdscale(global_distance, 2); % 降维到2维
%%
figure;
hold on;

% 绘制所有trial的分布
scatter(Y(1:50,1), Y(1:50,2), 30, 'r', 'filled', 'MarkerEdgeAlpha',0.5, 'MarkerFaceAlpha',0.5);
scatter(Y(901:950,1), Y(901:950,2), 30, 'b', 'filled', 'MarkerEdgeAlpha',0.5, 'MarkerFaceAlpha',0.5);

% 标注跨组最近邻连线（示例：随机选5对）

% 图形标注
title('MDS 2D Visualization with Cross-Condition Links');
xlabel('Dimension 1');
ylabel('Dimension 2');
legend('Group 1', 'Group 2', 'Cross-Condition Links');
grid on;
hold off;


% 计算质心距离
centroid_group1 = mean(Y(1:900, :));
centroid_group2 = mean(Y(901:1800, :));
distance_between_centroids = norm(centroid_group1 - centroid_group2);
fprintf('质心距离: %.4f\n', distance_between_centroids);

% Procrustes分析（形状对齐差异）
[~, Z] = procrustes(Y(1:900, :), Y(901:1800, :));
disp('Procrustes统计量（组间形状差异）:');
disp(Z);