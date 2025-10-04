% --- 0. 环境设置 ---
function cue_anovaplot(data,p_05,ylabel1)

% --- 1. 准备数据 ---
% 假设这是您的 4x6 矩阵 (4个条件, 6个session/被试)
% 为了演示，我们生成一些随机数据
% 条件1 (L) 的均值稍高于0.5
% 条件2 (S) 的均值稍低于0.5
% 条件3 (No) 的均值接近0.5
% 条件4 (Both) 的均值显著高于0.5

% 定义条件的标签
condition_labels = {'L', 'S', 'No', 'Both'};
num_conditions = size(data, 1);
num_sessions = size(data, 2);

%% --- 2. 统计分析：单因素方差分析 (One-way ANOVA) ---
data_vector = data(:); 
group = repelem(condition_labels, 1, num_sessions); 

fprintf('--- 单因素方差分析 (ANOVA) 结果 ---\n');
[p_anova, tbl, stats] = anova1(data_vector, group, 'off');
fprintf('4个条件之间的总体差异显著性 (ANOVA p-value): %.4f\n', p_anova);
if p_anova < 0.05
    fprintf('结论: 至少有一对条件之间存在显著差异。\n\n');
else
    fprintf('结论: 4个条件之间没有发现显著的总体差异。\n\n');
end

%% --- 3. 统计分析：事后检验 (Post-hoc Test) ---
if p_anova < 0.05
    fprintf('--- 事后检验 (Tukey''s HSD) 结果 ---\n');
    c = multcompare(stats, 'ctype', 'hsd', 'Display', 'off');
    disp('组1  组2   p-value');
    sig_pairs_idx = find(c(:,6) < 0.05);
    if isempty(sig_pairs_idx)
        disp('在 alpha=0.05 水平下，没有发现显著差异的配对。');
    else
        for i = 1:length(sig_pairs_idx)
            idx = sig_pairs_idx(i);
            g1_idx = c(idx, 1);
            g2_idx = c(idx, 2);
            p_val = c(idx, 6);
            fprintf('%-4s vs %-4s: p = %.4f\n', condition_labels{g1_idx}, condition_labels{g2_idx}, p_val);
        end
    end
    fprintf('\n');
end

%% --- 4. 统计分析：单样本 t-检验 (vs 0.5) ---
fprintf('--- 单样本 t-检验 (与 0.5 比较) ---\n');

% *** 新增部分：创建一个向量来存储 t-检验的结果 ***
% h=1 表示显著, h=0 表示不显著
h_vs_05 = zeros(num_conditions, 1); 

for i = 1:num_conditions
    [h, p_ttest, ci, t_stats] = ttest(data(i, :), 0.5);
    
    % 将结果存储起来
    h_vs_05(i) = h;
    
    fprintf('条件 ''%s'' vs 0.5: p = %.4f', condition_labels{i}, p_ttest);
    if h == 1
        fprintf(' (显著差异)\n');
    else
        fprintf(' (无显著差异)\n');
    end
end
fprintf('\n');

%% --- 5. 数据可视化：绘制柱状图并标注显著性 ---

% 计算每个条件的均值和标准误 (SEM)
means = mean(data, 2);
sem = std(data, 0, 2) / sqrt(num_sessions);

% 创建图窗
figure('Position', [100, 100, 800, 600]);
hold on;

% 绘制柱状图
bar_color = [0.2, 0.6, 0.8]; 
b = bar(1:num_conditions, means, 'FaceColor', bar_color, 'BarWidth', 0.6);

% 添加误差棒
errorbar(1:num_conditions, means, sem, 'k.', 'LineWidth', 1.5, 'CapSize', 10);


% *** 新增功能：在bar上方标注与0.5的显著性 ***
% 定义一个小的垂直偏移量，让符号显示在误差棒上方
if p_05 ==1
    symbol_offset = max(means + sem) * 0.05;
    for i = 1:num_conditions
        [h, p_ttest, ci, t_stats] = ttest(data(i, :), 0.5);
        if h_vs_05(i) == 1
            if p_ttest < 0.001
                star_str = '***';
            elseif p_ttest < 0.01
                star_str = '**';
            else
                star_str = '*';
            end
            % 如果这个条件与0.5有显著差异，则在其上方添加符号
            % 使用 '#' 符号以区别于组间比较的 '*'
            text(i, means(i) + sem(i) + symbol_offset, star_str, ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', ...
                'FontSize', 16, ...
                'Color', 'k',...
                'FontWeight', 'bold');
        end
    end
end

% --- 添加条件之间的显著性标注 (ANOVA的事后检验结果) ---
if p_anova < 0.05 && exist('c','var') && ~isempty(c)
    sig_pairs = c(c(:,6) < 0.05, 1:2);
    p_values_pairs = c(c(:,6) < 0.05, 6);
    
    % 找到所有柱子+误差棒的最高点，以确定标注线的起始高度
    % 也要考虑刚刚添加的 '#' 符号的高度
    max_y_with_symbol = max(means + sem + h_vs_05*symbol_offset*2);
    y_increment = max_y_with_symbol * 0.1; 
    y_level = max_y_with_symbol + y_increment;

    for i = 1:size(sig_pairs, 1)
        pair = sig_pairs(i, :);
        p_val = p_values_pairs(i);
        
        if p_val < 0.001
            star_str = '***';
        elseif p_val < 0.01
            star_str = '**';
        else
            star_str = '*';
        end
        
        line(pair, [y_level, y_level], 'Color', 'k', 'LineWidth', 1.5);
        text(mean(pair), y_level, star_str, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontSize', 16);
            
        y_level = y_level + y_increment;
    end
    
    % 调整y轴范围以容纳所有标注
    ylim([0, y_level]);
end
if p_05==1
    ylim([0,1.5]);
else 
    ylim([0,max(means)+500]);
end
% --- 美化图表 ---
hold off;
ax = gca;
ax.XTick = 1:num_conditions;
ax.XTickLabel = condition_labels;
ax.FontSize = 12;
ax.Box = 'off';
ylabel(ylabel1, 'FontSize', 14);
title({'No Hetero Training'}, 'FontSize', 16);