ssgnv_data = {};
for m = 1:13
    ssgnv_data{m}  = [];
end
for i = 1:2
    for trial = 1:length(final_sessions{1,i})
        idx = [final_sessions{1,i}(trial).location];
        if ~isempty(idx)
            ssgnv_data{idx} = cat(2,ssgnv_data{idx},final_sessions{1,i}(trial).pic_idx([1, 14, 27, 40]));
        end
    end
end

for i = 1:13
    a = min(ssgnv_data{i});
    b = max(ssgnv_data{i});
    c = b-a;
    disp(c);
end
%% 生成均衡的phase


% generatePhaseSequence 根据输入的数字序列生成对应的相位序列。
%
% 输入:
%   digital_sequence: 一个行向量或列向量，其中每个元素是 1 到 18 的整数。
%
% 输出:
%   phase_sequence: 与输入等长的相位序列，每个元素是 1 到 6 的整数。
digital_sequence = m(1,:);
    % --- 1. 前提条件检查 ---
    fprintf('--- 检查前提条件 ---\n');
    % 使用 groupcounts 统计每个数字的出现次数 (需要 R2020b 或更高版本)
    % 如果您的 MATLAB 版本较低，可以使用 tabulate 或 histcounts
    [counts, numbers] = groupcounts(digital_sequence(:)); % 使用(:)确保是列向量
    
    % 创建一个包含所有数字1-18的完整统计表
    full_counts = zeros(18, 1);
    full_counts(numbers) = counts;
    
    all_conditions_met = true;
    for num = 1:18
        if full_counts(num) > 0 && full_counts(num) < 6
            fprintf('警告: 数字 %d 在序列中只出现了 %d 次，无法满足分配6种相位的要求。\n', num, full_counts(num));
            all_conditions_met = false;
        end
    end
    
    if all_conditions_met
        fprintf('所有出现过的数字，其次数都 >= 6 (或为0)，满足条件。\n');
    end
    fprintf('---------------------\n\n');

    % --- 2. 初始化 ---
    sequence_length = length(digital_sequence);
    phase_sequence = zeros(size(digital_sequence)); % 创建与输入同尺寸的零矩阵
    
    % 计数器数组，索引 1-18 对应数字 1-18
    % 记录每个数字已经出现过的次数
    occurrence_counts = zeros(1, 18); 
    
    phases = 1:6; % 定义6种相位

    % --- 3. 遍历数字序列并生成相位 ---
    for i = 1:sequence_length
        % 获取当前数字
        current_num = digital_sequence(i);
        
        % 获取该数字已经出现过的次数（从0开始计数）
        current_count = occurrence_counts(current_num);
        
        % 使用取模运算来循环选择相位
        % mod(0, 6) -> 0, 我们需要相位1
        % mod(5, 6) -> 5, 我们需要相位6
        % mod(6, 6) -> 0, 我们需要相位1
        % 所以索引是 mod(current_count, 6)，然后加1
        phase_index = mod(current_count, 6) + 1;
        assigned_phase = phases(phase_index);
        
        % 将生成的相位赋值给输出序列的对应位置
        phase_sequence(i) = assigned_phase;
        
        % 更新该数字的出现次数计数器
        occurrence_counts(current_num) = occurrence_counts(current_num) + 1;
    end
%%
for ori =1:18
    idx = find(m(1,:)==ori);
    phase_d= phase_sequence(idx);
    subplot(3,6,ori)
    histogram(phase_d)
end
%%
%上一步得到的phase还不够随机，会使得target序列中的target位置都是相同的图片
% 对每个朝向下的相位排序进行随机化
% clear;
% load('D:\Ensemble coding\QQdata\tooldata\Exp1Btrial0915.mat')
% m = [random,target10,target90];

for ori = 1:18
    idx = find(m(1,:)==ori);
    phase = [];
    phase = m(3,idx);
    phase = phase(randperm(length(phase)));
    phase = phase(randperm(length(phase)));
    phase = phase(randperm(length(phase)));
    m(3,idx) = phase;
end
random = m(:,1:72);
target10 =m(:,73:144);
target90 = m(:,145:216);


random(2,:)  = 5508+(random(1,:)-1)*18+(random(3,:)-1)*3+1;
target10(2,:)  = 5508+(target10(1,:)-1)*18+(target10(3,:)-1)*3+1;
target90(2,:)  = 5508+(target90(1,:)-1)*18+(target90(3,:)-1)*3+1;
save('D://Ensemble coding//QQdata//tooldata//Exp1Btrial0915_1.mat','target10','target90','random');