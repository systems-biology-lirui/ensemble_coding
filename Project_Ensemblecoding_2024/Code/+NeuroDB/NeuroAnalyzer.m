classdef NeuroAnalyzer < handle
    properties
        Subject
        BlockName
        DataPath

        % === 数据属性 ===
        RawTensor   % [nTrials, nCh, nLongTime] (int16)
        MetaTable   % Table
        StimSeq     % Cell
        Pattern     % Cell
        Config      % Struct

        % === 辅助 ===
        TimeVecLong
        TimeVecEpoch
    end

    methods
        % [Fix 1] 构造函数参数补全
        function obj = NeuroAnalyzer(subject, block, paradigmStr, dataType, dbPath)
            obj.Subject = subject;
            obj.BlockName = block;

            % [Fix 1.1] 构建正确的文件名
            % 格式参考 Builder: Subject_Block_Paradigm_DataType_Master.mat
            fName = sprintf('%s_%s_%s_%sMaster.mat', subject, block, paradigmStr, dataType);
            obj.DataPath = fullfile(dbPath, fName);

            % [Fix 1.2] 增加文件存在性检查，支持模糊搜索（可选）
            if ~exist(obj.DataPath, 'file')
                % 尝试模糊匹配 (例如如果不确定范式名)
                pattern = fullfile(dbPath, sprintf('%s_%s_*_%sMaster.mat', subject, block, dataType));
                files = dir(pattern);
                if ~isempty(files)
                    fprintf('! 未找到精确匹配，自动选择: %s\n', files(1).name);
                    obj.DataPath = fullfile(files(1).folder, files(1).name);
                else
                    error('Data file not found: %s', obj.DataPath);
                end
            end

            obj.load_data();
        end


        % ----------------------导入master数据--------------------%
        function load_data(obj)
            fprintf('加载数据库: %s ... ', obj.DataPath);
            try
                tmp = load(obj.DataPath, 'FinalData');
            catch
                error('文件加载失败，可能是路径错误或文件损坏。');
            end
            D = tmp.FinalData;

            obj.RawTensor = D.LFP;
            obj.MetaTable = D.Meta;
            obj.StimSeq   = D.StimSeq;
            obj.Pattern   = D.Pattern;

            % [Fix 2] Config 鲁棒性处理
            savedConfig = D.Config;

            % 检查当前路径下是否有 Main_Config
            if exist('Main_Config.m', 'file') || exist('Main_Config', 'file')
                try
                    currentConfig = Main_Config();
                    fprintf('[Config] 使用当前 Main_Config 更新分析参数。\n');

                    % 混合策略：保留构建时的基本信息，更新分析参数
                    obj.Config = savedConfig;

                    % 安全更新字段 (使用 isfield 检查)
                    fieldsToUpdate = {'Fs', 'StimSOA', 'StimOffset', 'StimDuration', 'EpochWin'};
                    for f = 1:length(fieldsToUpdate)
                        fn = fieldsToUpdate{f};
                        if isfield(currentConfig, fn)
                            obj.Config.(fn) = currentConfig.(fn);
                        end
                    end
                catch ME
                    fprintf('! [Warn] Main_Config 运行出错: %s。使用文件内保存的 Config。\n', ME.message);
                    obj.Config = savedConfig;
                end
            else
                fprintf('[Config] 未找到 Main_Config，使用数据文件内保存的配置。\n');
                obj.Config = savedConfig;
            end

            % 重新计算长 Trial 时间轴
            nT = size(obj.RawTensor, 3);
            obj.TimeVecLong = (0:nT-1) / obj.Config.Fs * 1000;
            fprintf('完成 (nTrials=%d)。\n', height(obj.MetaTable));
        end


        % ---------------------提取epoch--------------------------%
        function [epochData, epochMeta] = slice_epochs(obj, varargin)
            % 解析参数
            p = inputParser;
            addParameter(p, 'AverageRepeats', false, @islogical); % 新增开关
            addParameter(p, 'Verbose', true, @islogical);
            % [新增] 保存选项
            addParameter(p, 'Save', false, @islogical);
            addParameter(p, 'SaveDir', '', @ischar); % 默认为空，自动推导

            parse(p, varargin{:});

            doAvg   = p.Results.AverageRepeats;
            doSave  = p.Results.Save;
            saveDir = p.Results.SaveDir;
            verbose = p.Results.Verbose;
            if verbose, fprintf('>>> 开始切片流程 (平均模式: %d) <<<\n', doAvg); end

            % === 1. 基础参数准备 ===
            fs = obj.Config.Fs;
            soa_pts    = round(obj.Config.StimSOA / 1000 * fs);
            offset_pts = round(obj.Config.StimOffset / 1000 * fs);

            t_pre = obj.Config.EpochWin(1);
            t_post = obj.Config.EpochWin(2);
            nPre = round(abs(t_pre) / 1000 * fs);
            nPost = round(t_post / 1000 * fs);
            win_len = nPre + nPost + 1;
            obj.TimeVecEpoch = linspace(t_pre, t_post, win_len);

            [nLongTrials, nCh, maxLongTime] = size(obj.RawTensor);

            % === 2. Pass 1: 仅构建元数据索引 (极快，不占内存) ===
            if verbose, fprintf('  [Phase 1] 扫描元数据...\n'); end

            lens = cellfun(@length, obj.StimSeq);
            nEst = sum(lens);

            % [修改点 1] 增加 DateCode 存储数组
            % DateCode 通常是 string 或 double。为了 findgroups 效率，建议转为 double (如果可能)
            % 或者使用 categorical/string 数组。这里假设是 string。
            temp_DateCode = strings(nEst, 1);
            temp_Session  = zeros(nEst, 1, 'double');
            temp_Loc      = zeros(nEst, 1, 'int16');
            temp_PicID    = zeros(nEst, 1, 'int16');
            temp_Pattern  = zeros(nEst, 1, 'int16');
            temp_SourceTrial = zeros(nEst, 1, 'int32');
            temp_OnsetIdx    = zeros(nEst, 1, 'int32');

            global_cnt = 0;

            for i = 1:nLongTrials
                seq = obj.StimSeq{i};
                if isempty(seq), continue; end

                % [修改点 2] 获取 DateCode
                cur_date = obj.MetaTable.DateCode(i);
                % 确保统一为 string，防止有些是 cell 有些是 char
                if iscell(cur_date), cur_date = string(cur_date{1}); else, cur_date = string(cur_date); end

                cur_sess = obj.MetaTable.SessionID(i);
                cur_loc  = obj.MetaTable.Location(i);
                if iscell(cur_loc), cur_loc = -1; end

                if i <= length(obj.Pattern), pat = obj.Pattern{i}; else, pat = []; end
                if iscell(pat), try pat=[pat{:}]; catch, pat=zeros(size(seq)); end; end
                if ~isnumeric(pat), pat=zeros(size(seq)); end

                min_len = min(length(seq), length(pat));
                seq = seq(1:min_len);
                pat = pat(1:min_len);

                for k = 1:length(seq)
                    onset_idx = offset_pts + (k-1)*soa_pts;
                    idx_start = onset_idx - nPre;
                    idx_end   = idx_start + win_len - 1;

                    if idx_start < 1 || idx_end > maxLongTime, continue; end

                    global_cnt = global_cnt + 1;

                    % 填充
                    temp_DateCode(global_cnt) = cur_date; % 记录日期
                    temp_Session(global_cnt)  = cur_sess;
                    temp_Loc(global_cnt)      = cur_loc;
                    temp_PicID(global_cnt)    = seq(k);
                    temp_Pattern(global_cnt)  = pat(k);

                    temp_SourceTrial(global_cnt) = i;
                    temp_OnsetIdx(global_cnt)    = idx_start;
                end
            end

            % 截断
            valid_idx = 1:global_cnt;
            temp_DateCode = temp_DateCode(valid_idx); % 截断日期
            temp_Session  = temp_Session(valid_idx);
            temp_Loc      = temp_Loc(valid_idx);
            temp_PicID    = temp_PicID(valid_idx);
            temp_Pattern  = temp_Pattern(valid_idx);
            temp_SourceTrial = temp_SourceTrial(valid_idx);
            temp_OnsetIdx    = temp_OnsetIdx(valid_idx);

            fprintf('  [Phase 1] 扫描完成: %d 个 Epochs。\n', global_cnt);

            % === 3. 确定分组策略 ===
            if doAvg
                if verbose, fprintf('  [Strategy] 平均模式 (Group by Date-Session-Loc-Pic-Pat)...\n'); end

                % [修改点 3] 将 DateCode 加入 findgroups
                % 只有 DateCode, Session, Location, PicID, Pattern 全部相同的才会被归为一组
                [G, tbl_Date, tbl_Sess, tbl_Loc, tbl_Pic, tbl_Pat] = ...
                    findgroups(temp_DateCode, temp_Session, temp_Loc, temp_PicID, temp_Pattern);

                nGroups = max(G);
                fprintf('  [Info] 数据压缩: %d -> %d (压缩率 %.1f%%)\n', ...
                    global_cnt, nGroups, (1-nGroups/global_cnt)*100);

                % 预分配累加器
                try
                    Accumulator = zeros(nGroups, nCh, win_len, 'single');
                    Counts      = zeros(nGroups, 1, 'single');
                catch ME
                    error('内存不足 (合并后仍过大): %s', ME.message);
                end

                target_indices = G;
                final_N = nGroups;

            else
                % ... (原始模式代码不变，记得检查内存) ...
                req_mem_gb = global_cnt * nCh * win_len * 2 / 1024^3;
                if req_mem_gb > 16
                    error('内存超限 (%.1f GB)。必须开启 AverageRepeats=true。', req_mem_gb);
                end
                Accumulator = zeros(global_cnt, nCh, win_len, 'int16');
                target_indices = (1:global_cnt)';
            end

            % === 4. Pass 2: 提取并累加 (Batch Processing) ===
            if verbose, fprintf('  [Phase 2] 提取并处理数据...\n'); end

            % 为了提高 IO 效率，我们按 SourceTrial 也就是 RawTensor 的行来遍历
            % 找出哪些 Epoch 属于同一个 RawTensor 行，一次性切出来

            % 进度条
            unique_trials = unique(temp_SourceTrial);
            nBlocks = length(unique_trials);
            hWait = waitbar(0, 'Processing Epochs...');

            for b = 1:nBlocks
                if mod(b, 50) == 0, waitbar(b/nBlocks, hWait); end

                uTrialIdx = unique_trials(b);

                % 找出所有属于当前长 Trial 的 Epoch 索引 (在 temp 列表中的位置)
                current_mask = (temp_SourceTrial == uTrialIdx);

                % 对应的参数
                these_onsets = temp_OnsetIdx(current_mask);
                these_targets = target_indices(current_mask); % 它们应该去 Accumulator 的哪一行

                if isempty(these_onsets), continue; end

                % 读取整条长 Trial 数据 (int16 -> single 以便计算)
                % [1, nCh, nTime]
                long_data = obj.RawTensor(uTrialIdx, :, :);

                % 循环切片 (内存内操作，极快)
                for k = 1:length(these_onsets)
                    idx_s = these_onsets(k);
                    idx_e = idx_s + win_len - 1;

                    % 切片 [1, nCh, win_len]
                    % squeeze 可能会导致维度丢失，如果 nCh=1，要注意
                    chunk = single(long_data(1, :, idx_s:idx_e));

                    dest_row = these_targets(k);

                    if doAvg
                        % 累加模式
                        Accumulator(dest_row, :, :) = Accumulator(dest_row, :, :) + chunk;
                        Counts(dest_row) = Counts(dest_row) + 1;
                    else
                        % 直接填充模式 (转回 int16 省空间)
                        Accumulator(dest_row, :, :) = int16(chunk);
                    end
                end
            end
            close(hWait);

            % === 5. 后处理 (平均计算) ===
            if doAvg
                epochData = Accumulator ./ Counts;

                % [修改点 4] 输出表中包含 DateCode
                epochMeta = table(tbl_Date, tbl_Sess, tbl_Loc, tbl_Pic, tbl_Pat, Counts, ...
                    'VariableNames', {'DateCode', 'SessionID', 'Location', 'PicID', 'Pattern', 'AvgCount'});
            else
                epochData = Accumulator;
                epochMeta = table(temp_DateCode, temp_Session, temp_Loc, temp_PicID, temp_Pattern, temp_SourceTrial, ...
                    'VariableNames', {'DateCode', 'SessionID', 'Location', 'PicID', 'Pattern', 'OriginTrialIdx'});
            end
            if strcmp(obj.Config.TargetParadigms{1},'EVENT')
                epochData = epochData - squmean(epochData(:,:,1:20),3);
            end

            if verbose, fprintf('=== 完成 ===\n'); end

            if doSave
                if verbose, fprintf('  [Save] 正在保存切片数据...\n'); end
                obj.save_epoch_dataset(epochData, epochMeta, doAvg, saveDir);
            end
        end


        % ---------------------保存图片---------------------------%
        function save_epoch_dataset(obj, data, meta, isAveraged, targetDir)
            % SAVE_EPOCH_DATASET 保存切片后的数据
            % data: 切片数据矩阵
            % meta: 元数据 Table
            % isAveraged: 逻辑值，文件名会据此标记为 'Avg' 或 'Raw'
            % targetDir: (可选) 目标文件夹

            % 1. 确定保存目录
            if nargin < 5 || isempty(targetDir)
                % 自动推导: 假设当前数据在 .../Data/01_Database/
                % 我们想存到 .../Data/02_EpochDatabase/

                % 获取 DataPath 的上上级目录 (即 Data 文件夹)
                [parentDir, ~, ~] = fileparts(fileparts(obj.DataPath));
                baseDir = fullfile(parentDir, '02_EpochDatabase');
            else
                baseDir = targetDir;
            end

            if ~exist(baseDir, 'dir')
                mkdir(baseDir);
                fprintf('  [Info] 创建文件夹: %s\n', baseDir);
            end

            % 2. 构建文件名
            % 格式: Subject_Block_Paradigm_DataType_Epochs_Avg.mat
            % 从文件名或 Config 中提取必要信息

            % 尝试从 DataPath 提取文件名主体
            [~, rawName, ~] = fileparts(obj.DataPath);
            % rawName 类似于: QQ_MGv_SSVEP_B_MUA2Master

            % 去掉结尾的 "Master" (如果有)
            coreName = erase(rawName, 'Master');

            % 添加后缀
            if isAveraged
                suffix = 'Epochs_Avg';
            else
                suffix = 'Epochs_Raw';
            end

            saveName = sprintf('%s_%s.mat', coreName, suffix);
            savePath = fullfile(baseDir, saveName);

            % 3. 打包数据结构
            EpochDB.Data = data;
            EpochDB.Meta = meta;
            EpochDB.Config = obj.Config; % 重要！保存当时的切片配置
            EpochDB.IsAveraged = isAveraged;
            EpochDB.Timestamp = datetime('now');

            % 4. 保存
            fprintf('  [IO] 保存至: %s ... ', savePath);
            try
                % 使用 -v7.3 以支持大于 2GB 的文件
                save(savePath, 'EpochDB', '-v7.3');
                fprintf('成功。\n');
            catch ME
                fprintf('失败!\n!!! Error: %s\n', ME.message);
            end
        end


        % ------------------------数据裁剪-------------------------%
        function subset_sessions(obj, nKeep)
            % SUBSET_SESSIONS 只保留前 nKeep 个 Session 的数据，裁剪 RawTensor
            % nKeep: 要保留的 Session 数量 (例如 61)

            fprintf('>>>正在裁剪数据: 保留前 %d 个 Session <<<\n', nKeep);

            % 1. 识别唯一的 Session (组合 DateCode 和 SessionID)
            %    因为 SessionID 每天可能重置 (Day1: 1-10, Day2: 1-10)
            meta = obj.MetaTable;
            if iscell(meta.DateCode), dc = string(meta.DateCode); else, dc = meta.DateCode; end

            % findgroups 会自动按出现的顺序或者排序编号
            % 为了确保是按时间顺序保留，我们假设 MasterTable 已经是按时间排序的
            % 直接用 findgroups 即可生成唯一的 Group ID (1, 2, 3...)
            [G, ~] = findgroups(dc, meta.SessionID);

            totalSessions = max(G);
            if nKeep >= totalSessions
                fprintf('  [Info] 请求数量 (%d) >= 总数量 (%d)，无需裁剪。\n', nKeep, totalSessions);
                return;
            end

            % 2. 生成保留掩码 (Keep Mask)
            % 保留所有 GroupID <= nKeep 的 Trial
            keep_mask = (G <= nKeep);

            nTrialsBefore = height(meta);
            nTrialsAfter  = sum(keep_mask);

            % 3. 执行裁剪 (覆盖自身属性)
            fprintf('  [执行] 正在裁剪 RawTensor...\n');
            obj.RawTensor = obj.RawTensor(keep_mask, :, :);

            fprintf('  [执行] 正在裁剪元数据...\n');
            obj.MetaTable = obj.MetaTable(keep_mask, :);

            % 这里的 StimSeq 和 Pattern 是 Cell 数组，也要对应裁剪
            if ~isempty(obj.StimSeq)
                obj.StimSeq = obj.StimSeq(keep_mask);
            end
            if ~isempty(obj.Pattern)
                obj.Pattern = obj.Pattern(keep_mask);
            end

            % 4. 强制垃圾回收 (释放被切掉的内存)
            % Java 垃圾回收在 MATLAB 中不一定立即生效，但调用一下有好处
            java.lang.System.gc();

            fprintf('  [完成] 数据已缩减: %d Trials -> %d Trials (保留了 %d/%d Sessions)\n', ...
                nTrialsBefore, nTrialsAfter, nKeep, totalSessions);
        end

        % ----------------------条件提取---------------------------%
        function subset_data(obj, varargin)
            % SUBSET_DATA 通用数据筛选器
            % 使用 Name-Value 对进行联合筛选 (逻辑 AND)
            %
            % 示例:
            %   obj.subset_data('Condition', [1, 9]);
            %   obj.subset_data('Location', 1, 'SessionID', 1:10);
            %   obj.subset_data('Condition', -1, 'DateCode', 'u087');

            % 1. 解析输入参数
            p = inputParser;
            % 定义支持的筛选字段，默认值为空(即不筛选)
            addParameter(p, 'Condition', []);
            addParameter(p, 'Location', []);
            addParameter(p, 'SessionID', []);
            addParameter(p, 'DateCode', []); % 支持 string, char 或 cell

            % [功能合并] 顺便把保留前N个Session的功能也加进来
            addParameter(p, 'MaxSessions', []);

            parse(p, varargin{:});
            args = p.Results;

            fprintf('>>> 开始执行数据筛选/裁剪 ...\n');

            % 初始掩码：全部选中
            nTrials = height(obj.MetaTable);
            keep_mask = true(nTrials, 1);

            % 2. 逐个应用筛选条件 (逻辑 AND)

            % --- 筛选 Condition ---
            if ~isempty(args.Condition)
                fprintf('  [Filter] Condition: %s\n', mat2str(args.Condition));
                keep_mask = keep_mask & ismember(obj.MetaTable.Condition, args.Condition);
            end

            % --- 筛选 Location ---
            if ~isempty(args.Location)
                fprintf('  [Filter] Location: %s\n', mat2str(args.Location));
                keep_mask = keep_mask & ismember(obj.MetaTable.Location, args.Location);
            end

            % --- 筛选 SessionID ---
            if ~isempty(args.SessionID)
                fprintf('  [Filter] SessionID: %s\n', mat2str(args.SessionID));
                keep_mask = keep_mask & ismember(obj.MetaTable.SessionID, args.SessionID);
            end

            % --- 筛选 DateCode ---
            if ~isempty(args.DateCode)
                % 统一格式处理，防止 MetaTable 里是 cell 而输入是 string
                targetDates = string(args.DateCode);
                currentDates = obj.MetaTable.DateCode;
                if iscell(currentDates), currentDates = string(currentDates); end

                fprintf('  [Filter] DateCode: %s\n', strjoin(targetDates, ', '));
                keep_mask = keep_mask & ismember(currentDates, targetDates);
            end

            % --- 筛选 MaxSessions (保留前 N 个) ---
            % 这个逻辑比较特殊，要在上述筛选的基础上，再按时间顺序截断
            if ~isempty(args.MaxSessions)
                nKeep = args.MaxSessions;
                fprintf('  [Filter] 仅保留前 %d 个 Session\n', nKeep);

                % 获取当前的 Date-Session 组合
                meta = obj.MetaTable;
                if iscell(meta.DateCode), dc = string(meta.DateCode); else, dc = meta.DateCode; end

                % 计算全局 Session 序号
                [G, ~] = findgroups(dc, meta.SessionID);

                % 生成 Session 掩码
                sess_mask = (G <= nKeep);

                % 与现有掩码合并
                keep_mask = keep_mask & sess_mask;
            end

            % 3. 执行裁剪
            nTrialsAfter = sum(keep_mask);

            if nTrialsAfter == 0
                warning('  [Warn] 筛选条件过于严格，结果为空！未执行任何操作。');
                return;
            end

            if nTrialsAfter == nTrials
                fprintf('  [Info] 数据未发生变化 (符合所有条件)。\n');
                return;
            end

            fprintf('  [执行] 裁剪数据: %d -> %d Trials (保留 %.1f%%)\n', ...
                nTrials, nTrialsAfter, (nTrialsAfter/nTrials)*100);

            obj.RawTensor = obj.RawTensor(keep_mask, :, :);
            obj.MetaTable = obj.MetaTable(keep_mask, :);

            if ~isempty(obj.StimSeq), obj.StimSeq = obj.StimSeq(keep_mask); end
            if ~isempty(obj.Pattern), obj.Pattern = obj.Pattern(keep_mask); end

            % 4. 内存回收
            java.lang.System.gc();
            fprintf('  [完成] 筛选结束。\n');
        end


        % ---------------------频谱分析策略------------------------%
        function [psdResult, freqVec, extraInfo] = analyze_spectrum(obj, varargin)
            % 参数解析
            p = inputParser;
            % Method 选项:
            % 'Default' (Evoked): 按 Session 分组 -> 时域信号平均 -> FFT (您的要求)
            % 'Trial-PSD-Avg' (Induced): 每个 Trial 单独 FFT -> 然后平均 PSD
            % 'Global-Signal-Avg': 忽略 Session，对所有同 Condition 的信号全局平均 -> FFT
            addParameter(p, 'Method', 'Default');
            addParameter(p, 'ComputeSNR', false);
            addParameter(p, 'RemoveDC', true);
            parse(p, varargin{:});

            method = p.Results.Method;
            calcSNR = p.Results.ComputeSNR;
            rmDC = p.Results.RemoveDC;

            fs = obj.Config.Fs;
            [~, nCh, nT] = size(obj.RawTensor);

            fprintf('>>> 频谱分析 (Long Trial) | 模式: %s | 去直流: %d <<<\n', method, rmDC);

            % === 第一步：根据模式准备数据 (聚合与平均) ===

            meta = obj.MetaTable;
            % 处理 DateCode 格式
            if iscell(meta.DateCode), d_code = string(meta.DateCode); else, d_code = meta.DateCode; end

            switch method
                case 'Default'
                    % 策略：按 Date, Session, Condition 分组 (忽略 Location)
                    fprintf('  [Step 1] 分组并在时域平均信号 (Session Level, Ignore Location)...\n');

                    % [关键修改] findgroups 中移除了 meta.Location
                    % 现在的分组键只有：Date, Session, Condition
                    [G, t_date, t_sess, t_cond] = findgroups(...
                        d_code, meta.SessionID, meta.Condition);

                    nGroups = max(G);

                    % 2. 执行时域平均 (和之前一样)
                    processed_signal = zeros(nGroups, nCh, 1600, 'single');

                    % 为了显示进度，这里如果 nGroups 很大可以加 waitbar
                    % 但因为 Location 合并了，nGroups 会变得很小 (Session数 * Condition数)
                    % 所以直接循环即可，速度极快
                    for i = 1:nGroups
                        idx = (G == i);
                        processed_signal(i, :, :) = mean(single(obj.RawTensor(idx, :, 41:1640)), 1);
                    end

                    % 3. 构建元数据表
                    % 注意：结果中不再包含 Location 列，因为它已经被平均掉了
                    resultMeta = table(t_date, t_sess, t_cond, ...
                        'VariableNames', {'DateCode', 'SessionID', 'Condition'});

                    % 如果你想保留 Location 信息，可以加一列 'All' 或 'Mixed'
                    % resultMeta.Location = repmat("Mixed", height(resultMeta), 1);

                case 'Global-Signal-Avg'
                    % 策略：Same Loc, Cond (Ignore Session) -> Signal Avg -> FFT
                    fprintf('  [Step 1] 全局时域平均 (Condition Level)...\n');

                    [G, t_loc, t_cond] = findgroups(meta.Location, meta.Condition);
                    nGroups = max(G);

                    processed_signal = zeros(nGroups, nCh, nT, 'single');
                    for i = 1:nGroups
                        processed_signal(i, :, :) = mean(single(obj.RawTensor(G==i, :, 41:1640)), 1);
                    end

                    resultMeta = table(t_loc, t_cond, 'VariableNames', {'Location', 'Condition'});

                case 'Trial-PSD-Avg'
                    % 策略：不进行时域平均，直接使用原始 Trial
                    % 注意：这种模式下，是先算 FFT 再平均 PSD，所以这里 processed_signal 就是原始数据
                    fprintf('  [Step 1] 保持原始 Trials (用于先 FFT 后平均)...\n');

                    % 显式转为 single，防止 int16 溢出
                    processed_signal = single(obj.RawTensor(:,:,41:1640));

                    % 元数据保持不变
                    resultMeta = meta;

                otherwise
                    error('未知模式: %s', method);
            end

            % === 第二步：频谱计算 (FFT) ===
            fprintf('  [Step 2] 计算功率谱 (FFT)...\n');

            % 去直流 (对时域信号)
            if rmDC
                % 对 Time 维度 (dim 3) 求均值并减去
                processed_signal = processed_signal - mean(processed_signal, 3);
            end

            % 调用 NeuroAlgo 工具计算 PSD
            % 输入: [Batch, Ch, Time], 输出: [Batch, Ch, Freq]
            [psd_data, freqVec] = NeuroAlgo.compute_psd_simple(processed_signal, fs);

            % === 第三步：后续聚合 (仅针对 Trial-PSD-Avg 模式) ===
            if strcmp(method, 'Trial-PSD-Avg')
                fprintf('  [Step 3] 对 PSD 结果进行平均聚合...\n');

                % 这里同样按 Date, Sess, Loc, Cond 聚合，但是是对 PSD 聚合
                [G, t_date, t_sess, t_loc, t_cond] = findgroups(...
                    d_code, meta.SessionID, meta.Location, meta.Condition);
                nGroups = max(G);

                psd_aggregated = zeros(nGroups, nCh, size(psd_data, 3), 'single');

                for i = 1:nGroups
                    psd_aggregated(i, :, :) = mean(psd_data(G==i, :, :), 1);
                end

                psdResult = psd_aggregated;
                resultMeta = table(t_date, t_sess, t_loc, t_cond, ...
                    'VariableNames', {'DateCode', 'SessionID', 'Location', 'Condition'});
            else
                % 对于 Default 和 Global 模式，Signal 已经聚合过了，FFT 出来的结果就是最终结果
                psdResult = psd_data;
            end

            % === 第四步：计算 SNR (可选) ===
            if calcSNR
                fprintf('  [SNR] 计算 SNR 谱...\n');
                % 输入 PSD，输出 SNR
                snrResult = NeuroAlgo.compute_snr_spectrum(psdResult, freqVec);
                extraInfo.SNR = snrResult;
            else
                extraInfo.SNR = [];
            end

            extraInfo.Meta = resultMeta;
            fprintf('  分析完成。输出形状: [%s]\n', strjoin(string(size(psdResult)), 'x'));
        end

        % -----------------------d-prime计算----------------------%
        function [dp_val, stats] = analyze_dprime(~, psdData, psdMeta, freqVec, targetHz, varargin)
            % ANALYZE_DPRIME 计算 d-prime
            % psdData: [N_Groups, nCh, nFreq]
            % psdMeta: 对应的元数据表 (必须包含 DateCode, SessionID, Condition)
            % targetHz: 目标频率
            % varargin: 可选参数 'NoiseCondition' (默认 -1)

            % 1. 解析参数
            p = inputParser;
            addParameter(p, 'NoiseCondition', -1); % 定义哪个 Condition 是噪声/基线
            parse(p, varargin{:});
            noiseCond = p.Results.NoiseCondition;

            fprintf('>>> d-prime 分析 @ %.1f Hz (Session Level Aggregation) <<<\n', targetHz);

            % 2. 提取目标频率的功率
            [~, f_idx] = min(abs(freqVec - targetHz));
            pow_all = squeeze(psdData(:, :, f_idx)); % [N_Groups, nCh]

            % 3. 按 Session 分组聚合
            % 我们需要找到同一天、同一个 Session 的数据
            if iscell(psdMeta.DateCode), d_code = string(psdMeta.DateCode); else, d_code = psdMeta.DateCode; end

            [G, ~, ~] = findgroups(d_code, psdMeta.SessionID);
            nSessions = max(G);
            nCh = size(psdData, 2);

            % 预分配 Session 级别的分布
            % dist_sig: 每个 Session 一个点 (所有 Signal 的均值)
            % dist_noise: 每个 Session 一个点 (Noise 的值)
            dist_sig   = nan(nSessions, nCh);
            dist_noise = nan(nSessions, nCh);

            valid_mask = true(nSessions, 1); % 标记哪些 Session 是完整的(既有Signal又有Noise)

            for i = 1:nSessions
                % 找到当前 Session 的所有行
                idx_sess = (G == i);

                % 在当前 Session 内区分 Signal 和 Noise
                % Noise: Condition == -1
                % Signal: Condition != -1 (即所有其他 Condition)
                idx_noise = idx_sess & (psdMeta.Condition == noiseCond);
                idx_sig   = idx_sess & (psdMeta.Condition ~= noiseCond);

                % 提取并聚合 Signal
                if any(idx_sig)
                    % 【关键修改】取均值：将该 Session 下所有 Signal Condition 平均为一个样本
                    dist_sig(i, :) = mean(pow_all(idx_sig, :), 1);
                else
                    valid_mask(i) = false; % 该 Session 没有 Signal 数据
                end

                % 提取 Noise
                if any(idx_noise)
                    % 通常 Noise 只有一个 Condition，如果有多个也取均值
                    dist_noise(i, :) = mean(pow_all(idx_noise, :), 1);
                else
                    valid_mask(i) = false; % 该 Session 没有 Noise 数据
                end
            end

            % 4. 剔除无效 Session
            if sum(valid_mask) < nSessions
                fprintf('  [Warn] 剔除 %d 个不完整 Session (缺失 Signal 或 Noise)\n', nSessions - sum(valid_mask));
            end

            dist_sig   = dist_sig(valid_mask, :);
            dist_noise = dist_noise(valid_mask, :);

            if isempty(dist_sig)
                error('没有找到任何完整的 Session 对用于计算 d-prime');
            end

            % 5. 计算 d-prime (基于 Session 样本分布)
            % 使用之前的 NeuroAlgo 工具
            dp_val = NeuroAlgo.compute_dprime(dist_sig, dist_noise);

            % 6. 统计检验 (配对 t 检验 Paired t-test)
            % 因为 Signal_i 和 Noise_i 来自同一个 Session，它们是配对的
            stats.p_val = zeros(1, nCh);
            stats.h_val = zeros(1, nCh);

            for c = 1:nCh
                % 使用 ttest (配对) 而不是 ttest2 (独立)
                [h, p] = ttest(dist_sig(:,c), dist_noise(:,c), 'Tail', 'right');
                stats.p_val(c) = p;
                stats.h_val(c) = h;
            end
        end
    end
end


