%---------------------------提取SSVEPA中的pic（高性能预分配版）---------------------------%
function EVENT_Pic_Preallocated(file_idx, MUA_LFP,label, label2)
% 从SSVEP的trial数据中提取Pic数据（高性能预分配版）
%
% 主要优化点:
% 1. 采用“两步走”（计数-填充）策略，预先分配内存，避免在循环中使用 `cat`。
% 2. 共享核心处理逻辑，减少代码冗余。
% 3. 使用具名常量，增强可读性和可维护性。
% 4. 优化了内存使用，例如使用 'single' 精度和及时清理数据。

% --- 定义常量 ---
NUM_PICS = 1;
BASELINE_END_MS = 20;
PIC_INTERVAL_MS = 20;
WINDOW_RANGE = 1:100;
WINDOW_LENGTH = length(WINDOW_RANGE);
MAX_ORI = 18;
MAX_PATTERN = 6;
MAX_LOCATION = 13;

% --- 主循环，处理每个文件 ---
for i = 1:length(file_idx)
    
    fprintf('--> 开始处理文件 %d/%d: %s\n', i, length(file_idx), file_idx{i});
    
    % --- 1. 根据标签确定处理模式和参数 ---
    current_label = label{i};
    is_ssg_case = strcmpi(current_label, 'SSGnv') || strcmpi(current_label, 'SSGv');
    
    if is_ssg_case
        num_conds =234;
        counter_matrix = zeros(MAX_ORI, MAX_PATTERN, MAX_LOCATION);
    else
        num_conds = 18;
        counter_matrix = zeros(MAX_ORI, MAX_PATTERN);
    end
    
    data = load(file_idx{i});
    
    % --- PASS 1: 计数 ---
    % 遍历所有数据，统计每个组合(ori, pattern, [location])出现的次数
    fprintf('    - Pass 1: 正在计数...\n');
    for cond = 1:num_conds
        cond_struct = data.(current_label)(cond);
        if isempty(cond_struct.Data)
            continue;
        end
        
        num_trials = size(cond_struct.Data, 1);
        pic_ori_matrix = ones(num_trials,1)*cond_struct.Pic_Ori;
        pattern_matrix = cond_struct.Pattern;
        if isempty(pattern_matrix)
            pattern_matrix = ones(num_trials, NUM_PICS);
        end
        
        for trial = 1:num_trials
            for pic = 1:NUM_PICS
                ori = pic_ori_matrix(trial, pic);
                pattern = pattern_matrix(trial, pic);
                
                if is_ssg_case
                    location = cond_struct.Location;
                    counter_matrix(ori, pattern, location) = counter_matrix(ori, pattern, location) + 1;
                else
                    counter_matrix(ori, pattern) = counter_matrix(ori, pattern) + 1;
                end
            end
        end
    end
    
    % --- 2. 内存预分配 ---
    fprintf('    - 正在预分配内存...\n');
    EVENT_PIC_DATA = cell(size(counter_matrix));
    
    % 获取数据维度（通道数），只需一次
    num_channels = 0;
    for cond = 1:num_conds
        if ~isempty(data.(current_label)(cond).Data)
            num_channels = size(data.(current_label)(cond).Data, 2);
            break;
        end
    end
    if num_channels == 0
        fprintf('    ! 警告: 文件中无有效数据，跳过。\n');
        continue; % 跳到下一个文件
    end

    % 使用'single'精度可以节省一半内存，对于神经信号数据通常足够
    for idx = 1:numel(EVENT_PIC_DATA)
        if counter_matrix(idx) > 0
            EVENT_PIC_DATA{idx} = zeros(counter_matrix(idx), num_channels, WINDOW_LENGTH, 'int16');
        end
    end
    
    % --- PASS 2: 填充 ---
    fprintf('    - Pass 2: 正在填充数据...\n');
    fill_idx_matrix = ones(size(counter_matrix)); % 用1作为起始索引
    
    for cond = 1:num_conds
        disp(cond)
        cond_struct = data.(current_label)(cond);
        if isempty(cond_struct.Data)
            continue;
        end

        trial_data = cond_struct.Data;
        num_trials = size(trial_data,1);
        pic_ori_matrix = ones(num_trials,1)*cond_struct.Pic_Ori;
        pattern_matrix = cond_struct.Pattern;
        if isempty(pattern_matrix)
            pattern_matrix = ones(size(trial_data, 1), NUM_PICS);
        end
        
        for trial = 1:size(trial_data, 1)
            trial_baseline = mean(trial_data(trial, :, 1:BASELINE_END_MS), 3);
            
            for pic = 1:NUM_PICS

                window = 1:100;
                
                ori = pic_ori_matrix(trial, pic);
                pattern = pattern_matrix(trial, pic);
                
                current_data = trial_data(trial, :, window);
                corrected_data = int16(current_data) - int16(trial_baseline); % 确保类型一致
                
                % 填充数据
                if is_ssg_case
                    location = cond_struct.Location;
                    current_fill_idx = fill_idx_matrix(ori, pattern, location);
                    EVENT_PIC_DATA{ori, pattern, location}(current_fill_idx, :, :) = corrected_data;
                    fill_idx_matrix(ori, pattern, location) = current_fill_idx + 1;
                else
                    current_fill_idx = fill_idx_matrix(ori, pattern);
                    EVENT_PIC_DATA{ori, pattern}(current_fill_idx, :, :) = corrected_data;
                    fill_idx_matrix(ori, pattern) = current_fill_idx + 1;
                end
            end
        end
        % 及时释放内存
        data.(current_label)(cond).Data = [];
    end
    
    % --- 3. 保存结果 ---
    [~, file_name, ~] = fileparts(file_idx{i});
    output_filename = sprintf('EVENT_PIC_DATA_%s_%s_%s_%s.mat',label2, file_name(1:2), MUA_LFP, current_label);
    
    save(output_filename, 'EVENT_PIC_DATA', '-v7.3');
    fprintf('    ✔ 已完成并保存: %s\n\n', output_filename);
    
end

fprintf('*** 所有文件处理完毕 ***\n');

end