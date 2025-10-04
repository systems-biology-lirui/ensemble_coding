function [fig, ax, anova_stats, multcomp_results, p_val] = advancedBarPlot(data, options)
% advancedBarPlot - 创建一个美观的、带散点、连线和显著性标记的条形图
%
% 语法:
%   [fig, ax, anova_stats, multcomp_results] = advancedBarPlot(data)
%   [...] = advancedBarPlot(data, 'Name', Value, ...)
%
% 描述:
%   此函数接收一个数据矩阵，其中每列是一个组，每行是一个样本。
%   它会执行以下操作：
%   1. 绘制带有误差棒（标准误）的条形图。
%   2. 在条形图上叠加每个原始数据点（带水平抖动）。
%   3. 用细线连接每行（样本）在不同组之间的点。
%   4. 执行单因素ANOVA和Tukey's HSD多重比较，并在图上标记显著性。
%   5. (可选) 对每组数据执行单样本t检验（与指定值比较），并标记显著性。
%
% 输入:
%   data - M x N 矩阵，M是样本数，N是组数。
%
% 可选 'Name', Value 对:
%   'groupNames'     - 包含N个组名的 cell 数组 (e.g., {'Control', 'Treat1', 'Treat2'})。
%                      默认为 {'Group 1', 'Group 2', ...}。
%   'yLabel'         - Y轴标签的字符串。默认为 'Value'。
%   'titleText'      - 图表标题的字符串。默认为 'Group Comparison'。
%   'alpha'          - 显著性水平。默认为 0.05。
%   'barColor'       - 条形图的颜色。可以是颜色名称、RGB三元组或Nx3的颜色矩阵。
%                      默认为 MATLAB 的默认蓝色。
%   'dotColor'       - 散点的颜色。默认为灰色。
%   'lineColor'      - 连接线的颜色。默认为浅灰色。
%   'performTTest'   - 【新增】逻辑值(true/false)，是否对每组执行与'testAgainstValue'的t检验。默认为 false。
%   'testAgainstValue' - 【新增】t检验的目标值。默认为 0。
%   'tTestSymbol'    - 【新增】t检验显著性的标记符号。默认为 '#'。
%
% 输出:
%   fig              - 图形句柄。
%   ax               - 坐标轴句柄。
%   anova_stats      - anova1 函数的统计输出。
%   multcomp_results - multcompare 函数的结果矩阵。
%
% 示例:
%   % 1. 生成示例数据
%   data = [randn(10,1)+0.5; randn(10,1)+0.5]; % 组1接近0
%   data = [data, data+2+randn(20,1)*0.5, data+4+randn(20,1)*0.5]; % 组2和3显著大于0
%   group_names = {'Control', 'Treatment A', 'Treatment B'};
%
%   % 2. 调用函数，并执行t检验
%   [fig, ax, stats, comps] = advancedBarPlot(data, ...
%       'groupNames', group_names, ...
%       'yLabel', 'Response Value', ...
%       'titleText', 'Effect of Treatments (vs Control & vs 0)', ...
%       'performTTest', true, ...
%       'testAgainstValue', 0, ...
%       'tTestSymbol', '#');
%
% 作者: MATLAB AI Assistant
% 版本: 1.1
% 日期: 2023-10-28

% =========================================================================
%  【智能提示修改】 开始：使用 arguments 块
% =========================================================================
arguments
    % 1. 位置参数 (必须提供)
    data (:,:) {mustBeNumeric, mustBeNonempty}

    % 2. 名称-值对参数 (可选，都放在 "options" 结构体里)
    % 语法: options.参数名 (大小限制) {验证函数} = 默认值;
    options.groupNames cell = {}
    options.yLabel string = "Value"
    options.titleText string = "Group Comparison"
    options.alpha (1,1) {mustBeNumeric, mustBeInRange(options.alpha, 0, 1, 'exclusive')} = 0.05
    options.barColor {mustBeA(options.barColor, ["numeric", "char", "string"])} = [0 0.4470 0.7410] % 默认值使用RGB
    options.dotColor {mustBeA(options.dotColor, ["numeric", "char", "string"])} = [0.5 0.5 0.5]
    options.lineColor {mustBeA(options.lineColor, ["numeric", "char", "string"])} = [0.8 0.8 0.8]
    options.performTTest (1,1) logical = true
    options.testAgainstValue (1,1) double = 0
    options.tTestSymbol (1,1) string = "#"
