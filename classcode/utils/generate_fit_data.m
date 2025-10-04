function [fit_result, fit_stats] = generate_fit_data(base_data_struct, main_data_struct, fit_label, method)
% GENERATE_FIT_DATA - 使用基线数据(SSG)拟合或组合生成主数据(MG)。
%
% 语法:
%   fit_result = generate_fit_data(base_data_struct, main_data_struct, fit_label)
%   fit_result = generate_fit_data(..., method)
%
% 输入:
%   base_data_struct - 基线数据结构体数组 (例如 SSGnv 或 SSGv)
%   main_data_struct - 要被拟合的主数据结构体数组 (例如 MGnv 或 MGv)
%   fit_label        - 用于标记结果的字符串 (例如 'fitMGnv' 或function [fit_result, fit_stats] = generate_fit_data(base_data_struct, main_data_struct, fit_label, method) 'fitMGv')
%   method           - (可选) 指定计算方法的字符串:
%                      'linear'     (默认) - 对12个位置进行完整线性回归。
%                      'sum'        - 直接将12个位置的信号相加。
%                      'scaled_sum' - 对12个位置信号的和进行增益和偏移拟合。
%
% 输出:
%   fit_result       - 包含拟合结果的结构体数组。
%                      字段: Block, Target_Ori, Pattern, Pic_Ori, Data
%   fit_stats        - (可选) 包含拟合优度统计信息的结构体数组。
%                      字段: Target_Ori, R2, R2_adj, RMSE

% --- 1. 参数处理和初始化 ---
if nargin < 4
    method = 'linear'; % 如果未提供method参数，则默认为'linear'
end
% 验证method参数是否合法
valid_methods = {'linear', 'sum', 'scaled_sum'};
method = validatestring(method, valid_methods, mfilename, 'method');

condition = -1:2:17;
num_conditions = length(condition);
num_locations = 12;

% 假设从第一个数据点获取通道和时间点信息
[~, num_channels, num_timepoints] = size(main_data_struct(find(~cellfun(@isempty, {main_data_struct.Data}), 1)).Data);

all_base_locs = [base_data_struct.Location];
all_base_oris = [base_data_struct.Target_Ori];
fit_result(1:num_conditions) = struct('Block', [], 'Target_Ori', [], 'Pattern', [], 'Pic_Ori', [], 'Data', []);
fit_stats(1:num_conditions) = struct('Target_Ori', [], 'R2', [], 'R2_adj', [], 'RMSE', []);

