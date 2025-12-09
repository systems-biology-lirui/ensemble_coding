%% Pipeline_LFP_Analysis_DG.m
% 这是一个专门为 DG 数据的 MGnv 和 MGv 条件构建的 LFP 分析 Pipeline。
% 修改记录:
% - [Date] 切换到 NeuroDB.NeuroAnalyzer 进行数据加载和频谱分析

%% 1. 初始化配置
clc; clear; close all;

% 加载主配置
config = main_config();
config.Subject = 'DG';

% 数据库路径
dbPath = config.Path.DB;

%% 2. 加载数据并进行频谱分析

% 执行处理
% 注意: analyzer 内部会自动读取 Fs，不需要显式传递
target_freq = 6.25;
cov_freq = 25;

Power_MGnv = process_condition_v2(config.Subject, 'MGnv', dbPath, target_freq, cov_freq);
Power_MGv  = process_condition_v2(config.Subject, 'MGv',  dbPath, target_freq, cov_freq);

%% 3. 协方差分析 (ANCOVA) 修正
% 逻辑参考 +NeuroTool/get_ancova_diff.m
fprintf('\n正在进行协方差修正 (ANCOVA Logic)...\n');

Y_MGnv_adj = get_ancova_diff(Power_MGnv);
Y_MGv_adj = get_ancova_diff(Power_MGv);
%% 4. 绘制结果
fprintf('正在绘制结果...\n');

figure('Color', 'w', 'Position', [200, 200, 600, 500]);
ax = gca;

% 准备数据
data_cell = {Y_MGnv_adj, Y_MGv_adj};
group_names = {'MGnv (Corrected)', 'MGv (Corrected)'};

% 调用 NeuroPlot.bar_with_scatter
NeuroPlot.bar_with_scatter(ax, data_cell, group_names, ...
    'ShowSigVs0', false, ...     % 功率通常 > 0，检测 vs 0 意义不大
    'ComparePairs', [1 2], ...   % 比较 MGnv vs MGv
    'TestType', 'ttest2', ...    % 独立样本 t 检验
    'YLimExpand', 1.2);

ylabel(sprintf('Power at %.2f Hz (Corrected)', target_freq));
title(sprintf('Subject %s: ANCOVA Corrected Power', config.Subject));

fprintf('完成。\n');

%% 5. 辅助函数定义
function power_matrix = process_condition_v2(subject, condition, dbPath, targetFreq, covFreq)
    fprintf('>>> 处理条件: %s <<<\n', condition);
    
    % 1. 初始化 NeuroAnalyzer
    % 参数: Subject, Block(Condition), Paradigm, DataType, DBPath
    % 假设 Paradigm 为 'SSVEP_A'，与原文件名一致
    paradigm = 'SSVEP_A';
    dataType = 'LFP';
    
    % 实例化 NeuroAnalyzer
    analyzer = NeuroDB.NeuroAnalyzer(subject, condition, paradigm, dataType, dbPath);
    
    % 2. 频谱分析 (Trial-Level)
    % 使用 'Trial-Level' 模式获取所有 Trial 的 PSD (不聚合)
    fprintf('  调用 analyzer.analyze_spectrum (Trial-Level)...\n');
    [psdResult, fVec, info] = analyzer.analyze_spectrum('Method', 'Default', 'RemoveDC', true);
    
    % psdResult 维度: [Trials x Channels x Freq]
    
    % 3. 提取频率索引
    [~, idx_target] = min(abs(fVec - targetFreq));
    [~, idx_cov]    = min(abs(fVec - covFreq));
    
    fprintf('  提取频率: Target=%.2fHz, Covariate=%.2fHz\n', fVec(idx_target), fVec(idx_cov));
    
    % 4. 提取功率值
    % 策略: 先对所有通道取平均，得到每个 Trial 的平均功率
    % psdResult Dim 2 是 Channels
    target_idx = find(info.Meta.Condition~=-1);
    P1_avg_target = squeeze(mean(psdResult(target_idx,:,:), 1)); % -> [Trials x Freq]
    
    random_idx = find(info.Meta.Condition==-1);
    P1_avg_random = squeeze(mean(psdResult(random_idx,:,:), 1)); % -> [Trials x Freq]

    power_matrix_target = cat(2,P1_avg_target(:, idx_target),P1_avg_target(:, idx_cov));
    power_matrix_random = cat(2,P1_avg_random(:, idx_target),P1_avg_random(:, idx_cov));
    power_matrix = cat(3,power_matrix_target,power_matrix_random);
    % n_trials = length(power_target);
    
    fprintf('  提取完成，channel 数: %d\n', size(psdResult,2));
end