end
% =========================================================================
%  【智能提示修改】 结束
% =========================================================================

% --- 1. 参数准备 (不再需要 inputParser) ---
% 直接从 options 结构体和 data 变量中获取值
if isempty(options.groupNames)
    % 用户未提供 groupNames，现在根据 data 的大小计算默认值
    numGroups = size(data, 2);
    groupNames = arrayfun(@(x) string(['Group ' num2str(x)]), 1:numGroups);
else
    % 用户已提供，直接使用
    groupNames = options.groupNames;
end
yLabelText = options.yLabel;
titleText = options.titleText;
alpha = options.alpha;
barColor = options.barColor;
dotColor = options.dotColor;
lineColor = options.lineColor;
performTTest = options.performTTest;
testAgainstValue = options.testAgainstValue;
tTestSymbol = options.tTestSymbol;

% --- 2. 数据准备 ---
[numPoints, numGroups] = size(data);
means = mean(data, 1, 'omitnan');
sems = std(data, 0, 1) / sqrt(numPoints);

% --- 3. 绘图 ---
fig = figure('Position', [100, 100, 400 + numGroups*80, 500], 'Color', 'w');
ax = gca;
hold(ax, 'on');

% 3.1 绘制条形图和误差棒
b = bar(1:numGroups, means, 0.6,'LineWidth',0.5);
b.FaceColor = 'flat';
if size(barColor, 1) == numGroups
    b.CData = barColor;
else
    b.CData = repmat(barColor, numGroups, 1);
end

errorbar(1:numGroups, means, sems, 'k.', 'LineWidth', 1.5, 'CapSize', 12);

% 3.2 绘制连接线和抖动散点
jitterWidth = 0.1;
jitter_matrix = (rand(numPoints, numGroups) - 0.5) * jitterWidth;
x_base = repmat(1:numGroups, numPoints, 1);
x_jittered = x_base + jitter_matrix;

for i = 1:numPoints
    plot(ax, x_jittered(i, :), data(i, :), '-', ...
        'Color', lineColor, 'LineWidth', 1, 'HandleVisibility', 'off');
end
for i = 1:numGroups
    scatter(ax, x_jittered(:,i), data(:,i), 35, ...
        'MarkerFaceColor', dotColor(i,:), 'MarkerEdgeColor', 'none', ...
        'MarkerFaceAlpha', 0.2, 'HandleVisibility', 'off');
end
% 【新增】3.5. 单样本 t-检验 (可选)
% 【修改】创建一个变量来追踪每个条形上方的最高点，初始为误差棒顶端
y_tops = means + sems;
% 处理数据全为负数的情况，确保y_tops是顶端
y_tops_data_max = max(data,[],1);
y_tops = max(y_tops, y_tops_data_max);
y_tops(isnan(y_tops)) = 0; %
y_range = diff(get(ax, 'YLim'));
if y_range == 0, y_range = max(abs(y_tops))*0.2; end % 避免除以0
y_offset_ttest = y_range * 0.05; % t检验标记的垂直偏移量
p_val = zeros(numGroups,1);
if performTTest
    for i = 1:numGroups
        % 对非NaN数据执行t检验
        valid_data = data(~isnan(data(:,i)), i);
        if ~isempty(valid_data)
            [h, p_val(i)] = ttest(valid_data, testAgainstValue, 'Alpha', alpha);
            if p_val(i) < 0.001, tTestSymbol = '***';
            elseif p_val(i) < 0.01, tTestSymbol = '**';
            elseif p_val(i) < 0.05, tTestSymbol = '*';
            else 
                tTestSymbol = '*';
            end

            if h % 如果显著 (h=1)
                % 计算标记的Y坐标，放在误差棒/数据点的上方
                y_pos = y_tops(i) + y_offset_ttest;

                % 添加标记
                text(ax, i, y_pos, tTestSymbol, ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'bottom', ...
                    'FontSize', 14, 'FontWeight', 'bold');

                % 【修改】更新该组的最高点位置
                y_tops(i) = y_pos;
            end
        end
    end
end


% --- 4. 统计分析 ---
data_stacked = data(:);
group_matrix = repelem(1:numGroups, numPoints, 1);
group_indices = group_matrix(:);
% 过滤掉NaN值进行ANOVA
valid_idx = ~isnan(data_stacked);
[anova_p, anova_table, anova_stats] = anova1(data_stacked(valid_idx), group_indices(valid_idx), 'off');

