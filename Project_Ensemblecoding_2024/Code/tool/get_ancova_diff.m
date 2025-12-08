function diff_adj = get_ancova_diff(data_matrix)
% GET_ANCOVA_DIFF 基于ANCOVA逻辑修正数据并计算条件差值
%
% 输入:
%   data_matrix: 3维矩阵 [n_repeats x 2_frequencies x 2_conditions]
%       - Dim 1: Repeats (试次/重复)
%       - Dim 2: Frequency (索引1为目标Freq，索引2为协变量Freq)
%       - Dim 3: Condition (索引1为Cond1，索引2为Cond2)
%
% 输出:
%   diff_adj: [n_repeats x 1] 向量
%             代表 (Condition1_Adj - Condition2_Adj) 的结果

    %% 1. 数据解析与准备
    % 提取目标变量 (Frequency 1)
    Y_cond1 = data_matrix(:, 1, 1); 
    Y_cond2 = data_matrix(:, 1, 2);
    
    % 提取协变量 (Frequency 2)
    C_cond1 = data_matrix(:, 2, 1);
    C_cond2 = data_matrix(:, 2, 2);
    
    %% 2. 构建 GLM 模型获取"共同斜率" (Common Slope)
    % 为了准确去除协变量影响，我们需要使用所有数据来估计 Frequency 2 的效应
    
    % 拼接数据 (Long Format)
    Y_total = [Y_cond1; Y_cond2];
    C_total = [C_cond1; C_cond2];
    
    % 构建分组标签 (用于控制组间主效应)
    % 0 代表 Cond1, 1 代表 Cond2
    Group = [zeros(size(Y_cond1)); ones(size(Y_cond2))];
    
    % 使用 fitlm 拟合模型: Y ~ Group + Covariate
    % 注意：这里不包含交互项，假设斜率一致（标准ANCOVA假设）
    tbl = table(Y_total, C_total, Group, 'VariableNames', {'Y', 'C', 'Grp'});
    tbl.Grp = categorical(tbl.Grp); % 转为分类变量
    
    mdl = fitlm(tbl, 'Y ~ Grp + C');
    
    % 提取协变量的斜率 (Slope)
    % 查找名为 'C' 的系数
    slope = mdl.Coefficients.Estimate(strcmp(mdl.CoefficientNames, 'C'));
    
    %% 3. 计算修正值 (Adjusted Values)
    % 修正公式: Adj = Raw - Slope * (Covariate - GrandMean)
    % 目的：将所有数据的协变量拉平到整体均值水平
    
    grand_mean_C = mean(C_total); % 协变量的总均值
    
    % 修正 Condition 1
    Y_cond1_adj = Y_cond1 - slope * (C_cond1 - grand_mean_C);
    
    % 修正 Condition 2
    Y_cond2_adj = Y_cond2 - slope * (C_cond2 - grand_mean_C);
    
    %% 4. 计算差值并输出
    % 根据要求：Condition 1 - Condition 2
    diff_adj = Y_cond1_adj - Y_cond2_adj;

end