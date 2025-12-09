function migrate_metadata_to_excel()
    % 1. 设置路径
    % 请修改为你存放 SessionIdx.mat 的文件夹路径
    basePath_DG = 'D:\ensemble_coding\DGdata\tooldata\'; 
    basePath_QQ = 'D:\ensemble_coding\QQdata\tooldata\'; 
    % 初始化结果容器 (稍后转为 Table)
    % 我们用 Struct Array 暂存，最后一行行转
    AllEntries = struct('Subject', {}, 'DateCode', {}, 'RealDate', {}, ...
                        'Paradigm', {}, 'BlockType', {}, 'SessionID', {}, 'LogicIndex', {});
    
    %% === 处理 DG ===
    fprintf('正在处理 DG 数据...\n');
    load(fullfile(basePath_DG, 'DGSessionIdx.mat'), 'SessionIdx');
    % SessionIdx 应该是一个 Cell 矩阵
    
    [nRows, nDays] = size(SessionIdx);
    
    for d = 1:nDays
        % 1. 提取通用信息 (Row 1 & 2)
        u_code = sprintf('u%d', SessionIdx{1, d}); % Row 1: u前缀
        real_date = SessionIdx{2, d};              % Row 2: 日期 (可能是数字或字符)
        
        % 2. 遍历 Block 行 (从第3行开始到最后)
        % [CUSTOM LOGIC]: 请确认 DG 的 Block 行范围
        % 假设 Row 3=MGv, Row 4=MGnv... 你需要根据实际情况定义这些映射
        % 这里我写一个 Switch Case 供你修改
        for r = 3:nRows
            sess_nums = SessionIdx{r, d};
            if isempty(sess_nums), continue; end
            
            % 确定这一行代表什么 Block
            % [TODO]: 请修改这里的映射关系
            switch r
                case 3, blockName = 'MGv';
                case 4, blockName = 'MGnv';
                case 5, blockName = 'SG';
                case 6, blockName = 'SSGnv'; % 示例
                case 7, blockName = 'SSGv';  % 示例
                otherwise, blockName = sprintf('Unknown_Row%d', r);
            end
            
            % 遍历该 Block 下的所有 SessionID
            for s = 1:length(sess_nums)
                sid = sess_nums(s);
                
                % 计算 LogicIndex (对应旧 Meta_data 的行号)
                % [TODO]: DG 的 LogicIndex 计算逻辑比较复杂，你说它是顺序对应的
                % 这里暂时填 NaN，或者如果你知道怎么算 (比如 cumsum) 就在这里写
                % 示例：logic_idx = 计算逻辑...; 
                logic_idx = NaN; 
                
                % 添加到记录
                entry = struct();
                entry.Subject = 'DG';
                entry.DateCode = string(u_code);
                entry.RealDate = string(real_date);
                entry.Paradigm = 'B'; % [TODO]: DG 都是 B 范式吗？如果不是需判断
                entry.BlockType = blockName;
                entry.SessionID = sid;
                entry.LogicIndex = logic_idx;
                
                AllEntries(end+1) = entry;
            end
        end
    end
    
    %% === 处理 QQ ===
    fprintf('正在处理 QQ 数据...\n');
    % clear SessionIdx; % 如果变量名一样需清理
    load(fullfile(basePath_QQ, 'QQSessionIdx.mat'), 'SessionIdx'); % 假设文件名
    [nRows, nDays] = size(SessionIdx);
    
    for d = 1:nDays
        % 1. 提取通用信息
        u_code = SessionIdx{1, d}; % QQ Row 1 (可能是字符?)
        real_date = SessionIdx{2, d}; % QQ Row 2
        
        % QQ 特有: Row 3 是 meta_date
        meta_date_key = SessionIdx{3, d};
        
        % 2. 遍历“三行一组”的结构
        % [CUSTOM LOGIC]: QQ 从第 4 行开始，每 3 行是一组?
        % Row 4: Paradigm A/B? Row 5: MetaIndex? Row 6: SessionID?
        
        currentRow = 4;
        while currentRow <= nRows
            % 检查是否越界
            if currentRow + 2 > nRows, break; end
            
            % 获取这三行的数据
            % [TODO]: 请根据你的描述“每三行分别代表...”填空
            % 假设:
            % Line 1 (Row 4): Paradigm Name? (e.g. 'event_A')
            % Line 2 (Row 5): Meta Index (indices in meta file)
            % Line 3 (Row 6): Session File Numbers
            
            info1 = SessionIdx{currentRow, d};
            info2 = SessionIdx{currentRow+1, d};
            sess_nums = SessionIdx{currentRow+2, d};
            
            if isempty(sess_nums)
                currentRow = currentRow + 3;
                continue; 
            end
            
            % 解析范式和Block
            % [TODO]: 根据 info1 推断 Paradigm 和 Block
            paradigm = 'Unknown';
            blockName = 'Unknown';
            if contains(string(info1), 'A'), paradigm = 'A'; end
            if contains(string(info1), 'B'), paradigm = 'B'; end
            
            for s = 1:length(sess_nums)
                sid = sess_nums(s);
                
                % QQ 的 LogicIndex
                % 这里的 info2 似乎就是 meta 里的索引？
                if s <= length(info2)
                    l_idx = info2(s);
                else
                    l_idx = NaN;
                end
                
                entry = struct();
                entry.Subject = 'QQ';
                entry.DateCode = string(u_code);
                entry.RealDate = string(real_date);
                entry.Paradigm = paradigm;
                entry.BlockType = blockName; % 需要你补充
                entry.SessionID = sid;
                entry.LogicIndex = l_idx;
                
                AllEntries(end+1) = entry;
            end
            
            % 移动到下一组
            currentRow = currentRow + 3;
        end
    end
    
    %% === 输出 Excel ===
    if isempty(AllEntries)
        warning('没有提取到任何数据，请检查路径或逻辑。');
        return;
    end
    
    T = struct2table(AllEntries);
    
    % 排序：Subject -> RealDate -> SessionID
    T = sortrows(T, {'Subject', 'RealDate', 'SessionID'});
    
    outFile = fullfile(basePath_DG, 'Neuro_Experiment_Log.xlsx');
    writetable(T, outFile);
    fprintf('Excel 已生成: %s\n', outFile);
    fprintf('请务必打开 Excel 手动检查并填补 Unknown 的部分！\n');
end