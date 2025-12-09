function reconstruct_dg_meta()
    %% === 1. 配置与加载 (Configuration) ===
    clear; clc;
    basePath = 'D:\ensemble_coding\DGdata\tooldata\'; 
    
    % 定义文件名
    file_sess = 'DGSessionIdx.mat';
    file_ssvep = 'DG_metadata_SSVEP1.mat';
    file_event = 'DG_metadata_EVENT.mat'; % [请确认文件名]
    
    % 加载 SessionIdx
    fprintf('加载 SessionIdx...\n');
    tmp = load(fullfile(basePath, file_sess)); 
    SessionIdx = tmp.SessionIdx;
    
    % 加载 SSVEP Meta
    fprintf('加载 SSVEP Meta...\n');
    tmp = load(fullfile(basePath, file_ssvep));
    Meta_SSVEP = tmp.Meta_data;
    
    % 加载 EVENT Meta (如果文件存在)
    path_event = fullfile(basePath, file_event);
    if exist(path_event, 'file')
        fprintf('加载 EVENT Meta...\n');
        tmp = load(path_event);
        % [请确认变量名] 假设也是 Meta_data，如果不是请修改
        Meta_EVENT = tmp.Meta_data; 
    else
        warning('未找到 EVENT 文件: %s，将只处理 SSVEP。', path_event);
        Meta_EVENT = {};
    end
    
    %% === 2. 定义 Block 映射 (Block Mapping) ===
    % 你的 SessionIdx 里的行号对应什么 Block？
    BlockMap = containers.Map('KeyType','double','ValueType','char');
    BlockMap(3) = 'MGv';
    BlockMap(4) = 'MGnv';
    BlockMap(5) = 'SG';
    BlockMap(6) = 'SSGnv';
    BlockMap(7) = 'SSGv';
    BlockMap(8) = 'Unknown'; 
    
    % 拼接顺序: 无论哪一天，都按这个顺序扫描
    processRowOrder = 3:7; 
    
    %% === 3. 核心处理循环 ===
    NewMetaStruct = struct('DateCode', {}, 'SessionID', {}, 'FileName', {}, ...
                           'Block', {}, 'Paradigm', {}, 'Content', {});
                       
    [nRows, nDays] = size(SessionIdx);
    
    for d = 1:nDays
        % --- A. 获取当天的 uCode ---
        u_num = SessionIdx{1, d};
        if isempty(u_num), continue; end
        u_code = sprintf('u%d', u_num);
        
        % --- B. 构建 "文件篮子" (从 SessionIdx 提取) ---
        DaySessionIDs = [];
        DayBlockTypes = {};
        
        for r = processRowOrder
            if r > size(SessionIdx, 1), continue; end
            s_nums = SessionIdx{r, d};
            
            if ~isempty(s_nums)
                DaySessionIDs = [DaySessionIDs, s_nums]; %#ok<*AGROW>
                blkName = 'Unknown';
                if isKey(BlockMap, r), blkName = BlockMap(r); end
                for k = 1:length(s_nums), DayBlockTypes{end+1} = blkName; end
            end
        end
        
        % 如果这一天 SessionIdx 里全是空的，直接跳过
        if isempty(DaySessionIDs), continue; end
        
        
        % --- C. 三源查找 (Look up in 3 places) ---
        % 我们需要确定这一天属于哪个范式，并找到对应的 Meta 行
        
        match_indices = [];
        use_meta_source = {}; % 指向 Meta_SSVEP 或 Meta_EVENT
        content_col = 0;
        current_paradigm = '';
        
        % 1. 查 SSVEP_A (Col 3)
        mask_A = strcmp(Meta_SSVEP(:, 3), u_code);
        idx_A = find(mask_A);
        
        % 2. 查 SSVEP_B (Col 7)
        if size(Meta_SSVEP, 2) >= 7
            mask_B = strcmp(Meta_SSVEP(:, 7), u_code);
            idx_B = find(mask_B);
        else
            idx_B = [];
        end
        
        % 3. 查 EVENT (假设 uCode 在 Col 3, 数据在 Col 1 - [请按需修改])
        idx_E = [];
        if ~isempty(Meta_EVENT)
            % [配置] EVENT Meta 的 uCode 在第几列？假设是 3
            if size(Meta_EVENT, 2) >= 3
                mask_E = strcmp(Meta_EVENT(:, 3), u_code);
                idx_E = find(mask_E);
            end
        end
        
        % --- D. 决策与冲突处理 ---
        if ~isempty(idx_A)
            current_paradigm = 'SSVEP_A';
            match_indices = idx_A;
            use_meta_source = Meta_SSVEP;
            content_col = 1; % SSVEP_A 数据列
            
        elseif ~isempty(idx_B)
            current_paradigm = 'SSVEP_B';
            match_indices = idx_B;
            use_meta_source = Meta_SSVEP;
            content_col = 5; % SSVEP_B 数据列
            
        elseif ~isempty(idx_E)
            current_paradigm = 'EVENT';
            match_indices = idx_E;
            use_meta_source = Meta_EVENT;
            content_col = 1; % [配置] EVENT 数据列
            
        else
            warning('天数 %s 有文件记录，但在 SSVEP(A/B) 或 EVENT Meta 中均未找到 uCode。跳过。', u_code);
            continue;
        end
        
        
        % --- E. 对齐校验 ---
        n_files = length(DaySessionIDs);
        n_meta_rows = length(match_indices);
        
        if n_files ~= n_meta_rows
            warning('天数 %s (%s) 对齐失败！SessionIdx文件数=%d, Meta行数=%d。跳过。', ...
                u_code, current_paradigm, n_files, n_meta_rows);
            continue;
        end
        
        % --- F. 写入结果 ---
        for i = 1:n_files
            sessID = DaySessionIDs(i);
            
            % 获取内容
            row_idx = match_indices(i);
            contentData = use_meta_source{row_idx, content_col};
            
            entry.DateCode = u_code;
            entry.SessionID = sessID;
            entry.FileName = sprintf('DG2-%s-%03d-500hz.mat', u_code, sessID);
            entry.Block = DayBlockTypes{i};
            entry.Paradigm = current_paradigm; % 新增列
            entry.Content = contentData;
            
            NewMetaStruct(end+1) = entry;
        end
    end
    
    %% === 4. 排序与保存 ===
    if isempty(NewMetaStruct)
        warning('没有生成任何数据，请检查路径或 uCode 匹配。');
        return;
    end
    
    fprintf('正在排序并生成 Table...\n');
    MetaTable = struct2table(NewMetaStruct);
    
    % 排序：DateCode -> SessionID
    MetaTable = sortrows(MetaTable, {'DateCode', 'SessionID'});
    
    % 预览
    disp('预览前 15 行:');
    disp(MetaTable(1:min(15,height(MetaTable)), {'DateCode', 'SessionID', 'Block', 'Paradigm'}));
    
    savePath = fullfile(basePath, 'DG_Master_Meta_Table.mat');
    save(savePath, 'MetaTable');
    fprintf('处理完成！已保存至: %s\n', savePath);
end