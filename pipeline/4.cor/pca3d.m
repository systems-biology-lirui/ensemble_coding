%%
clearvars -except correlationData
% QQ old
% coilselect=[7,9,13,17,18,19,21,22,23,24,25,27,35,38,39,41,51,61,73,74,80,82,84,87,89]+1;
% DG
coilselect = [63,18,31,26,21,32,20,28,60,94,59,29,52,96,22,64,61,95,24,30,62,16,25,27,93,23,12,91,57,58];
% QQ_new
% coilselect= [79,43,78,81,47,49,85,42,46,89,58,91,92,25,21,62,60,20,27,22,24,26];

% 这里做了朝向的平均
neural_data = squmean(reshape(correlationData(:,:,1:100),[18,6,96,100]),1);
neural_data = neural_data(:,coilselect,1:100);
neural_data = cat(1,neural_data,neural_data(2,:,:)-neural_data(5,:,:));
% for t = 1:50
%     idx = ((t-1)*2+1):t*2;
%     neural_data(:,:,t) =squmean(neural_data(:,:,idx),3);
% end
% 
% neural_data = neural_data(:,:,1:50);
%%
[~,num_channels,num_timepoints] = size(neural_data);
% labelall = {'MGv','MGnv','SG','centerSSGnv','fitMGnv','sumMGnv','resMGnv'};
labelall = {'MGvday1','MGvday2','MGvday3','MGvday4','MGnvday1','MGnvday2','MGnvday3','MGnvday4','MGnvday5'};
conditionselect = 1:8;
X_combined = zeros(num_timepoints*length(conditionselect),num_channels);
for c = 1:length(conditionselect)
    % 提取条件1和条件2的数据
    idx = (num_timepoints*(c-1)+1):num_timepoints*c;
    X_combined(idx,:) = squeeze(neural_data(conditionselect(c), :, :))';
end
num_dims_to_keep = 3;

% 执行PCA
% coeff: 主成分系数（PC vectors or loadings），每一列是一个PC
% score: 数据在PC空间中的得分（即投影后的数据）
% latent: 每个主成分的方差（eigenvalues）
% explained: 每个主成分解释的方差百分比
[coeff, score, latent, ~, explained] = pca(X_combined);

% 查看解释的方差来决定保留多少维度
fprintf('前3个主成分解释的总方差: %.2f%%\n', sum(explained(1:3)));

% 可选：绘制解释方差的碎石图 (Scree Plot)
figure;
plot(1:length(explained), cumsum(explained), 'o-');
xlabel('主成分数量');
ylabel('累计解释方差 (%)');
title('Scree Plot');

% 将条件A和B的数据投影到前3个PC上
for c = 1:length(conditionselect)
    idx = (num_timepoints*(c-1)+1):num_timepoints*c;
    X_A = X_combined(idx,:);
    trajectory_A (:,:,c)= X_A * coeff(:, 1:num_dims_to_keep); % 100x30 * 30x3 -> 100x3
end
figure;
hold on; % 允许在同一张图上绘制多条线
window_size = 3;
time_win = 21:80;
for c = 1:length(conditionselect)
    trajectory_A(:,1,c) = movmean(squeeze(trajectory_A(:,1,c)), window_size);
    trajectory_A(:,2,c) = movmean(squeeze(trajectory_A(:,2,c)), window_size);
    trajectory_A(:,3,c) = movmean(squeeze(trajectory_A(:,3,c)), window_size);
    currentlabel = labelall{conditionselect(c)};
    plot3(trajectory_A(time_win,1,c), trajectory_A(time_win,2,c), trajectory_A(time_win,3,c), ...
          'LineWidth', 2, 'DisplayName', currentlabel);

    scatter3(trajectory_A(time_win(1),1,c), trajectory_A(time_win(1),2,c), trajectory_A(time_win(1),3,c), ...
             100, 'b', 'o', 'filled', 'HandleVisibility', 'off');

    scatter3(trajectory_A(time_win(end),1,c), trajectory_A(time_win(end),2,c), trajectory_A(time_win(end),3,c), ...
             100, 'b', 's', 'filled', 'HandleVisibility', 'off');
end

% 美化图像
xlabel('PC 1');
ylabel('PC 2');
zlabel('PC 3');
title('低维空间中的神经轨迹');
legend('show');

axis equal; % 使坐标轴比例相同，更真实地反映距离
view(125,25); % 设置为三维视角
hold off;
% 计算每个时间点的欧氏距离
distance_over_time = sqrt(sum((trajectory_A(:,:,2) - trajectory_A(:,:,1)).^2, 2));
% distance_over_time = normalize(distance_over_time,'range');
% 绘制距离随时间变化的曲线
figure;
time_axis = 1:num_timepoints;
plot(time_axis, distance_over_time, 'k-', 'LineWidth', 2);
hold on
distance_over_time = sqrt(sum((trajectory_A(:,:,2) - trajectory_A(:,:,3)).^2, 2));
% distance_over_time = normalize(distance_over_time,'range');
plot(time_axis, distance_over_time, 'r-', 'LineWidth', 2);
grid off
distance_over_time = sqrt(sum((trajectory_A(:,:,2) - trajectory_A(:,:,4)).^2, 2));
% distance_over_time = normalize(distance_over_time,'range');
plot(time_axis, distance_over_time, 'b-', 'LineWidth', 2);
xlabel('时间点');
ylabel('轨迹间的欧氏距离');
title('两个条件神经表征的差异随时间的变化');
 legend({'MGnv-MGv','MGnv-fitMGnv','MGnv-resMGnv'});
box off;
xticks(0:10:100)
xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160'})