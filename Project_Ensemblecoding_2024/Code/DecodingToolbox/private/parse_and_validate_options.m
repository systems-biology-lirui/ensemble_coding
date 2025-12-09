function config = parse_and_validate_options(data_train, data_test, user_options)
% PARSE_AND_VALIDATE_OPTIONS - 解析输入选项，设置默认值，并验证参数。
%
% 描述:
%   此函数作为内部辅助函数，被 Master_Decoder 调用。它的主要职责是：
%   1. 检查必需的选项 (如 .mode) 是否已提供。
%   2. 为可选的选项 (如 .n_shuffles) 提供合理的默认值。
%   3. 基于数据维度和所选模式，验证参数的有效性。
%   4. 将所有配置整合到一个干净的 'config' 结构体中返回。
%
%   这样做可以将繁琐的参数处理逻辑与核心的解码算法分离。

% --- 1. 初始化一个默认配置结构体 ---
config = struct();

% 解码模式 (必需参数)
if isfield(user_options, 'mode')
    valid_modes = {'temporal', 'gat', 'cross_condition', 'cross_gat'};
    if ~ismember(user_options.mode, valid_modes)
        error('Invalid mode specified. Options are: %s.', strjoin(valid_modes, ', '));
    end
    config.mode = user_options.mode;
else
    error('Decoding mode must be specified in options.mode.');
end

% --- 2. 为可选参数设置默认值 ---

% K-Fold 交叉验证折数
if isfield(user_options, 'k_fold')
    config.k_fold = user_options.k_fold;
else
    config.k_fold = 3; % 默认值
end

% 真实准确率的重复计算次数
if isfield(user_options, 'n_repetitions')
    config.n_repetitions = user_options.n_repetitions;
else
    config.n_repetitions = 5; % 默认值
end

% 时间平滑窗口半径
if isfield(user_options, 'time_smooth_win')
    config.time_smooth_win = user_options.time_smooth_win;
else
    config.time_smooth_win = 1; % 默认值
end

% 置换检验相关参数
if isfield(user_options, 'do_permutation') && user_options.do_permutation
    config.do_permutation = true;
    if isfield(user_options, 'n_shuffles')
        config.n_shuffles = user_options.n_shuffles;
    else
        config.n_shuffles = 5; % 默认置换次数
    end
else
    config.do_permutation = false;
    config.n_shuffles = 0;
end

% --- 3. 验证模式与数据输入的匹配性 ---

% 获取训练数据维度
[config.n_cluster, config.n_repeat_train, config.n_coil, config.n_time] = size(data_train);
config.num_samples_train = config.n_cluster * config.n_repeat_train;

% 检查 'cross_condition' 模式
if strcmp(config.mode, 'cross_condition') || strcmp(config.mode, 'cross_gat')
    if isempty(data_test)
        error('For ''%s'' mode, a second dataset (decodingdata_test) must be provided.', config.mode);
    end
    % 验证测试数据维度的一致性
    [n_cluster_test, ~, n_coil_test, n_time_test] = size(data_test);
    if n_cluster_test ~= config.n_cluster || n_coil_test ~= config.n_coil || n_time_test ~= config.n_time
        error('Train and test data dimensions (n_cluster, n_coil, n_time) must match.');
    end
else
    % 对于 'temporal' 和 'gat' 模式，确保 test data 为空
    if ~isempty(data_test)
        warning('For ''%s'' mode, decodingdata_test is ignored. Set it to [] to suppress this warning.', config.mode);
    end
end

% --- 4. 最终检查和信息输出 ---
if config.k_fold < 2
    error('k_fold must be at least 2.');
end
if config.do_permutation && config.n_shuffles < 1
    error('n_shuffles must be at least 1 when do_permutation is true.');
end

rng('default'); % 保证结果可复现性

fprintf('Configuration validated successfully.\n');

end