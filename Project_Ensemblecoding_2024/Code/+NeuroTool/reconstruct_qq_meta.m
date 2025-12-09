function reconstruct_qq_meta()
    %% === 1. 配置与加载 ===
    clear; clc;
    basePath = 'D:\ensemble_coding\QQdata\tooldata\'; 
    
    file_sess = 'QQSessionIdx.mat';
    file_meta_ssvep = 'QQ_metadata_SSVEP.mat'; 
    file_meta_event = 'QQ_metadata_EVENT.mat'; % [确认文件名]
    
    fprintf('加载 SessionIdx...\n');
    tmp = load(fullfile(basePath, file_sess)); 
    SessionIdx = tmp.SessionIdx;
    
    fprintf('加载 SSVEP Meta...\n');
    tmp = load(fullfile(basePath, file_meta_ssvep));
    Meta_SSVEP = tmp.Meta_data;
    
    % 加载 EVENT Meta
    path_event = fullfile(basePath, file_meta_event);
    if exist(path_event, 'file')
        fprintf('加载 EVENT Meta...\n');
        tmp = load(path_event);
        Meta_EVENT = tmp.Meta_data; % [确认变量名]
    else
        warning('未找到 EVENT 文件: %s，将忽略 EVENT 数据。', path_event);
        Meta_EVENT = {};
    end
    
    %% === 2. 核心处理循环 ===
    NewMetaStruct = struct('DateCode', {}, 'SessionID', {}, 'FileName', {}, ...
                           'Block', {}, 'Paradigm', {}, 'Content', {});
                       
    [nRows, nDays] = size(SessionIdx);
    
    for d = 1:nDays
        % --- A. 提取通用头信息 ---
        u_code = SessionIdx{1, d}; 
        if isempty(u_code), continue; end
        
        meta_date_key = SessionIdx{3, d}; 
        if isnumeric(meta_date_key), meta_date_key = num2str(meta_date_key); end
        
        % --- B. 遍历 "三行一组" 的结构 ---
        currentRow = 4;
        
        while currentRow <= nRows
            if currentRow + 2 > nRows, break; end
            
            % 1. 提取这三行
            para_name = string(SessionIdx{currentRow, d}); 
            meta_idxs = SessionIdx{currentRow+1, d};   
            file_nums = SessionIdx{currentRow+2, d};   
            
            if isempty(file_nums)
                currentRow = currentRow + 3;
                continue;
            end
            
            % === [逻辑分支 1] 决定去哪个 Meta 文件找？ ===
            % 并且决定去哪一列找 (Col Mapping)
            
            Use_Meta_Source = {}; % 目标容器
            col_date_match = 0;   % 日期匹配列
            col_content = 0;      % 数据提取列
            
            % 1. 忽略 EVENT_B
            if contains(para_name, 'EVENT_B', 'IgnoreCase', true)
                currentRow = currentRow + 3;
                continue; 
            end
            
            % 2. 分流逻辑
            if contains(para_name, 'SSVEP', 'IgnoreCase', true)
                % --- SSVEP 处理 ---
                Use_Meta_Source = Meta_SSVEP;
                
                if contains(para_name, 'B', 'IgnoreCase', true)
                    % SSVEP_B -> 右边
                    col_date_match = 6;
                    col_content = 5;
                else
                    % SSVEP_A -> 左边
                    col_date_match = 2;
                    col_content = 1;
                end
                
            elseif contains(para_name, 'EVENT', 'IgnoreCase', true)
                % --- EVENT 处理 ---
                if isempty(Meta_EVENT)
                    warning('遇到 EVENT 数据但未加载到 Meta 文件。跳过。');
                    currentRow = currentRow + 3;
                    continue;
                end
                Use_Meta_Source = Meta_EVENT;
                
                % EVENT (A) 通常遵循 A 范式的布局 (左边)
                % 假设 EVENT 的日期在 Col 2，数据在 Col 1
                col_date_match = 2; 
                col_content = 1;
                
            else
                warning('未知的范式名称: %s', para_name);
                currentRow = currentRow + 3;
                continue;
            end
            
            
            % === [修复点] 鲁棒的字符串转换 (解决 Element 241 报错) ===
            % 提取目标 Meta 的日期列
            raw_dates = Use_Meta_Source(:, col_date_match);
            
            str_dates = strings(size(raw_dates)); 
            for i = 1:length(raw_dates)
                val = raw_dates{i};
                if isempty(val)
                    str_dates(i) = ""; 
                elseif isnumeric(val)
                    str_dates(i) = string(val); 
                elseif ischar(val) || isstring(val)
                    str_dates(i) = string(val); 
                else
                    str_dates(i) = "INVALID"; 
                end
            end
            
            % 3. 查找匹配行
            subset_indices = find(str_dates == string(meta_date_key));
            
            if isempty(subset_indices)
                % 只有当不是空数据时才报警，避免满屏无效警告
                warning('日期 %s (%s) 在 Meta 列 %d 中未找到匹配行！', meta_date_key, para_name, col_date_match);
                currentRow = currentRow + 3;
                continue;
            end
            
            % 4. 遍历文件列表进行配对
            n_files = length(file_nums);
            n_metas = length(meta_idxs);
            
            if n_files ~= n_metas
                warning('天数 %s (%s) 长度不匹配: Files=%d, MetaIdx=%d', u_code, para_name, n_files, n_metas);
                loop_len = min(n_files, n_metas);
            else
                loop_len = n_files;
            end
            
            for k = 1:loop_len
                sessID = file_nums(k);     
                rel_idx = meta_idxs(k);    
                
                if rel_idx > length(subset_indices)
                    warning('Meta索引越界: 天数%s (%s) 试图取第 %d 个，但该日期只有 %d 行。', ...
                        u_code, para_name, rel_idx, length(subset_indices));
                    continue;
                end
                
                abs_row = subset_indices(rel_idx);

                % 提取内容
                contentData = Use_Meta_Source{abs_row, col_content};

                blkName = "Unknown";
                if isstruct(contentData) && isfield(contentData, 'Block')
                    % 提取当前 Session 下所有 Trial 的 Block 字段
                    all_blks = {contentData.Block};

                    % 去重 (例如全是 'SSGnv'，这就变成一个)
                    % 如果混合了 'MGv' 和 'SG'，这里会得到两个
                    unique_blks = unique(string(all_blks));

                    % 拼接成字符串 (如 "SSGnv" 或 "MGv,SG")
                    if ~isempty(unique_blks)
                        blkName = strjoin(unique_blks, ',');
                    end
                end

                % 存入
                entry.DateCode = u_code;
                entry.SessionID = sessID;
                entry.FileName = sprintf('QQ2-%s-%03d-500hz.mat', u_code, sessID);
                entry.Paradigm = char(para_name);
                entry.Block = blkName; 
                entry.Content = contentData;


                NewMetaStruct(end+1) = entry;
            end
            
            currentRow = currentRow + 3;
        end
    end
    
    %% === 3. 排序与保存 ===
    if isempty(NewMetaStruct)
        warning('未生成数据，请检查路径。');
        return;
    end
    
    fprintf('正在生成 Table...\n');
    MetaTable = struct2table(NewMetaStruct);
    
    % 排序
    % MetaTable = sortrows(MetaTable, {'Paradigm', 'DateCode', 'SessionID'});
    % MetaTable = movevars(MetaTable, 'Paradigm', 'After', 'SessionID');
    idx_to_fix = strcmpi(MetaTable.Paradigm, 'EVENT_A') | strcmpi(MetaTable.Paradigm, 'Event_A');
    if any(idx_to_fix)
        MetaTable.Paradigm(idx_to_fix) = {'EVENT'};
        fprintf('已将 %d 个 "EVENT_A" 重命名为 "EVENT"。\n', sum(idx_to_fix));
    end
    % 预览
    disp('预览前 15 行:');
    disp(MetaTable(1:min(15,height(MetaTable)), {'DateCode', 'SessionID', 'Paradigm', 'FileName'}));

    savePath = fullfile(basePath, 'QQ_Master_Meta_Table.mat');
    save(savePath, 'MetaTable');
    fprintf('QQ 处理完成！已保存至: %s\n', savePath);
end