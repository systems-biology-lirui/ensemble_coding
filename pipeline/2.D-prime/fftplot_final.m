%% --- 1. 配置与数据加载 ---

clear; 
close all; 
clc;

% 加载数据
load('QQ_exp1b_LFP_MGv_fftplot.mat');
Labels = {'MGv','MGnv','SG'};
load('D:\ensemble_coding\QQdata\tooldata\QQchannelselect.mat')
selchannel =  [75,79,43,78,81,41,45,82,84,38,47,49,85,42,44,51,88,17,50,46,89,8,54,52,58,91,92,23,25,21,62,60,14,16,20,27,29,31,63,56,22,24,26,28];

% 定义常量和参数
Fs = 500;
N = 1600;
f = Fs * (0:N/2) / N;
plot_range = 1:100; % 定义绘图的频率范围索引

% 定义绘图样式
special_points = [6.25, 25];
color_target = [0.7, 0, 0];       % 'Target' 数据的颜色 (深红)
color_random = [0.7, 0.7, 0.7];   % 'Random' 数据的颜色 (灰色)
line_width_target = 3;
line_width_random = 2.3;


% --- 2. 主绘图循环 ---

for i = 1:length(Labels)
    % 为每个 Label 创建一个新 Figure
    figure('Position', [100, 100, 300, 750]); % 调整了尺寸以适应内容
    sgtitle(['Analysis for ', Labels{i}], 'FontSize', 14, 'FontWeight', 'bold');

    % --- 子图1: 幅度谱 (Amplitude) ---
    ax1 = subplot(4, 1, 1);
    hold(ax1, 'on');
    plot(ax1, f(plot_range), plot_content.(Labels{i}).random_am, 'LineWidth', line_width_random, 'Color', color_random);
    plot(ax1, f(plot_range), plot_content.(Labels{i}).target_am, 'LineWidth', line_width_target, 'Color', color_target);
    xline(ax1, special_points, '--');
    hold(ax1, 'off');
    
    title(ax1, 'Amplitude Spectrum');
    ylabel(ax1, 'Amplitude');
    legend(ax1, 'Random', 'Target', 'Location', 'north');
    xlim(ax1,[0,30])
    ylim(ax1, [0, 120]);
    box(ax1, 'off');
    
    % 调用辅助函数设置X轴
    set_custom_xticks(ax1, special_points, color_target);
    % --- 子图2: D-prime 对比图 ---
    ax2 = subplot(4, 1, 2);
    data_before = plot_content.(Labels{i}).dprimeresult{1}(1, selchannel);
    data_after = plot_content.(Labels{i}).dprimeresult{1}(3, selchannel);
    xlim(ax1,[0,30])
    % 调用专门的绘图函数来绘制复杂的D-prime图
    plot_dprime_comparison(ax2, data_before, data_after, color_target, color_random);

    % --- 子图3: 相位谱 (Phase) ---
    ax3 = subplot(4, 1, 3);
    hold(ax3, 'on');
    plot(ax3, f(plot_range), plot_content.(Labels{i}).random_ph, 'LineWidth', line_width_random-1, 'Color', color_random);
    plot(ax3, f(plot_range), plot_content.(Labels{i}).target_ph, 'LineWidth', line_width_target-1, 'Color', color_target);
    xline(ax3, special_points, '--');
    hold(ax3, 'off');
    
    title(ax3, 'Phase Spectrum');
    ylabel(ax3, 'Phase');
    box(ax3, 'off');
    xlim(ax1,[0,30])
    % 再次调用辅助函数设置X轴
    set_custom_xticks(ax3, special_points, color_target);

    % --- 子图4: Phase D-prime 对比图 ---
    ax4 = subplot(4, 1, 4);
    data_before = plot_content.(Labels{i}).dprimeresult{2}(1, selchannel);
    data_after = plot_content.(Labels{i}).dprimeresult{2}(3, selchannel);
    xlim(ax1,[0,30])
    % 调用专门的绘图函数来绘制复杂的D-prime图
    plot_dprime_comparison(ax4, data_before, data_after, color_target, color_random);
    
    filename = sprintf('Analysis_%s.png', Labels{i});  % 生成文件名
    saveas(gcf, filename);  % 保存当前 Figure
    close(gcf);  % 关闭当前 Figure，避免内存占用
end
%%
figure('Position', [100, 100, 300, 350]);
data_before = plot_content.MGnv.dprimeresult{1}(1,selchannel)-plot_content.normfitMGnv.dprimeresult{1}(1,selchannel);
data_after = plot_content.MGnv.dprimeresult{1}(3,selchannel)-plot_content.normfitMGnv.dprimeresult{1}(3,selchannel);
ax1=subplot(1,1,1);
plot_dprime_comparison(ax1, data_before, data_after, color_target, color_random);
title('MGnv-normfitMGnv')
%% --- 3. 辅助函数 (Helper Functions) ---

