%% ------------------------------分离session------------------------------%
% SSVEP
clearvars -except Event SSVEP blocks datetoday;
% 定义参数
block_names = {'MGv', 'MGnv', 'SG', 'SSGnv'};  % 4 个 block
num_blocks = length(block_names);
num_sessions = 10;
num_blanks = 2;  % 每个 session 插入的 blank 数量

% Step 1: 处理前 3 个 block（MGv, MGnv, SG）
all_sessions = cell(num_blocks, num_sessions);

for b = 1:3  % 前 3 个 block
    block = SSVEP.(block_names{b});
    conditions = [block.condition];
    
    % 排除 condition=0 的情况
    valid_indices = find(conditions ~= 0);
    block = block(valid_indices);
    conditions = conditions(valid_indices);
    
    unique_conditions = unique(conditions);
    num_conditions = length(unique_conditions);
    
    % 记录每个 condition 的索引
    [~, ~, idx] = unique(conditions, 'stable');
    all_indices = accumarray(idx, (1:length(block))', [], @(x) {x});
    
    % 随机打乱索引顺序
    for i = 1:num_conditions
        all_indices{i} = all_indices{i}(randperm(num_sessions));
    end
    
    % 生成当前 block 的 10 个 session
    for session = 1:num_sessions
        session_indices = zeros(1, num_conditions);
        for cond = 1:num_conditions
            session_indices(cond) = all_indices{cond}(session);
        end
        all_sessions{b, session} = block(session_indices);
    end
end

% Step 2: 处理第 4 个 block（SSGnv）
block = SSVEP.SSGnv;
locations = [block.location];
conditions = [block.condition];

% 排除 condition=0 的情况
valid_indices = find(conditions ~= 0);
block = block(valid_indices);
locations = locations(valid_indices);
conditions = conditions(valid_indices);

% 生成唯一的组合键（location + condition）
combo_keys = [locations; conditions]';
[unique_combo, ~, combo_idx] = unique(combo_keys, 'rows', 'stable');
num_combos = size(unique_combo, 1);

% 检查数据合规性
assert(length(block) == num_combos * num_sessions, 'SSGnv 的交叉组合数量应为 num_combos × 10');

% 记录每个组合的索引
all_indices = accumarray(combo_idx, (1:length(block))', [], @(x) {x});

% 随机打乱索引顺序
for i = 1:num_combos
    all_indices{i} = all_indices{i}(randperm(num_sessions));
end

% 生成当前 block 的 10 个 session
for session = 1:num_sessions
    session_indices = zeros(1, num_combos);
    for combo = 1:num_combos
        session_indices(combo) = all_indices{combo}(session);
    end
    all_sessions{4, session} = block(session_indices);
end

% Step 3: 合并 4 个 block 并打乱顺序
final_sessions = cell(num_sessions, 1);
pic_idx_concatenated = cell(num_sessions, 1); 
for session = 1:num_sessions
    % 提取 4 个 block 的当前 session
    blocks_in_session = cell(1, num_blocks);
    for b = 1:num_blocks
        blocks_in_session{b} = all_sessions{b, session};
    end
    
    % 打乱 block 的顺序
    shuffled_order = randperm(num_blocks);
    shuffled_blocks = blocks_in_session(shuffled_order);
    
    % 横向拼接
    session_data = [shuffled_blocks{:}];
    
    % 插入 blank 实例
    blank_struct = struct(...
        'location', 0, ...
        'condition', 0, ...
        'stim_sequence', [], ...
        'pattern',[], ...
        'pic_idx', 5833 * ones(1, 72), ...
        'block', 'blank' ...
    );
    
    % 随机选择插入位置（不重复）
    insert_positions = randperm(length(session_data) + num_blanks, num_blanks);
    insert_positions = sort(insert_positions);
    
    % 插入 blank
    for i = 1:num_blanks
        session_data = [session_data(1:insert_positions(i)-1), blank_struct, session_data(insert_positions(i):end)];
    end
    
    final_sessions{session} = session_data;
    pic_idx_concatenated{session} = [session_data.pic_idx];
end

% 验证结果
for session = 1:num_sessions
    % 检查 blank 实例
    blank_flags = [final_sessions{session}.condition] == 0;
    assert(sum(blank_flags) == num_blanks, 'Blank 实例数量不正确');
    
    % 检查非 blank 数据的唯一性
    non_blank_data = final_sessions{session}(~blank_flags);
    for b = 1:3
        block_data = non_blank_data(strcmp({non_blank_data.block}, block_names{b}));
        conditions = [block_data.condition];
        assert(all(conditions ~= 0) && length(unique(conditions)) == length(conditions), ...
               '非 blank 数据的 condition 不唯一或包含 0');
    end
    
    % 检查 SSGnv 的交叉组合唯一性
    ssgnv_data = non_blank_data(strcmp({non_blank_data.block}, 'SSGnv'));
    combo_check = [[ssgnv_data.location]; [ssgnv_data.condition]]';
    assert(size(unique(combo_check, 'rows'), 1) == size(combo_check, 1), ...
           'SSGnv 交叉组合不唯一');
end

disp('所有验证通过！');

save(sprintf('D:\\Ensemble coding\\sti\\GSQdata_session2025%s.mat',datetoday),'final_sessions',"pic_idx_concatenated");










%% -------------------------- Event Session--------------------------------%
clearvars -except Event SSVEP blocks datetoday;
% 定义参数
block_names = {'MGv', 'MGnv', 'SG', 'SSGnv'};  % 4 个 block
num_blocks = length(block_names);
num_sessions = 6;          % Session 总数改为6
num_blanks = 4;            % 每个 session 插入的 blank 数量
session_size_per_block = 18; % 前3个block每个session包含18个实例

% Step 1: 处理前3个block (MGv, MGnv, SG)
all_sessions = cell(num_blocks, num_sessions); 

for b = 1:3  % 处理前3个block
    block = Event.(block_names{b});
    
    zero_indices = find(arrayfun(@(x) isequal(x.condition, 0), block));
    valid_indices=setdiff(1:size(block,2),zero_indices);
    block = block(valid_indices);
    
    
    % 检查数据量是否足够
    required_instances = num_sessions * session_size_per_block;
    assert(length(block) >= required_instances, ...
        'Block %s 有效实例不足，需要至少 %d 个，当前 %d 个', block_names{b}, required_instances, length(block));
    
    % 随机打乱并选择所需实例
    shuffled_indices = randperm(length(block), required_instances); 
    block = block(shuffled_indices);
    
    % 切分为6个session (每个session 18个)
    for session = 1:num_sessions
        start_idx = (session-1)*session_size_per_block + 1;
        end_idx = session*session_size_per_block;
        all_sessions{b, session} = block(start_idx:end_idx);
    end
end

% Step 2: 处理第4个block (SSGnv)
block = Event.SSGnv;
locations = [block.location];
zero_indices = find(arrayfun(@(x) isequal(x.condition, 0), block));
valid_indices=setdiff(1:size(block,2),zero_indices);

block = block(valid_indices);
locations = locations(valid_indices);

% 获取唯一location并检查数量
unique_locations = unique(locations);
num_locations = length(unique_locations); 

% 为每个location分配18×6=108个实例到6个session
for loc_idx = 1:num_locations
    loc = unique_locations(loc_idx);
    loc_indices = find(locations == loc);  % 当前location的所有实例
    
    % 随机选择108个实例
    assert(length(loc_indices) >= 108, 'Location %d 实例不足，需要108个，当前%d个', loc, length(loc_indices));
    selected_indices = loc_indices(randperm(length(loc_indices), 108));
    
    % 分配到6个session，每个session18个
    for session = 1:num_sessions
        start_idx = (session-1)*18 + 1;
        end_idx = session*18;
        session_data = block(selected_indices(start_idx:end_idx));
        all_sessions{4, session} = [all_sessions{4, session}, session_data];
    end
end

% 打乱每个session中SSGnv实例的顺序
for session = 1:num_sessions
    shuffled_indices = randperm(length(all_sessions{4, session}));
    all_sessions{4, session} = all_sessions{4, session}(shuffled_indices);
end

% Step 3: 合并block并插入blank实例
final_sessions = cell(num_sessions, 1);
pic_idx_concatenated = cell(num_sessions, 1);

for session = 1:num_sessions
    % 提取四个block的数据
    session_data = [];
    for b = 1:num_blocks
        session_data = [session_data, all_sessions{b, session}];
    end
    
    % 打乱block顺序 (例如 [SSGnv, MGv, SG, MGnv])
    block_order = randperm(num_blocks);
    shuffled_data = [];
    for b = block_order
        shuffled_data = [shuffled_data, all_sessions{b, session}];
    end
    
    % 插入4个blank实例
    blank_struct = struct(...
        'location', 0, ...
        'condition', 0, ...
        'stim_sequence', [], ...
        'pattern', [], ...
        'pic_idx', 5833 * ones(1,52), ...
        'block', 'blank' ...
    );
    
    % 随机选择插入位置（不重复）
    insert_positions = randperm(length(session_data) + num_blanks, num_blanks);
    insert_positions = sort(insert_positions);
    
    % 插入 blank
    for i = 1:num_blanks
        session_data = [session_data(1:insert_positions(i)-1), blank_struct, session_data(insert_positions(i):end)];
    end
    
    final_sessions{session} = session_data;
    pic_idx_concatenated{session} = [session_data.pic_idx];
end



% 保存数据


