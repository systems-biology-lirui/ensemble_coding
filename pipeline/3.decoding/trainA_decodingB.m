%% --- 1. 创建示例数据 ---
% 假设我们有以下参数
[num_clusters,num_repeats_A,num_channels,num_timepoints] = size(lsqlinMGv);
num_repeats_B = size(MGv,2);


fprintf('示例数据创建完成。\n');
fprintf('  训练矩阵A维度: [%s]\n', num2str(size( lsqlinMGv)));
fprintf('  测试矩阵B维度: [%s]\n', num2str(size(MGv)));
fprintf('\n');


% --- 2. 准备标签和结果容器 ---

% --- 创建训练标签 Train_Y ---
% 这部分在循环外完成，因为它对于所有时间点都是一样的
labels_per_cluster_A = ones(num_repeats_A, 1);
Train_Y = [];
for c = 1:num_clusters
    Train_Y = [Train_Y; labels_per_cluster_A * c];
end
% 更高效的写法 (使用 repelem 或 kron)
% Train_Y = repelem((1:num_clusters)', num_repeats_A, 1);

% --- 创建测试标签 Test_Y ---
labels_per_cluster_B = ones(num_repeats_B, 1);
Test_Y = [];
for c = 1:num_clusters
    Test_Y = [Test_Y; labels_per_cluster_B * c];
end
% 更高效的写法
% Test_Y = repelem((1:num_clusters)', num_repeats_B, 1);


% --- 预分配结果容器 ---
% 创建一个向量来存储每个时间点的准确率
decoding_accuracy = zeros(1, num_timepoints);


% --- 3. 逐时间点循环解码 (Time-by-Time Decoding) ---

fprintf('开始逐时间点解码...\n');
tic; % 开始计时

% 使用 parfor 进行并行计算可以极大地加速这个过程
% 如果你有 Parallel Computing Toolbox，将 'for' 改为 'parfor'
% parfor t = 1:num_timepoints
for t = 1:num_timepoints

    % --- a. 提取并重塑当前时间点 t 的数据 ---

    % 提取训练数据
    % train_data_slice 的维度是 [cluster, repeat, channel]
    train_data_slice =  lsqlinMGv(:, :, :, t);
    % 重塑成2D矩阵: [samples, features] -> [(cluster*repeat), channel]
    Train_X = reshape(train_data_slice, [num_clusters * num_repeats_A, num_channels]);

    % 提取测试数据
    test_data_slice = MGv(:, :, :, t);
    Test_X = reshape(test_data_slice, [num_clusters * num_repeats_B, num_channels]);

    % --- b. 训练LDA分类器 ---
    % 'DiscrimType', 'linear' 指定了是LDA. 'pseudoLinear' 或 'diagLinear'
    % 在通道数多于样本数时更稳定。
    try
        lda_model = fitcdiscr(Train_X, Train_Y, 'DiscrimType', 'pseudoLinear');
    catch ME
        % 如果在某个时间点出错（例如数据有NaN或全为0），记录下来并继续
        warning('在时间点 %d 训练失败: %s', t, ME.message);
        decoding_accuracy(t) = NaN; % 标记为失败
        continue;
    end

    % --- c. 预测测试集 ---
    predicted_labels = predict(lda_model, Test_X);

    % --- d. 计算并存储准确率 ---
    accuracy = sum(predicted_labels == Test_Y) / length(Test_Y);
    decoding_accuracy(t) = accuracy;

    % (可选) 打印进度
    if mod(t, 50) == 0
        fprintf('  处理到时间点 %d / %d\n', t, num_timepoints);
    end

end

toc; % 结束计时
fprintf('解码完成！\n');


%% --- 4. 可视化结果 ---
figure;
plot(1:num_timepoints, decoding_accuracy, 'b-', 'LineWidth', 2);
hold on;
% 绘制机会水平线 (chance level)
chance_level = 1 / num_clusters;
plot([1, num_timepoints], [chance_level, chance_level], 'r--', 'LineWidth', 1.5);
hold off;

title('Time-by-Time LDA Decoding Accuracy');
xlabel('Time Point');
ylabel('Accuracy');
legend('LDA Accuracy', 'Chance Level');
ylim([0.04, 0.1]); % 准确率在0到1之间
grid on;