function set_custom_xticks(ax, special_points, special_color)
    % 功能：为一个坐标轴(ax)设置包含特殊点的X轴刻度和颜色。
    
    xlabel(ax, 'Frequency (Hz)'); % X轴标签是通用的，也放在这里
    
    % 获取并合并刻度
    current_ticks = xticks(ax);
    new_ticks = unique(sort([current_ticks, special_points]));
    xticks(ax, new_ticks);
    
    % 创建并应用自定义标签
    new_labels = cell(size(new_ticks));
    for k = 1:length(new_ticks)
        tick_val = new_ticks(k);
        if ismember(tick_val, special_points)
            % 为特殊点设置颜色和粗体
            new_labels{k} = sprintf('\\color[rgb]{%f,%f,%f}\\bf{%g}', special_color, tick_val);
        else
            new_labels{k} = sprintf('%g', tick_val);
        end
    end
    xticklabels(ax, new_labels);
    xtickangle(ax, 45);
end


function plot_dprime_comparison(ax, data1, data2, color1, color2)
    % 功能：在指定坐标轴(ax)上绘制D-prime对比条形图，并进行配对t检验及对零值检验。

    hold(ax, 'on');
    
    % --- 数据处理与统计 ---
    
    % 1. 配对 t 检验 (比较 data1 和 data2 之间)
    [h_paired, p_paired] = ttest(data1, data2);

    % 2. 单样本 t 检验 (比较 data1 vs 0)
    [h1_zero, p1_zero] = ttest(data1, 0);

    % 3. 单样本 t 检验 (比较 data2 vs 0)
    [h2_zero, p2_zero] = ttest(data2, 0);

    means = [mean(data1), mean(data2)];
    stds = [std(data1), std(data2)];
    x_coords = [1, 2];
    
    % 定义 P 值到符号的转换函数
    function sig_symbol = get_sig_symbol(p_value)
        if p_value < 0.001, sig_symbol = '***';
        elseif p_value < 0.01, sig_symbol = '**';
        elseif p_value < 0.05, sig_symbol = '*';
        else, sig_symbol = '';
        end
    end
    
    % --- 绘制图形元素 ---
    
    % 1. 连接线
    for i = 1:length(data1)
        plot(ax, x_coords, [data1(i), data2(i)], '-', 'Color', [0.8, 0.8, 0.8]);
    end

    % 2. 条形图
    b = bar(ax, x_coords, means, 0.6);
    b.FaceColor = 'flat';
    b.CData(1,:) = color1;
    b.CData(2,:) = color2;
    b.EdgeColor = 'none';

    % 3. 误差棒
    errorbar(ax, x_coords, means, stds, 'k', 'LineStyle', 'none', 'LineWidth', 1.5);
    
    % 4. 散点图 (带抖动)
    jitter_amount = 0.1;
    scatter(ax, x_coords(1) + (rand(size(data1))-0.5)*jitter_amount, data1, 24, 'filled', ...
            'MarkerFaceColor', color1, 'MarkerEdgeColor', [0.2,0.2,0.2], 'MarkerFaceAlpha', 0.6);
    scatter(ax, x_coords(2) + (rand(size(data2))-0.5)*jitter_amount, data2, 24, 'filled', ...
            'MarkerFaceColor', color2, 'MarkerEdgeColor', [0.2,0.2,0.2], 'MarkerFaceAlpha', 0.6);

    % 5. 显著性标记 (对零值的检验)
    y_buffer = 0.5; % 标记相对于误差棒顶部的垂直偏移

    % Group 1 vs 0
    sig_symbol1 = get_sig_symbol(p1_zero);
    if ~isempty(sig_symbol1)
        y_pos1 = means(1) + stds(1) + y_buffer;
        text(ax, x_coords(1), y_pos1, sig_symbol1, 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'bottom', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');
    end

    % Group 2 vs 0
    sig_symbol2 = get_sig_symbol(p2_zero);
    if ~isempty(sig_symbol2)
        y_pos2 = means(2) + stds(2) + y_buffer;
        text(ax, x_coords(2), y_pos2, sig_symbol2, 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'bottom', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');
    end
    
    % 6. 显著性标记 (配对比较)
    if h_paired == 1
        sig_symbol_paired = get_sig_symbol(p_paired);
        
        % 确定配对显著性标记的基线高度 (高于所有零值标记)
        y_max_data = max(means + stds);
        y_max_sig_zero = max([y_max_data, means(1) + stds(1) + y_buffer, means(2) + stds(2) + y_buffer]);
        
        y_top = y_max_sig_zero * 1.05 + 0.6; % 在最高的标记之上留出空间
        y_whisker = 0.05;

        plot(ax, [1, 1, 2, 2], [y_top-y_whisker, y_top, y_top, y_top-y_whisker], '-k', 'LineWidth', 1.2);
        text(ax, mean(x_coords), y_top, sig_symbol_paired, 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'bottom', 'FontSize', 16, 'FontWeight', 'bold');
    end
    
    hold(ax, 'off');

    % --- 坐标轴美化 ---
    xticks(ax, [1, 2]);
    xticklabels(ax, {'6.25hz (Ensemble)', '25hz (Individual)'});
    % xticklabels(ax, {'MGv (6.25hz)', 'fitMGv (6.25hz)'});
    ylabel(ax, 'D-prime (channels)');
    xlim(ax, [0.5, 2.5]);
    
    % 动态调整 Y 轴上限以确保所有标记可见
    y_current_max = max(ax.YLim);
    if exist('y_top', 'var')
        y_max_needed = y_top * 1.1; 
    else
        y_max_needed = max(means + stds) * 1.2;
    end
    
    % 确保 Y 轴下限至少为 -1，上限足够高
    ylim(ax, [-1,4]);
    
    box(ax, 'off');
end