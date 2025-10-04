function SSVEP = GSQ_SSVEP_Exp1A_SSGnv(SSVEP,repeat)
% ----------------------------------------Patch0---------------------------%%


% 定义参数
num_locations = 13;
trials_per_location = 3*repeat;
num_blank = 0;
num_random = repeat;
orientations = [1,9]; % 9种整体朝向条件
trials_per_orientation = repeat;
globalOriCount = zeros(13, 18);

% 验证条件总数
assert(num_blank + num_random + length(orientations)*trials_per_orientation == trials_per_location, '条件数量不匹配');

% 生成基础条件数组（每个location使用）
condition_base = [zeros(1, num_blank), -ones(1, num_random)];
for o = orientations
    condition_base = [condition_base, repmat(o, 1, trials_per_orientation)];
end

% 预分配存储结构
total_trials(num_locations * trials_per_location) = struct('location', [], 'condition', [], 'stim_sequence', [], 'pattern', []);
index = 1;

% 生成每个location的trial
for loc = 1:num_locations
    % 打乱当前location的条件顺序
    shuffled_conditions = condition_base(randperm(trials_per_location));
    
    % 填充当前location的trial信息
    for t = 1:trials_per_location
        total_trials(index).location = loc;
        total_trials(index).condition = shuffled_conditions(t);
        index = index + 1;
    end
end

% 全局打乱所有trial顺序
total_trials = total_trials(randperm(numel(total_trials)));

% 生成每个trial的刺激序列
for i = 1:numel(total_trials)
    trial = total_trials(i);
    
    if trial.condition == 0       % Blank trial
        stim_seq = ones(72, 1) * 325;
        
    elseif trial.condition == -1  % Random trial
        orientations_random = repmat(1:18, 1, 4);
        stim_seq = orientations_random(randperm(72))';
        
    else                          % 定向trial
        ori_val = trial.condition;
        stim_seq = zeros(72, 1);
        
        % 设置固定位置
        fixed_positions = 4:4:72;
        stim_seq(fixed_positions) = ori_val;
        globalOriCount(total_trials(i).location,ori_val) = globalOriCount(total_trials(i).location,ori_val) + 18;
        % 生成随机位置
        other_positions = setdiff(1:72, fixed_positions);
        available_orientations = setdiff(1:18, ori_val);
        for pic = other_positions

            % 动态计算选择权重（当前出现次数越少权重越高）
            counts = globalOriCount(total_trials(i).location,available_orientations);
            selectionWeights = exp(-3*(counts-min(counts))); % 加1避免除零

            % 归一化权重并概率采样
            selectionWeights = selectionWeights / sum(selectionWeights);
            ori = randsample(available_orientations, 1, true, selectionWeights);

            % 更新全局计数器
            globalOriCount(total_trials(i).location,ori) = globalOriCount(total_trials(i).location,ori) + 1;

            stim_seq(pic) = ori;
        end
        
    end
    
    total_trials(i).stim_sequence = stim_seq';
end
SSVEP.SSGnv = total_trials;

% 验证
% figure;
% orientationHist = zeros(13, 18);
% 
% 
% for t = 1:286
% 
%         orientationHist(total_trials(t).location,:) = orientationHist(total_trials(t).location,:) + histcounts(total_trials(t).stim_sequence, 0.5:1:18+0.5);
% 
% 
% end
% 
% imagesc(orientationHist)