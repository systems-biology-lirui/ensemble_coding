function [all_r_squared, all_weights, reconstructed_data] = trial_fitting(target_data, predictor_data, method, time_segment)
% FIT_MULTI_CHANNEL_SIGNALS - 使用多种方法将一组预测信号拟合到一个目标信号。
%
% 本函数将多个多通道时间信号（预测变量）拟合到一个多通道时间信号（目标变量）上。
% 它在每个通道上独立进行计算。
% 权重和拟合优度 (R-squared) 的计算可以限制在数据的一个特定时间段内，
% 但重建的信号 (reconstructed_data) 始终覆盖整个时间段。
%
% 语法:
%   [all_r_squared, all_weights, reconstructed_data] = trial_fitting(target_data, predictor_data, method, time_segment)
%
% 输入:
%   target_data      - 目标信号数据，维度为 [channel, time]。
%                      这是我们要拟合到的真实数据 (real_path)。
%
%   predictor_data   - 用于拟合的预测信号数据，维度为 [channel, time, predictor]。
%                      (base_path), 其中第三维代表不同的预测变量(例如，12个位置)。
%
%   method           - (可选) 指定计算方法的字符串:
%                      'linear_unconstrained' (默认) - 标准多元线性回归，包含截距项，
%                                                    权重无约束。使用高效的 '\' 求解。
%
%                      'linear_constrained'   - 线性回归，但对权重施加约束：
%                                                    1. 权重 >= 0 (非负)
%                                                    2. sum(权重) = 1
%                                                    不包含独立的截距项。使用 lsqlin 求解。
%
%                      'sum'                  - 直接将所有预测信号相加，不进行任何拟合。
%
%                      'scaled_sum'           - 先将所有预测信号相加，然后对这个“和信号”
%                                               进行增益(gain)和偏移(offset)的线性拟合。
%
%   time_segment     - (可选) 一个包含 [start_index, end_index] 的 1x2 向量，
%                      指定用于计算权重和 R-squared 的时间段（基于索引）。
%                      如果未提供或为空，则使用所有时间点进行权重计算和 R-squared 评估。
%                      请注意，reconstructed_data 始终会覆盖 target_data 的所有时间点。
%
% 输出:
%   all_r_squared    - 每个通道的拟合优度 (R-squared)，维度为 [channel, 1]。
%                      该值根据 time_segment 指定的时间段计算。
%   all_weights      - 每个通道计算出的权重，维度取决于方法。
%                      这些权重是根据 time_segment 指定的时间段计算的。
%                       - 'linear_unconstrained': [channel, n_predictors + 1] (第一列为截距)
%                       - 'linear_constrained'  : [channel, n_predictors]
%                       - 'scaled_sum'          : [channel, 2] ([offset, gain])
%                       - 'sum'                 : 返回空矩阵 []
%
%   reconstructed_data - 使用拟合模型重建出的信号，维度为 [channel, time]。
%                        此信号覆盖全部时间点，即使拟合在某个时间段内完成。

tic;

% --- 1. 参数处理和初始化 ---
if nargin < 3 || isempty(method)
    method = 'linear_unconstrained'; % 默认方法
end
% 验证method参数是否合法
valid_methods = {'linear_unconstrained', 'linear_constrained', 'sum', 'scaled_sum'};
method = validatestring(method, valid_methods, mfilename, 'method');

[n_channels, total_timepoints, n_predictors] = size(predictor_data);

% 处理 time_segment 参数
if nargin < 4 || isempty(time_segment)
    fit_start_idx = 1;
    fit_end_idx = total_timepoints;
else
    % 验证 time_segment
    if ~isvector(time_segment) || length(time_segment) ~= 2 || ...
       any(~isnumeric(time_segment)) || any(time_segment < 1) || ...
       any(time_segment > total_timepoints) || time_segment(1) > time_segment(2) || ...
       any(mod(time_segment, 1) ~= 0) % 确保是整数索引
        error('time_segment 必须是一个包含 [start_index, end_index] 的 1x2 整数向量，且在数据范围内 [1, %d]，并满足 start_index <= end_index。', total_timepoints);
    end
    fit_start_idx = time_segment(1);
    fit_end_idx = time_segment(2);
end

% 用于拟合的时间点数量
n_fit_timepoints = fit_end_idx - fit_start_idx + 1;

% 根据方法预分配内存
all_weights = []; % 默认为空，适用于 'sum' 方法
if strcmp(method, 'linear_unconstrained')
    all_weights = zeros(n_channels, n_predictors + 1);
elseif strcmp(method, 'linear_constrained')
    all_weights = zeros(n_channels, n_predictors);
elseif strcmp(method, 'scaled_sum')
    all_weights = zeros(n_channels, 2);
end

