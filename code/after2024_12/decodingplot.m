function h = decodingplot(Accuracy_all, Chance_level)
color1 = [130,176,210;255,190,122;250,127,111;142,207,201];
h=figure;
   i=1; 
chancelevel =Chance_level;
% 参数设置
num_iterations = size(Accuracy_all, 1); % 迭代次数
num_time_points = size(Accuracy_all, 2); % 时间点数量
alpha = 0.05; % 显著性水平


% 计算 Accuracy_all 的均值和 95% 置信区间
mean_accuracy = mean(Accuracy_all, 1); % 每个时间点的平均解码准确率
std_accuracy = std(Accuracy_all, 0, 1); % 每个时间点的标准差
ci_upper_accuracy = mean_accuracy + 1.96 * (std_accuracy / sqrt(num_iterations)); % 95%置信区间上界
ci_lower_accuracy = mean_accuracy - 1.96 * (std_accuracy / sqrt(num_iterations)); % 95%置信区间下界

% 计算 chancelevel 的均值和 95% 置信区间
mean_chance = mean(chancelevel, 1); % 每个时间点的平均 chancelevel
std_chance = std(chancelevel, 0, 1); % 每个时间点的标准差
ci_upper_chance = mean_chance + 1.96 * (std_chance / sqrt(num_iterations)); % 95%置信区间上界
ci_lower_chance = mean_chance - 1.96 * (std_chance / sqrt(num_iterations)); % 95%置信区间下界

% 显著性测试（accuracy 是否显著大于 chancelevel）
p_values = zeros(1, num_time_points);
significant_time_points = false(1, num_time_points);

for t = 1:num_time_points
    [~, p_values(t)] = ttest(Accuracy_all(:, t), chancelevel(:, t), 'Alpha', alpha, 'Tail', 'right');
    if p_values(t) < alpha
        significant_time_points(t) = true; % 标记显著的时间点
    end
end

for t = 1:num_time_points-3
    if significant_time_points(t:t+3) == 1
        significant_time_points(t) = 1;
    else
        significant_time_points(t) = 0;
    end
end

subplot(1,2,1);
% 绘制 accuracy 的平均值折线和置信区间
plot(1:num_time_points, mean_accuracy, 'LineWidth', 1.5,'DisplayName','EC'); hold on;
fill([1:num_time_points, fliplr(1:num_time_points)], ...
     [ci_upper_accuracy, fliplr(ci_lower_accuracy)], ...
     color1(i,:)/256, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

% 绘制 chancelevel 的平均值折线和置信区间
plot(1:num_time_points, mean_chance, 'Color',[0.5,0.5,0.5], 'LineWidth', 1.5); % chancelevel 平均值折线
fill([1:num_time_points, fliplr(1:num_time_points)], ...
     [ci_upper_chance, fliplr(ci_lower_chance)], ...
     [0.5,0.5,0.5], 'FaceAlpha', 0.2, 'EdgeColor', 'none');

% 显著时间点可视化（accuracy 大于 chancelevel 的时间点）
y_min = 0; % 图表下界
y_max = 0.2; % 图表上界
for t = 1:num_time_points
    if significant_time_points(t)
        fill([t-0.5, t+0.5, t+0.5, t-0.5], [y_min+(i-1)*0.01, y_min+(i-1)*0.01, y_min+i*0.01, y_min+i*0.01], ...
             color1(i,:)/256, 'FaceAlpha', 0.5, 'EdgeColor', 'none'); % 用红色区块标记显著时间点
    end
end

% 图表设置
xlabel('时间点');
ylabel('解码准确率');
title('解码准确率、基线水平及显著性分析');
ylim([y_min, y_max]);
%g
clearvars -except i conditions

% subplot(1,2,2);
% 
% for t = 1:num_time_points
%     % 数据定义
% x0 = Accuracy_all(1,t); % 单个值
% x1 = Chance_level(:,t)'; % 一组值
% 
% % 合并数据
% data = [x0, x1]; % 将 x0 和 x1 放在一起
% n_permutations = 100; % 设置置换次数
% 
% % 计算观察统计量（例如均值差）
% observed_stat = x0 - mean(x1);
% 
% % 初始化置换统计量存储
% perm_stats = zeros(n_permutations, 1);
% 
% % 置换检验
% for i = 1:n_permutations
%     permuted_data = data(randperm(length(data))); % 随机置换数据
%     perm_x0 = permuted_data(1); % 获取置换后的 x0
%     perm_x1 = permuted_data(2:end); % 获取置换后的 x1
%     perm_stats(i) = perm_x0 - mean(perm_x1); % 计算置换统计量
% end
% 
% % 计算 p 值（双侧检验）
% p_value1(t) = mean(abs(perm_stats) >= abs(observed_stat)); % p 值（双侧）
% 
% % % 输出结果
% % disp(['观察统计量：', num2str(observed_stat)]);
% % disp(['p 值：', num2str(p_value)]);

end
