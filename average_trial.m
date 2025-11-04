channel1 =[74,67,68,72,45,38,40,86,7,87,58,91,92,25,94,29,64,61,56,30];
channel2 = [74,67,69,68,72,81,1,33,35,39,45,82,34,36,38,40,86,7,51,53,87,6,9,17,15,55,8,58,57,91,92,25,21,60,94,14,20,27,29,64,61,56,28,30,59];
channel3 = [58	81	9	56	40	51	39	30	1	8	72	21	87	36	68	7	61	69	35	60	33	14	53	82	57];
channels{1} =channel1;
channels{2} = channel2;
subtitles = {'channelsnum = 20','channelsnum = 45'};
figure;
for i = 2
    subplot(1,2,i)
    channel = channels{i};
    hold on;
    for meannum = [1,5,10,15,20,30,50,100]
        fprintf('channel = %d, finaltrial = %d',i,meannum);
        SSVEP_PIC_DATA1 = cell(18,6);
        for op=  1:108
            SSVEP_PIC_DATA1{op} =trialmean(SSVEP_PIC_DATA{op}(1:585,:,:),meannum);
        end
        % ------------------------------朝向解码-------------------------------%
%         data = [];
%         for ori = 1:18
%             data(ori,:,:,:) =cat(1,SSVEP_PIC_DATA1{ori,:});
%         end
% 
%         % channel2 = [];
%         [acc_real_mean, p_value, perm_accuracies_mean,detailed_results] = SVM_Decoding_LR(single(data(:,:,channel,:)), 0, 50);
%         plot(smooth(acc_real_mean),'LineWidth',2,'DisplayName',sprintf('finaltrial = %d',meannum));
        % -------------------------------pattern解码--------------------------%
        data = [];
        acc = [];
        per_acc = [];
        for ori = 1:18
            data=cat(4,SSVEP_PIC_DATA1{ori,:});
            data = permute(data,[4,1,2,3]);
            [acc_real_mean, p_value, perm_accuracies_mean,detailed_results] = SVM_Decoding_LR(single(data(:,:,channel,:)), 0, 50);
            acc(ori,:) = acc_real_mean;
        end
        plot(smooth(mean(acc,1)),'LineWidth',2,'DisplayName',sprintf('finaltrial = %d',meannum));
        % channel2 = [];
        
    end
    legend();
    xticks(0:10:100)
    yline(1/6,'--');
    xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160'})
    subtitle(subtitles{i})
end
%%
nn = cell(100,5);
for i = 1:500
    data = {};
    for x = 1:18
        for y = 1:18
            if x>y
            data{x,y}= mm{i}(x,y).Linear;
            end
        end
    end
    
    nn{i} = squmean(cat(2,data{:}),2);
end
for t = 1:100
    channel_w(:,t) = squmean(cat(2,nn{t,:}),2);
end
dd = squmean(channel_w(:,55:65),2);

%%
% --- 1. 设置参数 ---
% 假设 SSVEP_PIC_DATA 已经加载

% --- 可灵活调整的参数 ---
cluster_indices = [1, 9];    % 要比较的cluster
channel_idx = 64;            % 要分析的通道
num_repeats_total = 585;     % 使用的repeat总数

% *** 核心修改点: 定义一个cell数组来存储所有时间窗口 ***
time_windows = { ...
    36:40, ...
    61:65, ...
    1:20  ... % 在这里可以添加任意多个时间窗口
    % 示例: 1:10, ...
};

k_values = [1, 5, 10, 15, 20, 30, 50, 100, 195]; % 平均尺度

% --- 初始化 ---
num_clusters = length(cluster_indices);
num_windows = length(time_windows);
results = struct();

% --- 2. 提取并预处理所有时间窗口的特征 ---
% features: {num_clusters x num_windows cell}
features = cell(num_clusters, num_windows);

fprintf('Step 1: Extracting features for all time windows...\n');
for i = 1:num_clusters
    cluster_idx = cluster_indices(i);
    % 从大的数据矩阵中只提取一次需要的通道数据
    channel_data = squeeze(SSVEP_PIC_DATA{cluster_idx,1}(1:num_repeats_total, channel_idx, :));
    
    for j = 1:num_windows
        current_window = time_windows{j};
        % 计算每个repeat在当前时间窗口内的平均值
        features{i, j} = mean(channel_data(:, current_window), 2);
    end
end
fprintf('Feature extraction complete.\n\n');

