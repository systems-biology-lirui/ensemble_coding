% Example
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

% ------------------------------------------------------------------------
% ------------------------------------------------------------------------

% results
% .acc_real_mean 
%       交叉验证平均之后的随时间点变化的正确率，根据mode不同会得到向量或者矩阵
% .p_value
%       随时间点变化的解码正确率与shuffle之后chance-level的t检验
% .perm_accuracies_mean
%       在shuffle交叉验证平均之后的随时间点变化的chance-level
% .detailed
%       每个时间点，每次重复得到的正确率和chance-level
% .linear_weight
%       解码器都是采用 one vs one策略，即18分类解码器会对所有两种分类进行一一辨别
%       每个时间点下所有二分类辨别的通道权重，如示例中是一个18*18的cell矩阵，只需要采用下三角内容；
% .config
%       之前的参数

clear;clc;

options.mode = 'temporal';          % mode{'temporal','gat','cross_condition','cross_gat'}
options.do_permutation = true;      % 是否进行shuffle的chance-level计算(true/false)
options.n_shuffles = 5;             % shuffle次数
options.n_repetitions = 5;          % 解码重复次数
options.k_fold = 3;                 % 解码交叉验证
options.time_smooth_win = 0;        % 时间点的窗口平滑

% 一些建议：
% 1.在进行跨时间点的decoding的时候，不建议进行时间点平滑

load('sel_channel_Yge.mat','sel_channel')
load('exampledata.mat','mgv','sg');

data1 = mgv(:,:,sel_channel.DG,:);
data2 = sg(:,:,sel_channel.DG,:);

clearvars -except data1 data2 options 

% [cluster,repeat,channel,timepoint] = size(data);
results = Master_Decoder(data1, [], options);


