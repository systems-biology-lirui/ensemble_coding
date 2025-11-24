% 删除demo中的数据模拟部分 (%% This section creates toy data.)
% 从这里开始替换为你自己的数据处理

% 假设你的数据已经加载到工作区，名为 myData
% size(myData) -> [6, 2, 100, 96, 100] (pattern, orientation, repeat, channel, time)
clear;
label = 'QQ_new';
load('sel_channel_Yge.mat','sel_channel')
load(sprintf('%s_resmgnv_Event.mat',label))
data = zeros(18,6,size(SSVEP_PIC_DATA{1,1},1),size(SSVEP_PIC_DATA{1,1},2),100);
for x = 1:18
    for y = 1:6
        data(x,y,:,:,:) = SSVEP_PIC_DATA{x,y};
    end
end
load(sprintf('%s_mgv_Event.mat',label))
data1 = zeros(size(data));
for x = 1:18
    for y = 1:6
        data1(x,y,:,:,:) = SSVEP_PIC_DATA{x,y}(1:12,:,:);
    end
end
channels = sel_channel.(label);
final_data = cat(2,data([1,9],1,:,:,:),data1([1,9],1,:,:,:));
final_data = permute(final_data,[2,1,3,4,5]);
%%
% 1. 定义你的数据参数
N = length(channels);   % number of channels
S = 2;    % number of patterns
D = 2;    % number of orientations
T = 100;  % number of time points
E = size(final_data,3);  % number of trial repetitions

% 2. 重排数据维度以匹配dPCA的要求
% 从 [real/res, ori, rep, chan, time] -> [chan, real/res, ori, time, rep]
firingRates = permute(double(final_data(:,:,:,channels,:)), [4, 1, 2, 5, 3]); 
% 现在 size(firingRates) 应该是 [96, 6, 2, 100, 100]

% 3. 创建 trialNum 和 firingRatesAverage
% 您的数据是完整的，每个条件下试验次数都相同
trialNum = repmat(E, [N, S, D]);

% 计算平均放电率
firingRatesAverage = mean(firingRates, 5); 
% size(firingRatesAverage) -> [96, 6, 2, 100]

%% -----------------------------滤波50hz,100hz----------------------------%
frequency = [50,100,150];
for m = 1:3
    [b,a] = notch_filter(500, frequency(m), 10);
    for ori = 1:S
        for pattern = 1:D
            for channel = 1:length(channels)
                firingRatesAverage(channel,ori,pattern,:)  = filtfilt(b,a,squeeze(firingRatesAverage(channel,ori,pattern,:)));
            end
        end
    end
end
for ori = 1:S
    for pattern = 1:D
        for channel = 1:length(channels)
            firingRatesAverage(channel,ori,pattern,:)  = firingRatesAverage(channel,ori,pattern,:)-squmean(firingRatesAverage(channel,ori,pattern,1:20),4);
        end
    end
end
%% Define parameter grouping
% *** 用下面的代码替换掉demo中这部分的内容 ***

% 我们的 firingRatesAverage 数组维度是 [N, S, D, T]
% 我们的参数维度是:
%    1 - realMGv/resMGnv
%    2 - orientation
%    3 - time

% Demo中提供的分组方式已经非常适合您的情况
combinedParams = {{1, [1 3]}, {2, [2 3]}, {3}, {[1 2], [1 2 3]}};

% 只需要修改 marginalization 的名字以匹配您的实验
margNames = {'real/fit', 'ori',  'Cond', 'cond/Ori Inter'};

% 颜色可以保持不变，或者自定义
margColours = [23 100 171; 187 20 25; 150 150 150; 114 97 171]/256;

% 定义时间轴和需要标记的事件（可选）
time = 1:T; % 或者您真实的时间轴
timeEvents = []; % 比如刺激开始的时间点
%%
% Step 3: dPCA without regularization
tic
[W,V,whichMarg] = dpca(firingRatesAverage, 20, 'combinedParams', combinedParams);
toc

explVar = dpca_explainedVariance(firingRatesAverage, W, V, 'combinedParams', combinedParams);

dpca_plot(firingRatesAverage, W, V, @dpca_plot_default, ...
    'explainedVar', explVar, ...
    'marginalizationNames', margNames, ...
    'marginalizationColours', margColours, ...
    'whichMarg', whichMarg,                 ...
    'time', time,                        ...
    'timeEvents', timeEvents,               ...
    'timeMarginalization', 3, ...  % <-- 确认这里是 3
    'legendSubplot', 16);