% --- 3. 循环遍历不同的平均尺度 k ---
fprintf('Step 2: Evaluating different averaging scales (k)...\n');
for m = 1:length(k_values)
    k = k_values(m);
    fprintf('  Processing k = %d\n', k);
    
    % averaged_data: {num_clusters x num_windows cell}
    averaged_data = cell(num_clusters, num_windows);
    for i = 1:num_clusters
        for j = 1:num_windows
            averaged_data{i, j} = trial_averaging(features{i, j}, k);
        end
    end
    
    % 计算所有时间窗口的 Cohen's d
    % cohens_d_vector: (1 x num_windows)
    cohens_d_vector = zeros(1, num_windows);
    for j = 1:num_windows
        % 假设我们总是比较第一个和第二个cluster (可以根据需要修改)
        cohens_d_vector(j) = cohens_d(averaged_data{1, j}, averaged_data{2, j});
    end

    % 存储结果
    results(m).k = k;
    results(m).data = averaged_data; % 存储平均后的数据
    results(m).cohens_d = cohens_d_vector; % 存储所有窗口的d值
end
fprintf('Evaluation complete.\n\n');


% --- 4. 可视化结果 ---
fprintf('Step 3: Generating visualizations...\n');

% 4.1 可视化分布随 k 的变化
figure('Name', 'Distribution 변화 with Averaging Scale (k)', 'Position', [50, 50, 250*length(k_values), 200*num_windows]);
colors = lines(num_windows); % 使用matlab内置颜色方案，支持超过2个cluster

for m = 1:length(k_values) % 遍历k值 (列)
    k = results(m).k;
    
    for j = 1:num_windows % 遍历时间窗口 (行)
        current_data_all_clusters = results(m).data(:, j);
        current_d = results(m).cohens_d(j);
        
        subplot_idx = (j-1) * length(k_values) + m;
        subplot(num_windows, length(k_values), subplot_idx);
        hold on;
        
        for i = 1:num_clusters
            [f, xi] = ksdensity(current_data_all_clusters{i});
            if i == 1
                plot(xi, f, 'Color', colors(j,:), 'LineWidth', 2);
            else
                plot(xi, f, 'Color', [0.6,0.6,0.6], 'LineWidth', 2);
            end
        end
        hold off;
        
        % 设置标题和标签
        title(sprintf('TW %d, k=%d, d=%.2f', j, k, current_d));
        if m == 1 % 只在第一列显示y轴标签和图例
            ylabel('Density');
            if j == 1
                legend(arrayfun(@(x) sprintf('Cluster %d', x), cluster_indices, 'UniformOutput', false), 'Location', 'northeast');
            end
        end
        if j == num_windows % 只在最后一行显示x轴标签
            xlabel('Feature Value');
        end
    end
end
% 给整个图添加一个大的标题
sgtitle('Distribution Changes Across Time Windows and Averaging Scales');


% 4.2 可视化评估指标 (Cohen's d) 随 k 的变化
figure('Name', 'Effect Size (Cohen''s d) vs. Averaging Scale (k)', 'Position', [100, 100, 800, 600]);
cohens_d_matrix = vertcat(results.cohens_d); % (num_k x num_windows) 矩阵

hold on;
legend_entries = cell(1, num_windows);
for j = 1:num_windows
    plot(k_values, cohens_d_matrix(:, j), '-o', 'LineWidth', 2);
    window_str = sprintf('%d-%d', time_windows{j}(1), time_windows{j}(end));
    legend_entries{j} = ['Time Window: ' window_str];
end
hold off;

set(gca, 'XScale', 'log'); 
xlabel('Averaging Scale (k) - Log Scale');
ylabel("Cohen's d (Effect Size)");
title("Separability of Clusters vs. Averaging Scale for Different Time Windows");
legend(legend_entries, 'Location', 'best');
grid on;
fprintf('All tasks finished.\n');

% --- 辅助函数 (保持不变) ---

function final_data = trial_averaging(data, k)
    if k == 1
        final_data = data;
        return;
    end
    num_trials = length(data);
    num_new_trials = floor(num_trials / k);
    data_truncated = data(1 : num_new_trials * k);
    data_reshaped = reshape(data_truncated, [k, num_new_trials]);
    final_data = mean(data_reshaped, 1)';
end

function d = cohens_d(x1, x2)
    n1 = length(x1); n2 = length(x2);
    mean1 = mean(x1); mean2 = mean(x2);
    s1 = var(x1); s2 = var(x2);
    s_pooled = sqrt(((n1 - 1) * s1 + (n2 - 1) * s2) / (n1 + n2 - 2));
    if s_pooled == 0
        d = inf;
    else
        d = (mean1 - mean2) / s_pooled;
    end
    d = abs(d);
end
function finaldata = trialmean(data,minnum)
    [trialnum,channel,time] =  size(data);
    m = floor(trialnum/minnum);
    n = minnum*m;
    
    midata = reshape(data(1:n,:,:),[minnum,m,channel,time]);
    finaldata = squmean(midata,1);
end