if anova_p < alpha
    multcomp_results = multcompare(anova_stats, 'CType', 'tukey-kramer', 'Display', 'off', 'Alpha', alpha);
    significant_pairs = multcomp_results(multcomp_results(:, 6) < alpha, 1:2);
    p_values = multcomp_results(multcomp_results(:, 6) < alpha, 6);

    % --- 5. 绘制显著性标记 ---
    if ~isempty(significant_pairs)
        % 【修改】将更新后的 y_tops 传递给辅助函数
        addSignificanceBars(ax, significant_pairs, p_values, y_tops);
    end
else
    multcomp_results = [];
    disp('ANOVA is not significant (p > alpha), no multiple comparisons performed.');
end

% --- 6. 美化图形 ---
hold(ax, 'off');
set(ax, ...
    'XTick', 1:numGroups, ...
    'XTickLabel', groupNames, ...
    'FontSize', 12, ...
    'LineWidth', 1.2, ...
    'box', 'off', ...
    'TickDir', 'out');
ylabel(yLabelText);
title(titleText);
xtickangle(ax, 0);

% 调整Y轴范围，为显著性标记留出空间
ylim_current = get(ax, 'YLim');
ylim_new_max = ylim_current(2) * 1.05; % 增加5%的顶部空间
set(ax, 'YLim', [ylim_current(1), ylim_new_max]);

% 检查是否有显著性标记，并相应调整Y轴
if exist('significant_pairs', 'var') && ~isempty(significant_pairs)
    % 查找所有绘制的线条和文本对象
    h_lines = findobj(ax, 'Type', 'line');
    h_texts = findobj(ax, 'Type', 'text');
    max_y = ylim_current(2);
    for i = 1:length(h_lines)
        max_y = max([max_y, h_lines(i).YData]);
    end
    for i = 1:length(h_texts)
        pos = get(h_texts(i), 'Position');
        if ~isempty(pos)
            max_y = max(max_y, pos(2));
        end
    end
    ylim(ax, [ylim_current(1), max_y * 1.1]); % 在最高标记上再增加10%空间
else
max_y = ylim_current(2);
end
ylim(ax, [ylim_current(1), max_y * 1.1]); % 在最高标记上再增加10%空间

end


% --- 辅助函数：添加显著性标记 ---
% 【修改】函数签名，接收 y_tops 而不是原始数据
function addSignificanceBars(ax, pairs, p_values, y_tops)
numGroups = length(y_tops);

% 对组对进行排序，以便优先绘制跨度小的条，避免交叉
[~, sort_idx] = sort(abs(pairs(:,1) - pairs(:,2)));
pairs = pairs(sort_idx,:);
p_values = p_values(sort_idx);

% 【修改】y_step的计算方式更稳健
y_lim = get(ax, 'YLim');
y_step = (y_lim(2) - y_lim(1)) * 0.08;
if y_step <= 0 || isinf(y_step)
    y_step = max(abs(y_tops)) * 0.1;
    if y_step == 0, y_step = 1; end % 最终备用
end

% 【修改】level_tracker 直接使用传入的 y_tops 初始化
% 这确保了多重比较的线会画在t检验标记的上方
level_tracker = y_tops;

for i = 1:size(pairs, 1)
    g1 = min(pairs(i, :)); % 确保g1 < g2
    g2 = max(pairs(i, :));

    y_pos = max(level_tracker(g1:g2)) + y_step;

    plot(ax, [g1, g2], [y_pos, y_pos], 'k', 'LineWidth', 1);
    plot(ax, [g1, g1], [y_pos, y_pos - y_step*0.2], 'k', 'LineWidth', 1);
    plot(ax, [g2, g2], [y_pos, y_pos - y_step*0.2], 'k', 'LineWidth', 1);

    p_val = p_values(i);
    if p_val < 0.001, star_str = '***';
    elseif p_val < 0.01, star_str = '**';
    else, star_str = '*';
    end

    text_x = mean([g1, g2]);
    text_y = y_pos + y_step * 0.1;
    text(ax, text_x, text_y, star_str, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', 14, 'FontWeight', 'bold');

    level_tracker(g1:g2) = y_pos + y_step * 0.5; % 为星号文本留出更多空间
end
end