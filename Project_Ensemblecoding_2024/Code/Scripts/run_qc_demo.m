%% Run QC Demo
% 这是一个演示脚本，用于展示如何使用 NeuroQC 包进行信号质量评估

% 1. 设置环境
% clear; clc;
dbPath = 'd:\ensemble_coding\Project_Ensemblecoding_2024\Data\01_Database';

% 2. 加载数据 (NeuroAnalyzer)
% 选取一个存在的 Master 文件: DG_SSGv_SSVEP_B_MUA2Master.mat
subject  = 'DG';
block    = 'MGv';
paradigm = 'EVENT';
dataType = 'MUA2';

fprintf('正在加载数据: %s - %s...\n', subject, block);
% try
%     na = NeuroDB.NeuroAnalyzer(subject, block, paradigm, dataType, dbPath);
% catch ME
%     fprintf('加载失败: %s\n', ME.message);
%     return;
% end
% 
% % 3. 提取 Single Trial Epochs
% % 为了进行 QC，我们需要原始的单次试次数据，而不是平均后的数据
% fprintf('正在切片 (Single Trials)...\n');
% [epochData, epochMeta] = na.slice_epochs1('SingleTrials', true, 'Verbose', true);

% 4. 初始化 QC 分析器
fprintf('初始化 QC 模块...\n');
epochData = EpochDB.Data;
epochMeta = EpochDB.Meta;
qc = NeuroQC.Analyzer(epochData, epochMeta, 500);

% 5. 运行评估
% 5.1 坏试次检测 (使用自适应标准差方法)
% 阈值设为 5 倍标准差 (Robust Sigma)，能自动适应不同 Session 的噪声水平
qc.detect_bad_trials('Method', 'std', 'Threshold', 5);

% 5.2 通道相关性检查 (找出断路或异常通道)
qc.check_channel_correlation('Threshold', 0.1);

% 6. 可视化报告
fprintf('正在生成图表...\n');

% 图1: 试次幅值分布
qc.plot_amplitude_dist();

% 图2: 通道相关性矩阵
qc.plot_correlation_matrix();

% 图3: 按条件 (PicID) 绘制 PSTH (仅使用好试次)
% 假设 PicID 存在于 Meta 中
if ismember('PicID', epochMeta.Properties.VariableNames)
    qc.plot_psth_by_condition('PicID', 'Smooth', 5);
    
    % 图4: 绘制 Tuning Curve (朝向选择性)
    % 假设 PicID 代表角度，我们统计 [50, 200] ms 时间窗内的平均响应
    qc.plot_tuning_curve('GroupCol', 'PicID', 'Window', [50, 200]);
else
    warning('MetaTable 中没有 PicID 列，跳过 PSTH 绘制。');
end

fprintf('演示完成。\n');
