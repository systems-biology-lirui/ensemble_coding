function performTwoWayAnova(A_data, B_data)
    % 输入参数:
    %   A_data: 4x18 矩阵 (4种条件 x 18个样本)
    %   B_data: 4x18 矩阵 (4种条件 x 18个样本)
    
    % 合并数据并创建分组变量
    allData = [A_data(:); B_data(:)];
    
    % 创建条件分组变量 (1-4)
    conditions = repmat((1:4)', 18 * 2, 1);  % 每种条件18样本 x 2种方法
    
    % 创建处理方法分组变量 (A/B)
    methods = [repmat("A", numel(A_data), 1); repmat("B", numel(B_data), 1)];
    
    % 执行双因素方差分析
    [p, tbl, stats] = anovan(allData, {conditions, methods}, ...
        'model', 'interaction', ...
        'varnames', {'Condition', 'Method'}, ...
        'display', 'on');
    
    % 显示ANOVA结果
    disp('双因素方差分析结果:');
    disp(tbl);
    
    % 可视化结果
    visualize_results(A_data, B_data);
end

function visualize_results(A_data, B_data)
    % 计算均值和标准误
    A_mean = mean(A_data, 2);
    A_se = std(A_data, 0, 2) / sqrt(size(A_data, 2));
    
    B_mean = mean(B_data, 2);
    B_se = std(B_data, 0, 2) / sqrt(size(B_data, 2));
    
    % 创建图形
    figure('Position', [100, 100, 800, 600]);
    
    % 绘制均值折线图
    subplot(2, 1, 1);
    hold on;
    errorbar(1:4, A_mean, A_se, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0 0.447 0.741]);
    errorbar(1:4, B_mean, B_se, 's-', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.85 0.325 0.098]);
    
    % 美化图形
    % title('不同条件和处理方法的均值比较');
    xlabel('Cue');
    ylabel('RT');
    xticks(1:4);
    legend({'data pre', 'data post'}, 'Location', 'best');
    % grid on;
    xticklabels({'Large', 'Small', 'Both', 'No'});
    set(gca, 'FontSize', 12);
    xlim([0,5])
    % 绘制箱线图
    subplot(2, 1, 2);
    hold on;
    
    % 重组数据用于箱线图
    plotData = [A_data; B_data]';
    groupMatrix = [ones(1, 18), 2*ones(1, 18), 3*ones(1, 18), 4*ones(1, 18);
                  5*ones(1, 18), 6*ones(1, 18), 7*ones(1, 18), 8*ones(1, 18)]';
    
    % 创建分组箱线图
    boxplot(plotData(:), groupMatrix(:), 'colors', 'br', 'symbol', 'k+');
    
    % 设置坐标轴标签
    set(gca, 'XTick', 1.5:2:8.5, 'XTickLabel', {'Large', 'Small', 'Both', 'No'});
    ylabel('RT');
    % title('数据分布箱线图');
    
    % 添加图例
    h = findobj(gca, 'Tag', 'Box');
    legend(h([end-1, end]), {'data pre', 'data post'}, 'Location', 'best');
    
    yl = ylim;  % 获取当前Y轴范围
    for k = 2.5:2:6.5
        hLine = line([k k], yl, 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
        
        % 关键设置：确保分隔线不出现在图例中
        set(hLine, 'HandleVisibility', 'off');
    end
    
    % grid on;
    set(gca, 'FontSize', 12);
end