% --- 2. 核心处理循环 ---
for i = 1:num_conditions
    % 填充基本信息
    fit_result(i).Block = fit_label;
    fit_result(i).Target_Ori = condition(i);
    
    if i > length(main_data_struct) || isempty(main_data_struct(i).Data)
        continue;
    end
    
    % --- 向量化提取 SSG 数据 (所有方法共用) ---
    condition_indices = find(all_base_oris == condition(i));
    condition_indices =  condition_indices(1:12);
    [~, sort_order] = sort(all_base_locs(condition_indices));
    sorted_indices = condition_indices(sort_order);
    % base_condition_data 维度: [location, trial, channel, time]
    base_condition_data = permute(cat(4, base_data_struct(sorted_indices).Data), [4, 1, 2, 3]);
    
    fit_result(i).Pattern = main_data_struct(i).Pattern;
    fit_result(i).Pic_Ori = main_data_struct(i).Pic_Ori;
    
    % --- 3. 根据所选方法执行计算 ---
    switch method
        case 'linear'
            % --- 方法1: 12个位置的完整线性回归 (原始方法) ---
            main_data_mean = squeeze(mean(main_data_struct(i).Data, 1));
            w = zeros(num_channels, num_locations + 1);
            
            R2 = zeros(num_channels, 1);
            R2_adj = zeros(num_channels, 1);
            RMSE = zeros(num_channels, 1);
            
            n_obs = num_timepoints; 
            n_preds = num_locations;
            
            for channel = 1:num_channels
                predictors = squeeze(mean(base_condition_data(:, :, channel, :), 2))';
                design_matrix = [ones(num_timepoints, 1), predictors];
                target_vector = main_data_mean(channel, :)';
                w(channel, :) = design_matrix \ target_vector;

                % **新增**: 计算拟合优度
                predicted_vector = design_matrix * w(channel, :)';
                residuals = target_vector - predicted_vector;
                
                SSR = sum(residuals.^2); % 残差平方和
                SST = sum((target_vector - mean(target_vector)).^2); % 总平方和
                
                R2(channel) = 1 - (SSR / SST);
                R2_adj(channel) = 1 - ( (1 - R2(channel)) * (n_obs - 1) / (n_obs - n_preds - 1) );
                RMSE(channel) = sqrt(mean(residuals.^2));
            end
            
            bias_fit = w(:, 1);
            weights_fit = w(:, 2:end);
            
            data_to_fit = permute(double(base_condition_data), [2, 4, 3, 1]);
            weights_reshaped = reshape(weights_fit, [1, 1, num_channels, num_locations]);
            weighted_sum = sum(data_to_fit .* weights_reshaped, 4);
            
            bias_reshaped = reshape(bias_fit, [1, 1, num_channels]);
            reconstructed_data = weighted_sum + bias_reshaped;
            
            fit_result(i).Data = int16(permute(reconstructed_data, [1, 3, 2]));

            % 将统计指标存入 fit_stats 结构体
            fit_stats(i).R2 = R2;
            fit_stats(i).R2_adj = R2_adj;
            fit_stats(i).RMSE = RMSE;

        case 'sum'
            % --- 方法2: 直接将12个位置的信号相加 ---
            % 沿 location 维度(dim 1)求和
            % squeeze 将 [1, trial, channel, time] 变为 [trial, channel, time]
            summed_data = squeeze(sum(double(base_condition_data), 1));
            fit_result(i).Data = int16(summed_data);
            
        case 'scaled_sum'
            % --- 方法3: 对12个位置的和进行增益(gain)和偏移(offset)拟合 ---
            % 步骤 A: 计算用于拟合的预测变量 (trial平均后的信号和)
            main_data_mean = squeeze(mean(main_data_struct(i).Data, 1)); % [channel, time]
            % 先在location维度求和，再在trial维度求平均
            summed_base_mean = squeeze(mean(sum(double(base_condition_data), 1), 2)); % [channel, time]
            
            w_scaled = zeros(num_channels, 2); % 每行存储 [offset, gain]
            
            R2 = zeros(num_channels, 1);
            R2_adj = zeros(num_channels, 1);
            RMSE = zeros(num_channels, 1);
            
            n_obs = num_timepoints; % 观测数量 (n)
            n_preds = 1; % 预测变量数量 (p), 只有一个: summed_base_mean
            for channel = 1:num_channels
                predictor = summed_base_mean(channel, :)'; % [time, 1]
                design_matrix = [ones(num_timepoints, 1), predictor];
                target_vector = main_data_mean(channel, :)';
                w_scaled(channel, :) = design_matrix \ target_vector;

                % **新增**: 计算拟合优度
                predicted_vector = design_matrix * w_scaled(channel, :)';
                residuals = target_vector - predicted_vector;
                
                SSR = sum(residuals.^2); % 残差平方和
                SST = sum((target_vector - mean(target_vector)).^2); % 总平方和

                R2(channel) = 1 - (SSR / SST);
                R2_adj(channel) = 1 - ( (1 - R2(channel)) * (n_obs - 1) / (n_obs - n_preds - 1) );
                RMSE(channel) = sqrt(mean(residuals.^2));
            end
            
            % 步骤 B: 使用拟合出的 gain 和 offset 重建数据
            offset = w_scaled(:, 1); % [channel, 1]
            gain = w_scaled(:, 2);   % [channel, 1]
            
            % 获取所有 trial 的信号和，用于重建
            summed_data_all_trials = squeeze(sum(double(base_condition_data), 1)); % [trial, channel, time]
            
            % 使用广播机制进行计算: y = gain * x + offset
            % 重塑 gain 和 offset 以匹配广播维度
            gain_reshaped = reshape(gain, [1, num_channels, 1]);
            offset_reshaped = reshape(offset, [1, num_channels, 1]);
            
            reconstructed_data = summed_data_all_trials .* gain_reshaped + offset_reshaped;
            fit_result(i).Data = int16(reconstructed_data);

            % 将统计指标存入 fit_stats 结构体
            fit_stats(i).R2 = R2;
            fit_stats(i).R2_adj = R2_adj;
            fit_stats(i).RMSE = RMSE;
    end
end

end