function [accuracy_over_time, peak_time_index, decoder_model] = PID_Decoding_LR(data, varargin)
%perform_PID_decoding 对4D神经数据执行泊松独立解码器(PID)分析
%
%   此函数根据论文 "Decoding the activity of neuronal populations in 
%   macaque primary visual cortex" (Graf et al., 2011) 中描述的PID模型，
%   在每个时间点上对神经响应数据进行多分类解码。
%
%   用法:
%       [accuracy, cm, peak_t, model] = perform_PID_decoding(data)
%       [accuracy, cm, peak_t, model] = perform_PID_decoding(data, 'train_ratio', 0.75, 'show_plots', false)
%
%   输入:
%       data - 4D矩阵 (n_stimuli x n_trials x n_neurons x n_timepoints)
%              这是主要的神经数据输入。
%
%       varargin - 可选的键值对参数:
%           'train_ratio' - 用于训练的数据比例 (0到1之间)。
%                           (默认值: 0.8)
%           'show_plots'  - 是否显示结果图表 (accuracy vs. time, confusion matrix)。
%                           (默认值: true)
%           'shuffle'     - 是否在分割数据前随机打乱试验顺序。
%                           (默认值: true)
%
%   输出:
%       accuracy_over_time   - 向量 (1 x n_timepoints)，包含每个时间点的解码准确率。
%       peak_confusion_chart - 在解码准确率最高的时间点生成的混淆矩阵图表对象。
%       peak_time_index      - 解码准确率最高的时间点的索引。
%       decoder_model        - 包含训练好的解码器参数的结构体，
%                              包括 .weights_W 和 .offsets_B。
%
%   示例:
%       % 1. 创建模拟数据
%       sim_data = randi([0 5], 10, 100, 20, 50); % 10类, 100次试验, 20神经元, 50时间点
%       % 2. 运行解码器
%       [accuracy, cm, peak_t] = perform_PID_decoding(sim_data);
%       % 3. 查看峰值准确率
%       fprintf('峰值准确率在时间点 T=%d 达到 %.2f%%\n', peak_t, max(accuracy)*100);

% =========================================================================
% 1. 解析输入参数
% =========================================================================
p = inputParser;
addRequired(p, 'data', @(x) isnumeric(x) && ndims(x) == 4);
addParameter(p, 'train_ratio', 0.8, @(x) isscalar(x) && x > 0 && x < 1);
addParameter(p, 'show_plots', true, @islogical);
addParameter(p, 'shuffle', true, @islogical);
parse(p, data, varargin{:});

% 将解析后的参数赋值给变量
train_ratio = p.Results.train_ratio;
show_plots = p.Results.show_plots;
should_shuffle = p.Results.shuffle;

% =========================================================================
% 2. 准备数据
% =========================================================================
fprintf('--- 开始PID解码分析 ---\n');

% 获取数据维度
[n_stimuli, n_trials, n_neurons, n_timepoints] = size(data);
fprintf('数据维度: %d个类别, %d次试验, %d个神经元, %d个时间点\n', n_stimuli, n_trials, n_neurons, n_timepoints);

% 划分训练集和测试集
if should_shuffle
    trial_indices = randperm(n_trials);
else
    trial_indices = 1:n_trials;
end

n_train_trials = floor(n_trials * train_ratio);
n_test_trials = n_trials - n_train_trials;

train_indices = trial_indices(1:n_train_trials);
test_indices = trial_indices(n_train_trials + 1:end);

data_train = data(:, train_indices, :, :);
data_test = data(:, test_indices, :, :);

fprintf('数据分割: %d个训练试验, %d个测试试验\n', n_train_trials, n_test_trials);

% =========================================================================
% 3. 训练PID解码器
% =========================================================================
fprintf('训练解码器...\n');

% 计算调谐曲线 f (在训练集上求平均)
f = squeeze(mean(data_train, 2)); % 维度: n_stimuli x n_neurons x n_timepoints

% 避免log(0)的技巧
epsilon = 1 / n_train_trials;
f(f < epsilon) = epsilon;

% 计算权重 W = log(f)
weights_W = log(f); % 维度: n_stimuli x n_neurons x n_timepoints

