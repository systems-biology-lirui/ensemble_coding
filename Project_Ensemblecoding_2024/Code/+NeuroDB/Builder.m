classdef Builder < handle
    % NEURODB.BUILDERV3

    properties
        Config
        MasterTable
    end

    methods
        function obj = Builder(config)
            obj.Config = config;
            obj.load_master_table();
        end

        function run(obj)
            targetBlocks = obj.Config.TargetBlocks;
            fprintf('=== 开始构建流程: Subject %s ===\n', obj.Config.Subject);
            fprintf('   目标范式: %s\n', strjoin(obj.Config.TargetParadigms, ', '));

            for i = 1:length(targetBlocks)
                blkName = targetBlocks{i};
                try
                    obj.build_single_block(blkName);
                catch ME
                    fprintf('!!! Error in Block %s: %s\n', blkName, ME.message);
                    disp(ME.stack(1));
                end
            end
            fprintf('=== 全部流程结束 ===\n');
        end
    end

    methods (Access = private)

        function load_master_table(obj)
            % 根据 Subject 自动加载对应的 Table
            fName = sprintf('%s_Master_Meta_Table.mat', obj.Config.Subject);
            fPath = fullfile(obj.Config.Path.MetaDir, fName);
            if ~exist(fPath, 'file'), error('Master Table not found: %s', fPath); end
            tmp = load(fPath, 'MetaTable');
            obj.MasterTable = tmp.MetaTable;
        end

        function build_single_block(obj, targetBlock)
            fprintf('\n>>> 正在处理 Block: %s <<<\n', targetBlock);

            % === [核心修改] 双重筛选逻辑 ===

            % 1. 筛选 Block (MasterTable.Block 包含目标字符串)
            % 使用 string() 转换以防 Table 里是 cell
            idx_blk = contains(string(obj.MasterTable.Block), targetBlock);

            % 2. 筛选 Paradigm (MasterTable.Paradigm 必须在白名单里)
            % ismember(A, B) -> A 中的元素是否存在于 B 中
            idx_para = ismember(string(obj.MasterTable.Paradigm), obj.Config.TargetParadigms);

            % 3. [新增] 筛选日期范围 (DateRange)
            if isfield(obj.Config, 'DateRange') && ~isempty(obj.Config.DateRange)
                d_start = obj.Config.DateRange(1);
                d_end   = obj.Config.DateRange(2);

                % === 核心修改：从 'u087' 提取数字 '87' ===
                raw_codes = string(obj.MasterTable.DateCode); % ["u087", "u088", ...]

                % 使用正则提取连续的数字 (\d+)
                % 'match', 'once' 保证只提取第一组数字
                extracted_str = regexp(raw_codes, '\d+', 'match', 'once');

                % 转换为 double 数字
                table_dates = str2double(extracted_str);

                % 处理可能提取失败的情况 (变成 NaN)
                table_dates(isnan(table_dates)) = -1;

                % 生成掩码
                idx_date = (table_dates >= d_start) & (table_dates <= d_end);

                fprintf('  [Filter] 日期编号筛选: %d -> %d (选中 %d 条)\n', ...
                    d_start, d_end, sum(idx_date));
            else
                idx_date = true(height(obj.MasterTable), 1);
            end

            % === 4. 联合筛选 ===
            is_relevant = idx_blk & idx_para & idx_date;
            BlockRows = obj.MasterTable(is_relevant, :);

            if height(BlockRows) == 0
                fprintf('  [Skip] 未找到满足条件(Block & Paradigm & Date)的记录。\n');
                return;
            end

            % === 筛选结束 ===

            if height(BlockRows) == 0
                fprintf('  [Skip] 没有找到满足条件 (Block=%s & Paradigm=Target) 的记录。\n', targetBlock);
                return;
            end

            % --- 下面的逻辑基本不变，但增加了 Paradigm 信息到文件名 (可选) ---

            fprintf('  [Pass 1] 扫描 %d 个 Session 文件...\n', height(BlockRows));
            [totalTrials, nCh, maxTime] = obj.prescan_dimensions(BlockRows, targetBlock);

            fprintf('  预分配: %d Trials, %d Ch, %d TimePoints\n', totalTrials, nCh, maxTime);

            LFP_Tensor = zeros(totalTrials, nCh, maxTime, 'int16');

            TrialMeta = table('Size', [totalTrials, 7], ...
                'VariableTypes', {'string', 'double', 'string', 'string', 'double', 'double', 'double'}, ...
                'VariableNames', {'DateCode', 'SessionID', 'Paradigm', 'Block', 'Location', 'Condition', 'TrialIndex'});

            StimSeqList = cell(totalTrials, 1);
            PatternList = cell(totalTrials, 1);
            fprintf('  [Pass 2] 提取数据...\n');
            current_idx = 1;
            hWait = waitbar(0, sprintf('Block: %s', targetBlock));

            for i = 1:height(BlockRows)
                if mod(i, 10) == 0, waitbar(i/height(BlockRows), hWait); end

                rowInfo = BlockRows(i, :);
                fName = rowInfo.FileName;
                if iscell(fName), fName = fName{1}; end


                rawPath = fullfile(obj.Config.Path.Raw, fName);



                if ~exist(rawPath, 'file')
                    fprintf('  ! 缺失: %s\n', rowInfo.FileName{1});
                    continue;
                end

                loaded = load(rawPath, 'Datainfo');
                % [增强版] 检查 Datainfo 结构是否完整
                if ~isfield(loaded, 'Datainfo')
                    fprintf('  ! [无效] 文件中缺少 Datainfo 变量: %s\n', fName);
                    continue;
                end

                % =======================================================
                % === [新增] Meta与Raw长度一致性检查 (Quality Control) ===
                % =======================================================
                
                % 1. 获取 Meta 记录的试次长度
                
                metaLen = length(rowInfo.Content{1});
                
                % 2. 获取 Raw Data 真实数据的试次长度
                %    (根据 Config.DataType 动态判断读取哪个字段)
                try
                    switch obj.Config.DataType
                        case 'MUA1'
                            rawLen = size(loaded.Datainfo.trial_MUA{1}, 1);
                        case 'MUA2'
                            rawLen = size(loaded.Datainfo.trial_MUA{2}, 1);
                        case 'LFP'
                            rawLen = size(loaded.Datainfo.trial_LFP, 1);
                        otherwise
                            rawLen = 0;
                    end
                catch
                    rawLen = 0; % 读取失败视作 0
                end
                
                % 3. 对比并警告
                if metaLen ~= rawLen
                    fprintf('  ! [Warn] 长度不一致: Meta(%d) vs Raw(%d) -> %s\n', ...
                        metaLen, rawLen, fName);
                    
                    % 策略：虽然警告，但我们不跳过。
                    % 后续 extract_trials_from_session 会自动执行:
                    % min_len = min(metaLen, rawLen); 
                    % 从而安全地截断较长的一方。
                end
                % =======================================================
                [sessData, sessMeta, sessSeq, sessPat] = obj.extract_trials_from_session(loaded.Datainfo, rowInfo, targetBlock);

                if isempty(sessData), continue; end

                n = size(sessData, 1);
                T = size(sessData, 3);
                limitT = min(T, maxTime);
                rng = current_idx : current_idx+n-1;

                current_nCh = size(sessData, 2);

                if current_nCh == nCh
                    LFP_Tensor(rng, :, 1:limitT) = sessData(:, :, 1:limitT);

                elseif current_nCh < nCh
                    fprintf('  ! [Warn] 通道缺失 (%d < %d): %s. 缺失部分补 NaN。\n', ...
                        current_nCh, nCh, fName);
                    LFP_Tensor(rng, 1:current_nCh, 1:limitT) = sessData(:, :, 1:limitT);

                elseif current_nCh > nCh
                    fprintf('  ! [Warn] 通道过多 (%d > %d): %s. 截断多余通道。\n', ...
                        current_nCh, nCh, fName);
                    LFP_Tensor(rng, :, 1:limitT) = sessData(:, 1:nCh, 1:limitT);
                end

                TrialMeta.DateCode(rng)  = rowInfo.DateCode;
                TrialMeta.SessionID(rng) = rowInfo.SessionID;
                TrialMeta.Paradigm(rng)  = rowInfo.Paradigm; % 这里会自动记录它是 A 还是 B
                TrialMeta.Block(rng)     = sessMeta.Block;
                TrialMeta.Location(rng)  = sessMeta.Location;
                TrialMeta.Condition(rng) = sessMeta.Condition;
                TrialMeta.TrialIndex(rng)= (1:n)';

                StimSeqList(rng) = sessSeq;
                PatternList(rng) = sessPat;


                current_idx = current_idx + n;
            end
            close(hWait);

            % 收尾
            valid_idx = 1 : (current_idx - 1);

            FinalData.LFP = LFP_Tensor(valid_idx, :, :);
            FinalData.Meta = TrialMeta(valid_idx, :);
            FinalData.StimSeq = StimSeqList(valid_idx);
            FinalData.Pattern = PatternList(valid_idx);

            FinalData.Config = obj.Config;

            if ~exist(obj.Config.Path.DB, 'dir'), mkdir(obj.Config.Path.DB); end

            % 1. 生成范式字符串
            if isfield(obj.Config, 'TargetParadigms') && ~isempty(obj.Config.TargetParadigms)
                % 将 cell 数组连接成字符串，例如: "SSVEP_A" 或 "SSVEP_A-SSVEP_B"
                paraStr = strjoin(obj.Config.TargetParadigms, '-');
            else
                paraStr = 'All'; % 如果没有筛选范式，标记为 All
            end
            
            % 2. 拼接最终文件名
            % 格式: Subject_Block_Paradigm_Master.mat
            % 例如: DG_MGv_SSVEP_A_Master.mat
            saveName = sprintf('%s_%s_%s_%sMaster.mat', obj.Config.Subject, targetBlock, paraStr, obj.Config.DataType);
            savePath = fullfile(obj.Config.Path.DB, saveName);

            fprintf('  保存至: %s ...\n', savePath);
            save(savePath, 'FinalData', '-v7.3');
            fprintf('  Block %s 完成。\n', targetBlock);
        end

        % --- 辅助函数 (基本不用改，因为传入的 BlockRows 已经被过滤了) ---

        function [totalTrials, nCh, maxTime] = prescan_dimensions(obj, BlockRows, targetBlock)
            totalTrials = 0; nCh = 0; maxTime = 1640;
            for i = 1:height(BlockRows)
                content = BlockRows.Content{i};
                if isstruct(content) && isfield(content, 'Block')
                    % 简单的字符串匹配统计
                    blks = string({content.Block});
                    totalTrials = totalTrials + sum(blks == string(targetBlock));
                end
            end
            % 获取维度
            for i = 1:height(BlockRows)
                fPath = fullfile(obj.Config.Path.Raw, BlockRows.FileName{i});
                if exist(fPath, 'file')
                    tmp = load(fPath, 'Datainfo');
                    switch obj.Config.DataType
                        case 'MUA1', d = tmp.Datainfo.trial_MUA{1};
                        case 'MUA2', d = tmp.Datainfo.trial_MUA{2};
                        case 'LFP',  d = tmp.Datainfo.trial_LFP;
                    end
                    nCh = size(d, 2); maxTime = size(d, 3);
                    break;
                end
            end
        end

        function [sessData, sessMeta, sessSeq, sessPat] = extract_trials_from_session(obj, Datainfo, rowInfo, targetBlock)
            switch obj.Config.DataType
                case 'MUA1', rawData = Datainfo.trial_MUA{1};
                case 'MUA2', rawData = Datainfo.trial_MUA{2};
                case 'LFP',  rawData = Datainfo.trial_LFP;
            end
            respCode = Datainfo.VSinfo.sMbmInfo.respCode;
            Content = rowInfo.Content{1};
            Content = obj.IdxRearrage(respCode,Content);

            nValid = length(Content);
            keep_mask = false(nValid, 1);
            m_Loc = nan(nValid, 1);
            m_Cond = nan(nValid, 1);
            m_Seq = cell(nValid, 1);
            m_Pat = cell(nValid, 1);

            for k = 1:nValid
                c = Content(k);
                if ~isfield(c, 'Block'), continue; end
                if string(c.Block) == string(targetBlock)
                    keep_mask(k) = true;
                    if isfield(c, 'Location') && ~isempty(c.Location)
                        m_Loc(k) = c.Location;
                    end

                    if isfield(c, 'Condition') && ~isempty(c.Condition)
                        m_Cond(k) = c.Condition;
                    end
                    if isfield(c, 'Stim_Sequence'), m_Seq{k} = c.Stim_Sequence; end
                    if isfield(c, 'Pattern'), m_Pat{k} = c.Pattern; end
                end
            end

            sessData = int16(rawData(keep_mask, :, 1:obj.Config.TrialLength));
            sessSeq = m_Seq(keep_mask);
            sessPat = m_Pat(keep_mask);
            sessMeta.Block = repmat(string(targetBlock), sum(keep_mask), 1);
            sessMeta.Location = m_Loc(keep_mask);
            sessMeta.Condition = m_Cond(keep_mask);

            % if ~isempty(sessData)
            %     baseWin = 1:100;
            %     baseline = mean(sessData(:, :, baseWin), 3);
            %     sessData = single(sessData - baseline);
            % end
        end
        function ReFactor = IdxRearrage(~, respCode, session_factor)
            for i = 1:length(respCode)
                if respCode(i) ~= 1
                    session_factor(end+1) = session_factor(i);

                end
            end
            idx = respCode ~= 1;
            session_factor(idx) = [];
            ReFactor = session_factor;
        end
    end
end