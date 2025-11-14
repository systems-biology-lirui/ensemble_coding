function results = Master_Decoder(decodingdata_train, decodingdata_test, options)
% MASTER_DECODER - 模块化的MVPA解码主函数
%
% 语法:
%   results = Master_Decoder(decodingdata_train, decodingdata_test, options)
%
% 描述:
%   此函数作为解码工具箱的统一入口，支持多种解码模式：
%   1. 'temporal':  标准逐时间点解码 (训练和测试在同一时间点)。
%   2. 'gat':       跨时间泛化 (GAT) 解码 (在一个时间点训练，在所有时间点测试)。
%   3. 'cross_condition': 跨条件/数据集解码 (在一个数据集上训练，在另一个上测试)。
%
%   函数通过一个 'options' 结构体来接收所有配置，并通过调用私有函数
%   来执行具体的解码任务，使得主逻辑清晰且易于扩展。
%
% 输入:
%   decodingdata_train: 训练数据集。
%                       维度: [n_cluster, n_repeat_train, n_coil, n_time]
%
%   decodingdata_test:  测试数据集。
%                       - 对于 'cross_condition' 模式，这是第二个数据集。
%                         维度: [n_cluster, n_repeat_test, n_coil, n_time]
%                       - 对于 'temporal' 和 'gat' 模式，此参数应设为 []。
%
%   options:            一个包含所有设置的结构体 (struct)。
%                       - .mode: 解码模式 ('temporal', 'gat', 'cross_condition')
%                       - .do_permutation: 是否执行置换检验 (true/false)
%                       - .n_shuffles: 置换次数
%                       - .n_repetitions: 真实准确率的重复计算次数
%                       - .k_fold: K-Fold交叉验证的折数
%                       - .time_smooth_win: 时间平滑窗口的半径 (例如, 1 表示 [-1, 0, 1])
%
% 输出:
%   results:            一个结构体，包含所选模式下的所有解码结果。
%                       其具体字段会根据 'options.mode' 的不同而变化。
%
% 示例调用:
%   % 模式1: 标准时间点解码
%   options_temporal.mode = 'temporal';
%   options_temporal.do_permutation = true;
%   results_t = Master_Decoder(myData, [], options_temporal);
%
%   % 模式2: GAT
%   options_gat.mode = 'gat';
%   results_gat = Master_Decoder(myData, [], options_gat);
%
%   % 模式3: 跨条件
%   options_cross.mode = 'cross_condition';
%   results_c = Master_Decoder(data_A, data_B, options_cross);
%
%   % 模式4：跨时间点跨条件 
%   options_cross.mode = 'cross_gat';
%   results_c = Master_Decoder(data_A, data_B, options_cross);

% --- 1. 解析和验证输入 ---
% 我们将所有复杂的参数处理逻辑都封装到这个私有函数中

config = parse_and_validate_options(decodingdata_train, decodingdata_test, options);

% --- 2. 基于解码模式，分派任务 ---
fprintf('Starting decoding with mode: %s\n', config.mode);
tic;

switch config.mode
    case 'temporal'
        % 调用专门处理逐时间点解码的函数
        results = run_decoding_temporal(decodingdata_train, config);
        
    case 'gat'
        % 调用专门处理GAT解码的函数
        results = run_decoding_gat(decodingdata_train, config);
        
    case 'cross_condition'
        % 调用专门处理跨条件解码的函数
        results = run_decoding_cross_condition(decodingdata_train, decodingdata_test, config);

    case 'cross_gat'
        % 调用专门处理跨条件GAT解码的函数
        results = run_decoding_cross_gat(decodingdata_train, decodingdata_test, config);

    otherwise
        error('Invalid decoding mode specified. Use ''temporal'', ''gat'', or ''cross_condition''.');
end

toc;
fprintf('----------------------------------------\n');
fprintf('Decoding finished successfully.\n');

end