% 计算偏移 B = -sum(f) over neurons
offsets_B = -squeeze(sum(f, 2)); % 维度: n_stimuli x n_timepoints

% 将训练好的模型参数存入结构体
decoder_model.weights_W = weights_W;
decoder_model.offsets_B = offsets_B;
decoder_model.epsilon = epsilon;

fprintf('解码器训练完成！\n');

% =========================================================================
% 4. 测试解码器
% =========================================================================
fprintf('在测试集上进行解码...\n');

correct_counts = zeros(1, n_timepoints);
total_test_cases = n_stimuli * n_test_trials;
predictions = zeros(n_stimuli, n_test_trials, n_timepoints);

% 使用 parfor (并行计算) 可以显著加速测试过程
% 如果没有并行计算工具箱, MATLAB会自动退化为普通的 for 循环
parfor t = 1:n_timepoints
    
    % 获取当前时间点的权重和偏移
    W_t = weights_W(:, :, t); % n_stimuli x n_neurons
    B_t = offsets_B(:, t);     % n_stimuli x 1
    
    temp_correct_count = 0;
    temp_predictions = zeros(n_stimuli, n_test_trials);

    for s_true = 1:n_stimuli
        for tr = 1:n_test_trials
            % 获取当前试验的神经元响应向量 r
            r_vector = squeeze(data_test(s_true, tr, :, t))'; % 1 x n_neurons
            
            % 计算所有类别的对数似然
            log_likelihoods = W_t * r_vector' + B_t; % n_stimuli x 1
            
            % 找到最大似然对应的类别
            [~, s_pred] = max(log_likelihoods);
            
            temp_predictions(s_true, tr) = s_pred;
            
            if s_pred == s_true
                temp_correct_count = temp_correct_count + 1;
            end
        end
    end
    correct_counts(t) = temp_correct_count;
    predictions(:, :, t) = temp_predictions;
end

% 计算每个时间点的准确率
accuracy_over_time = correct_counts / total_test_cases;

fprintf('解码测试完成！\n');

% =========================================================================
% 5. 分析和可视化结果
% =========================================================================

% 找到峰值准确率及其时间点
[peak_accuracy, peak_time_index] = max(accuracy_over_time);
fprintf('分析完成。峰值准确率: %.2f%%，出现在时间点 T=%d\n', peak_accuracy * 100, peak_time_index);

% % 准备混淆矩阵所需数据
% true_labels = repmat((1:n_stimuli)', 1, n_test_trials);
% predicted_labels_at_peak = predictions(:, :, peak_time_index);
% 
% % 如果需要，则显示图表
% if show_plots
%     % 绘制解码准确率随时间变化的曲线
%     figure('Name', 'PID Decoding Accuracy Over Time');
%     plot(1:n_timepoints, accuracy_over_time * 100, 'b-', 'LineWidth', 2);
%     hold on;
%     % 绘制机会水平
%     chance_level = (1 / n_stimuli) * 100;
%     plot([1, n_timepoints], [chance_level, chance_level], 'r--', 'LineWidth', 1.5);
%     ylim([0, max(accuracy_over_time)+10]);
%     xlim([1, n_timepoints]);
%     xlabel('时间点 (Time Bin)');
%     ylabel('解码准确率 (%)');
%     title(sprintf('PID解码器表现 (峰值: %.2f%%)', peak_accuracy * 100));
%     legend('PID Accuracy', 'Chance Level');
%     grid on;
%     set(gca, 'FontSize', 12);
% 
%     % 绘制峰值时间点的混淆矩阵
%     figure('Name', 'Confusion Matrix at Peak Accuracy');
%     peak_confusion_chart = confusionchart(true_labels(:), predicted_labels_at_peak(:));
%     peak_confusion_chart.Title = sprintf('在时间点 T=%d 的混淆矩阵', peak_time_index);
%     peak_confusion_chart.RowSummary = 'row-normalized';
%     peak_confusion_chart.ColumnSummary = 'column-normalized';
% else
%     % 如果不绘图，则生成混淆矩阵对象但不显示
%     peak_confusion_chart = confusionmat(true_labels(:), predicted_labels_at_peak(:));
% end

fprintf('--- PID解码分析结束 ---\n');

end