all_r_squared = zeros(n_channels, 1);
reconstructed_data = zeros(n_channels, total_timepoints); % 重建数据始终是全长度

% --- 2. 为 'linear_constrained' 方法设置约束条件 ---
% (仅在该方法被选择时使用)
if strcmp(method, 'linear_constrained')
    Aeq = ones(1, n_predictors);
    beq = 1;
    lb = zeros(n_predictors, 1);
    ub = ones(n_predictors, 1); % 权重上限为1 (可选，但通常与sum=1一同使用)
end

fprintf('开始对 %d 个通道进行拟合，使用方法: ''%s''。\n', n_channels, method);
fprintf('拟合和R-squared计算的时间段: %d 到 %d (共 %d 个时间点)。\n', fit_start_idx, fit_end_idx, n_fit_timepoints);

% --- 3. 核心处理循环 ---
for channel = 1:n_channels
    
    % 提取当前通道的 *完整* 目标信号和预测信号，以备重建全长数据
    y_full = double(target_data(channel, :))';
    X_c_full = double(squeeze(predictor_data(channel, :, :)));

    % 提取当前通道的目标信号 (因变量 y) 用于 *拟合*，并转为列向量
    y_fit = y_full(fit_start_idx:fit_end_idx);
    
    % 提取当前通道的预测信号 (自变量 X) 用于 *拟合*，维度为 [time, predictor]
    X_c_fit = X_c_full(fit_start_idx:fit_end_idx, :);
    
    weights_c = []; % 初始化当前通道的权重
    y_predicted_on_fit_segment = []; % 初始化在拟合时间段内的预测值
    y_predicted_full_data = []; % 初始化全时间段的预测值
    
    % --- 4. 根据所选方法执行计算 ---
    switch method
        case 'linear_unconstrained'
            % 标准线性回归 (等同于 fitlm 但更高效)
            design_matrix_fit = [ones(n_fit_timepoints, 1), X_c_fit]; % 添加截距列 (用于拟合)
            weights_c = design_matrix_fit \ y_fit; % 使用mldivide求解
            all_weights(channel, :) = weights_c';
            
            % 计算拟合时间段内的预测值 (用于R-squared)
            y_predicted_on_fit_segment = design_matrix_fit * weights_c;

            % 计算整个时间段的重建信号
            design_matrix_full = [ones(total_timepoints, 1), X_c_full]; % 添加截距列 (用于重建)
            y_predicted_full_data = design_matrix_full * weights_c;
            
        case 'linear_constrained'
            % 使用 lsqlin 进行带约束的线性回归
            weights_c = lsqlin(X_c_fit, y_fit, [], [], Aeq, beq, lb, ub);
            all_weights(channel, :) = weights_c';
            
            % 计算拟合时间段内的预测值 (用于R-squared)
            y_predicted_on_fit_segment = X_c_fit * weights_c;

            % 计算整个时间段的重建信号
            y_predicted_full_data = X_c_full * weights_c;

        case 'sum'
            % 直接相加，不计算权重，权重矩阵为空
            
            % 计算拟合时间段内的预测值 (用于R-squared)
            y_predicted_on_fit_segment = sum(X_c_fit, 2); % 沿 predictor 维度求和

            % 计算整个时间段的重建信号
            y_predicted_full_data = sum(X_c_full, 2);

        case 'scaled_sum'
            % 对“和信号”进行增益和偏移拟合
            summed_predictor_fit = sum(X_c_fit, 2);
            design_matrix_fit = [ones(n_fit_timepoints, 1), summed_predictor_fit];
            weights_c = design_matrix_fit \ y_fit; % weights_c = [offset; gain]
            all_weights(channel, :) = weights_c';
            
            % 计算拟合时间段内的预测值 (用于R-squared)
            y_predicted_on_fit_segment = design_matrix_fit * weights_c;

            % 计算整个时间段的重建信号
            summed_predictor_full = sum(X_c_full, 2);
            design_matrix_full = [ones(total_timepoints, 1), summed_predictor_full];
            y_predicted_full_data = design_matrix_full * weights_c;
    end
    
    % --- 5. 计算拟合优度 (R-squared) 并存储结果 ---
    % R-squared 是根据 *拟合时间段* 的数据计算的
    ss_total = sum((y_fit - mean(y_fit)).^2);
    ss_residual = sum((y_fit - y_predicted_on_fit_segment).^2);
    
    % 检查ss_total是否为0，防止除以0的错误
    if ss_total > 1e-9
        all_r_squared(channel) = 1 - (ss_residual / ss_total);
    else
        % 如果目标信号在拟合时间段内没有变异性，则无法计算R2
        all_r_squared(channel) = NaN; 
    end
    
    % 存储重建的全时间段数据
    reconstructed_data(channel, :) = y_predicted_full_data';
    
end

fprintf('所有通道拟合完成！\n');
toc;
end