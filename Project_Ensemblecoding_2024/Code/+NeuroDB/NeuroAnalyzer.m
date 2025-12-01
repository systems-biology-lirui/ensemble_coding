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
        function [epochData, epochMeta] = slice_epochs1(obj, varargin)
            % 解析参数
            p = inputParser;
            addParameter(p, 'CollapseToCount', 0, @isnumeric); % 压缩成几个阶段 (Repeat)
            addParameter(p, 'AverageRepeats', false, @islogical);
            addParameter(p, 'Verbose', true, @islogical);
            addParameter(p, 'Save', false, @islogical);
            addParameter(p, 'SaveDir', '', @ischar);
            addParameter(p, 'SingleTrials', false, @islogical);
            parse(p, varargin{:});

            nCollapse = p.Results.CollapseToCount;
            doAvg     = p.Results.AverageRepeats;
            verbose   = p.Results.Verbose;
            isSingleTrial = p.Results.SingleTrials;

            % 性能计时
            tStart = tic;

            % === 1. 基础参数与时间轴 ===
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

            if verbose, fprintf('>>> 开始极速切片 (Target Repeats: %d) <<<\n', nCollapse); end

            % === 2. Pass 1: 快速扫描构建索引 (不读数据) ===
            % 这一步必须做，用来计算权重和目标位置
            lens = cellfun(@length, obj.StimSeq);
            nEst = sum(lens);

            % 使用原生数组代替 struct 数组以提升速度
            vec_DateCode = strings(nEst, 1);
            vec_Session  = zeros(nEst, 1, 'double');
            vec_Loc      = zeros(nEst, 1, 'int16');
            vec_PicID    = zeros(nEst, 1, 'int16');
            vec_Pat      = zeros(nEst, 1, 'int16');
            vec_SrcTrial = zeros(nEst, 1, 'int32');
            vec_Onset    = zeros(nEst, 1, 'int32');

            global_cnt = 0;
            % 尽量减少循环内的开销
            for i = 1:nLongTrials
                seq = obj.StimSeq{i};
                if isempty(seq), continue; end

                % 提取当前 Long Trial 的元数据
                cur_date = string(obj.MetaTable.DateCode(i));
                if iscell(cur_date), cur_date = cur_date{1}; end
                cur_sess = obj.MetaTable.SessionID(i);
                cur_loc  = obj.MetaTable.Location(i);
                if iscell(cur_loc), cur_loc = -1; end

                if i <= length(obj.Pattern), pat = obj.Pattern{i}; else, pat = []; end
                if iscell(pat), try pat=[pat{:}]; catch, pat=zeros(size(seq)); end; end

                min_len = min(length(seq), length(pat));

                % 向量化计算 Onsets
                k_vec = 1:min_len;
                onsets = offset_pts + (k_vec-1)*soa_pts - nPre;

                % 筛选有效范围
                valid_mask = (onsets >= 1) & (onsets + win_len - 1 <= maxLongTime);
                if ~any(valid_mask), continue; end

                valid_onsets = onsets(valid_mask);
                nValid = length(valid_onsets);

                % 填充索引
                idx_range = global_cnt + (1:nValid);
                vec_DateCode(idx_range) = cur_date;
                vec_Session(idx_range)  = cur_sess;
                vec_Loc(idx_range)      = cur_loc;
                vec_PicID(idx_range)    = seq(valid_mask);
                vec_Pat(idx_range)      = pat(valid_mask);
                vec_SrcTrial(idx_range) = i;
                vec_Onset(idx_range)    = valid_onsets;

                global_cnt = global_cnt + nValid;
            end

            % 截断
            valid_idx = 1:global_cnt;
            vec_DateCode = vec_DateCode(valid_idx); vec_Session = vec_Session(valid_idx);
            vec_Loc = vec_Loc(valid_idx); vec_PicID = vec_PicID(valid_idx);
            vec_Pat = vec_Pat(valid_idx); vec_SrcTrial = vec_SrcTrial(valid_idx);
            vec_Onset = vec_Onset(valid_idx);

            if verbose, fprintf('  [Info] 扫描完成: %d Epochs (耗时 %.2fs)\n', global_cnt, toc(tStart)); end

            % === 3. 核心计算：权重分配与目标映射 (Map Building) ===
            % 我们需要确定每个 Epoch 的：
            %   1. DestRow: 它属于哪个最终结果行
            %   2. Weight: 它在累加时的权重 (1/该Session的总Trial数)
            %   3. NormFactor: 最终除以多少 (该Stage包含的Session数)
            if isSingleTrial
                if verbose, fprintf('  [Info] SingleTrials 模式: 不进行平均，保留原始 Epochs。\n'); end

                % 1. 直接 1对1 映射
                % Pass 1 扫描到的 global_cnt 就是总行数
                total_output_rows = global_cnt;

                % 2. 建立 Map (所有权重为 1，目标行就是自身索引)
                Map_DestRow = (1:global_cnt)';
                Map_Weight  = ones(global_cnt, 1, 'single');

                % 3. 直接构建 Meta 数据 (直接使用 Pass 1 产生的向量)
                % 注意：这里直接截取有效部分
                out_Meta_Loc = vec_Loc(1:global_cnt);
                out_Meta_Pic = vec_PicID(1:global_cnt);
                out_Meta_Pat = vec_Pat(1:global_cnt);

                % 对于 Single Trial，Stage 概念不再适用，统一设为 1
                out_Meta_Stage = ones(global_cnt, 1);
                out_Meta_SessCount = ones(global_cnt, 1);

                % 日期处理
                out_Meta_DateRange = vec_DateCode(1:global_cnt);
            else
                % 按条件 (Loc, Pic, Pat) 分组
                [CondG, u_Loc, u_Pic, u_Pat] = findgroups(vec_Loc, vec_PicID, vec_Pat);
                nConditions = max(CondG);

                % 预分配 Map
                Map_DestRow = zeros(global_cnt, 1);
                Map_Weight  = zeros(global_cnt, 1, 'single');

                % 预分配输出 Meta
                % 我们无法预知确切行数，但上限是 nConditions * nCollapse
                % 稍微多分配一点，最后截断
                max_out_rows = nConditions * max(1, nCollapse);
                out_Meta_Loc = zeros(max_out_rows, 1);
                out_Meta_Pic = zeros(max_out_rows, 1);
                out_Meta_Pat = zeros(max_out_rows, 1);
                out_Meta_Stage = zeros(max_out_rows, 1);
                out_Meta_SessCount = zeros(max_out_rows, 1); % 该Stage有多少个Session
                out_Meta_DateRange = strings(max_out_rows, 1);

                curr_out_row = 0;

                if verbose, fprintf('  [Info] 计算索引映射与权重...\n'); end

                for c = 1:nConditions
                    % 找到属于该 Condition 的所有 Epoch 索引
                    idx_cond = find(CondG == c);

                    % 在该 Condition 内，按 DateCode 和 SessionID 分组
                    sub_dates = vec_DateCode(idx_cond);
                    sub_sess  = vec_Session(idx_cond);

                    [SessG, u_sub_date, u_sub_sess] = findgroups(sub_dates, sub_sess);
                    nSessions = max(SessG);

                    % 统计每个 Session 有多少个 Trial (Count Trials per Session)
                    % histcounts 对于 integer group 很快
                    trials_per_sess = histcounts(SessG, 1:(nSessions+1));

                    % 对 Session 进行排序 (按日期)
                    % u_sub_date 是 string 数组，可以直接排序
                    T_Sess = table(u_sub_date, u_sub_sess, (1:nSessions)', 'VariableNames', {'D','S','OldID'});
                    T_Sess = sortrows(T_Sess, {'D','S'});
                    sorted_sess_indices = T_Sess.OldID; % 排序后的 Session 顺序

                    % --- 决定分段策略 ---
                    if nCollapse > 0
                        % 目标：分为 nCollapse 个阶段
                        nStages = nCollapse;
                        if nSessions < nCollapse
                            nStages = nSessions; % Session 不够分，有多少分多少
                            edges = 0:nStages;
                        else
                            edges = round(linspace(0, nSessions, nStages + 1));
                        end
                    else
                        % 目标：不合并 (Session Averages) 或 AverageRepeats 模式
                        if doAvg
                            nStages = 1; % 全部合并成1个
                            edges = [0, nSessions];
                        else
                            % 保持每个 Session 独立 (这里为了统一逻辑，也视为 Stage)
                            nStages = nSessions;
                            edges = 0:nStages;
                        end
                    end

                    % --- 分配 ---
                    for s = 1:nStages
                        % 获取当前 Stage 包含的 Session (在排序后的列表中的索引)
                        sess_start = edges(s) + 1;
                        sess_end   = edges(s+1);
                        target_sess_ids = sorted_sess_indices(sess_start:sess_end);

                        if isempty(target_sess_ids), continue; end

                        % 这是一个新的输出行
                        curr_out_row = curr_out_row + 1;

                        % 记录 Meta
                        out_Meta_Loc(curr_out_row) = u_Loc(c);
                        out_Meta_Pic(curr_out_row) = u_Pic(c);
                        out_Meta_Pat(curr_out_row) = u_Pat(c);
                        out_Meta_Stage(curr_out_row) = s;
                        nSessInStage = length(target_sess_ids);
                        out_Meta_SessCount(curr_out_row) = nSessInStage;
                        out_Meta_DateRange(curr_out_row) = T_Sess.D(target_sess_ids(1)) + " to " + T_Sess.D(target_sess_ids(end));

                        % 填充 Map
                        for k = 1:length(target_sess_ids)
                            ss_id = target_sess_ids(k);
                            % 找到属于这个 Session 的所有 Epoch (在全局列表中的索引)
                            % 逻辑：Idx_Cond 中的哪些元素属于 SessG == ss_id
                            global_indices = idx_cond(SessG == ss_id);

                            % 设置目标行
                            Map_DestRow(global_indices) = curr_out_row;

                            % 设置权重
                            % 公式：Weight = 1 / (TrialCount * SessionCountInStage)
                            % 这样直接累加就是最终平均值，不需要再除
                            nTrials = trials_per_sess(ss_id);
                            w = 1 / (nTrials * nSessInStage);
                            Map_Weight(global_indices) = w;
                        end
                    end
                end

                total_output_rows = curr_out_row;
                fprintf('  [Info] 映射构建完成: 将输出 %d 行数据。\n', total_output_rows);
            end
            % === 4. Pass 2: 极速加权累加 (Vectorized Accumulation) ===
            % 预分配内存 (Single 精度)
            Accumulator = zeros(total_output_rows, nCh, win_len, 'single');

            unique_source_trials = unique(vec_SrcTrial);
            nBlocks = length(unique_source_trials);

            hWait = waitbar(0, 'Batch Processing...');

            for b = 1:nBlocks
                if mod(b, 50) == 0, waitbar(b/nBlocks, hWait); end

                uTrialIdx = unique_source_trials(b);

                % 1. 获取当前 Block 涉及的所有 Epoch 信息
                % 使用逻辑索引通常比 find 快
                mask = (vec_SrcTrial == uTrialIdx);

                these_onsets = vec_Onset(mask);
                these_dest   = Map_DestRow(mask);
                these_weight = Map_Weight(mask);

                % 如果没有有效目标（比如被过滤掉了），跳过
                valid_k = (these_dest > 0);
                if ~any(valid_k), continue; end

                these_onsets = these_onsets(valid_k);
                these_dest   = these_dest(valid_k);
                these_weight = these_weight(valid_k);

                % 2. 读取原始数据 (一次性读取整行)
                % [1, nCh, nTime] -> [nCh, nTime]
                raw_chunk = single(squeeze(obj.RawTensor(uTrialIdx, :, :)));

                % 3. 极速聚合策略
                % 一个 SourceTrial 里可能包含属于同一个 DestRow 的多个 Epoch
                % 先在本地合并，再写全局内存

                u_dests = unique(these_dest);
                for d_idx = 1:length(u_dests)
                    target_row = u_dests(d_idx);

                    % 找到属于这个目标行的 epoch 索引
                    k_indices = (these_dest == target_row);
                    k_onsets  = these_onsets(k_indices);
                    k_weights = these_weight(k_indices);

                    % 本地累加器 (Local Sum)
                    % 这是一个 [nCh, win_len] 的矩阵
                    local_sum = zeros(nCh, win_len, 'single');

                    for i = 1:length(k_onsets)
                        idx_s = k_onsets(i);
                        % 提取并加权
                        % raw_chunk(:, idx_s : idx_s+win_len-1) 是 [nCh, win_len]
                        local_sum = local_sum + raw_chunk(:, idx_s : idx_s+win_len-1) * k_weights(i);
                    end

                    % 写入全局 Accumulator
                    Accumulator(target_row, :, :) = Accumulator(target_row, :, :) + reshape(local_sum, [1, nCh, win_len]);
                end
            end
            close(hWait);

            % === 5. 收尾 ===
            epochData = Accumulator;

            % 截断 Meta 表
            epochMeta = table(out_Meta_Loc(1:total_output_rows), ...
                out_Meta_Pic(1:total_output_rows), ...
                out_Meta_Pat(1:total_output_rows), ...
                out_Meta_Stage(1:total_output_rows), ...
                out_Meta_SessCount(1:total_output_rows), ...
                out_Meta_DateRange(1:total_output_rows), ...
                'VariableNames', {'Location', 'PicID', 'Pattern', 'StageID', 'SessionsAveraged', 'DateRange'});

            % 去基线
            if isfield(obj.Config, 'RemoveBaseline') && obj.Config.RemoveBaseline
                epochData = epochData - mean(epochData(:,:,1:20), 3);
            end

            if verbose, fprintf('=== 切片完成 (耗时 %.2fs) ===\n', toc(tStart)); end

            if p.Results.Save
                obj.save_epoch_dataset(epochData, epochMeta, true, p.Results.SaveDir);
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


        % ------------------------滤波----------------------------%

        function filter_raw_data(obj)
            fprintf('>>> 开始执行陷波滤波 (50Hz, 100Hz) ...\n');

            % 1. 获取基础参数
            [nTrials, nCh, nTime] = size(obj.RawTensor);

            if isfield(obj.Config, 'Fs')
                Fs = obj.Config.Fs;
            else
                Fs = 1000;
                warning('Config 中未找到 Fs，默认使用 1000Hz');
            end

            % 2. 设计滤波器 (使用 designfilt 设计，转换为 b, a)
            % 50Hz 陷波
            d50 = designfilt('bandstopiir', 'FilterOrder', 2, ...
                'HalfPowerFrequency1', 48, 'HalfPowerFrequency2', 52, ...
                'DesignMethod', 'butter', 'SampleRate', Fs);
            [b50, a50] = tf(d50);

            % 100Hz 陷波
            d100 = designfilt('bandstopiir', 'FilterOrder', 2, ...
                'HalfPowerFrequency1', 98, 'HalfPowerFrequency2', 102, ...
                'DesignMethod', 'butter', 'SampleRate', Fs);
            [b100, a100] = tf(d100);

            % 3. 准备处理
            hWait = waitbar(0, 'Filtering Data...');
            % 检查数据类型，决定是否需要转回 int16
            isInt16 = isa(obj.RawTensor, 'int16');

            % 4. 逐个 Trial 循环处理
            for i = 1:nTrials
                if mod(i, 50) == 0
                    waitbar(i/nTrials, hWait, sprintf('Filtering Trial %d/%d', i, nTrials));
                end

                % --- [步骤 A] 读取并转置 ---
                % 原始形状: [nCh, nTime]
                % 我们需要转置为 [nTime, nCh]，因为 filtfilt 默认滤“列”
                trialData = single(squeeze(obj.RawTensor(i, :, :))).';

                % --- [步骤 B] 滤波 (现在每一列是一个 Channel 的时间序列) ---

                % 滤 50Hz
                trialData = filtfilt(b50, a50, trialData);

                % 滤 100Hz
                trialData = filtfilt(b100, a100, trialData);

                % --- [步骤 C] 转置回来并保存 ---
                % 滤波后形状仍为 [nTime, nCh]，转置回 [nCh, nTime]
                trialData = trialData.';

                if isInt16
                    obj.RawTensor(i, :, :) = int16(trialData);
                else
                    obj.RawTensor(i, :, :) = trialData;
                end
            end

            close(hWait);
            fprintf('  [完成] 滤波结束。\n');
        end


        function [epochData, epochMeta] = slice_epochs(obj, varargin)
            % 解析参数
            p = inputParser;
            addParameter(p, 'CollapseToCount', 0, @isnumeric); % 压缩成几个阶段
            addParameter(p, 'AverageRepeats', false, @islogical);
            addParameter(p, 'Verbose', true, @islogical);
            addParameter(p, 'Save', false, @islogical);
            addParameter(p, 'SaveDir', '', @ischar);
            addParameter(p, 'SingleTrials', false, @islogical);
            parse(p, varargin{:});

            nCollapse = p.Results.CollapseToCount;
            doAvg     = p.Results.AverageRepeats;
            verbose   = p.Results.Verbose;
            isSingleTrial = p.Results.SingleTrials;

            % 性能计时
            tStart = tic;

            % === 1. 基础参数与时间轴 ===
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

            if verbose, fprintf('>>> 开始极速切片 (Target Repeats: %d) <<<\n', nCollapse); end

            % === 2. Pass 1: 快速扫描构建索引 (不读数据) ===
            lens = cellfun(@length, obj.StimSeq);
            nEst = sum(lens);

            % 使用原生数组代替 struct 数组以提升速度
            vec_DateCode = strings(nEst, 1);
            vec_Session  = zeros(nEst, 1, 'double');
            vec_Loc      = zeros(nEst, 1, 'int16');
            vec_PicID    = zeros(nEst, 1, 'int16');
            vec_Pat      = zeros(nEst, 1, 'int16');
            vec_SrcTrial = zeros(nEst, 1, 'int32');
            vec_Onset    = zeros(nEst, 1, 'int32');

            global_cnt = 0;
            for i = 1:nLongTrials
                seq = obj.StimSeq{i};
                if isempty(seq), continue; end

                cur_date = string(obj.MetaTable.DateCode(i));
                if iscell(cur_date), cur_date = cur_date{1}; end
                cur_sess = obj.MetaTable.SessionID(i);
                cur_loc  = obj.MetaTable.Location(i);
                if iscell(cur_loc), cur_loc = -1; end

                if i <= length(obj.Pattern), pat = obj.Pattern{i}; else, pat = []; end
                if iscell(pat), try pat=[pat{:}]; catch, pat=zeros(size(seq)); end; end

                min_len = min(length(seq), length(pat));

                k_vec = 1:min_len;
                onsets = offset_pts + (k_vec-1)*soa_pts - nPre;

                valid_mask = (onsets >= 1) & (onsets + win_len - 1 <= maxLongTime);
                if ~any(valid_mask), continue; end

                valid_onsets = onsets(valid_mask);
                nValid = length(valid_onsets);

                idx_range = global_cnt + (1:nValid);
                vec_DateCode(idx_range) = cur_date;
                vec_Session(idx_range)  = cur_sess;
                vec_Loc(idx_range)      = cur_loc;
                vec_PicID(idx_range)    = seq(valid_mask);
                vec_Pat(idx_range)      = pat(valid_mask);
                vec_SrcTrial(idx_range) = i;
                vec_Onset(idx_range)    = valid_onsets;

                global_cnt = global_cnt + nValid;
            end

            if verbose, fprintf('  [Info] 扫描完成: 找到 %d 个原始 Epochs (耗时 %.2fs)\n', global_cnt, toc(tStart)); end

            % === 2.5. 【新增】按 PicID 过滤 ===
            % 创建一个逻辑掩码，只保留 PicID 在 1 到 18 之间的 epoch
            picid_filter_mask = (vec_PicID >= 1) & (vec_PicID <= 18);

            % 应用过滤器，获取有效索引
            valid_idx = find(picid_filter_mask);
            global_cnt = length(valid_idx); % 更新 global_cnt 为过滤后的数量

            % 检查过滤后是否还有 epoch
            if global_cnt == 0
                if verbose
                    fprintf('  [Warning] 没有找到 PicID 在 1-18 范围内的 epoch。返回空结果。\n');
                end
                epochData = [];
                epochMeta = table('Size', [0 6], ...
                    'VariableTypes', {'double', 'double', 'double', 'double', 'double', 'string'}, ...
                    'VariableNames', {'Location', 'PicID', 'Pattern', 'StageID', 'SessionsAveraged', 'DateRange'});
                return; % 提前退出函数
            end

            % 使用过滤器截断所有向量
            vec_DateCode = vec_DateCode(valid_idx);
            vec_Session  = vec_Session(valid_idx);
            vec_Loc      = vec_Loc(valid_idx);
            vec_PicID    = vec_PicID(valid_idx);
            vec_Pat      = vec_Pat(valid_idx);
            vec_SrcTrial = vec_SrcTrial(valid_idx);
            vec_Onset    = vec_Onset(valid_idx);

            if verbose, fprintf('  [Info] PicID 过滤完成: 保留 %d 个 Epochs。\n', global_cnt); end
            % === 过滤部分结束 ===

            % === 3. 核心计算：权重分配与目标映射 ===
            if isSingleTrial
                if verbose, fprintf('  [Info] SingleTrials 模式: 不进行平均，保留原始 Epochs。\n'); end
                total_output_rows = global_cnt;
                Map_DestRow = (1:global_cnt)';
                Map_Weight  = ones(global_cnt, 1, 'single');
                out_Meta_Loc = vec_Loc;
                out_Meta_Pic = vec_PicID;
                out_Meta_Pat = vec_Pat;
                out_Meta_Stage = ones(global_cnt, 1);
                out_Meta_SessCount = ones(global_cnt, 1);
                out_Meta_DateRange = vec_DateCode;
            else
                % 按条件 分组
                [CondG, u_Loc, u_Pic, u_Pat] = findgroups(vec_Loc, vec_PicID, vec_Pat);
                nConditions = max(CondG);

                Map_DestRow = zeros(global_cnt, 1);
                Map_Weight  = zeros(global_cnt, 1, 'single');

                max_out_rows = nConditions * max(1, nCollapse);
                out_Meta_Loc = zeros(max_out_rows, 1);
                out_Meta_Pic = zeros(max_out_rows, 1);
                out_Meta_Pat = zeros(max_out_rows, 1);
                out_Meta_Stage = zeros(max_out_rows, 1);
                out_Meta_SessCount = zeros(max_out_rows, 1);
                out_Meta_DateRange = strings(max_out_rows, 1);

                curr_out_row = 0;
                if verbose, fprintf('  [Info] 计算索引映射与权重...\n'); end

                for c = 1:nConditions
                    idx_cond = find(CondG == c);
                    sub_dates = vec_DateCode(idx_cond);
                    sub_sess  = vec_Session(idx_cond);

                    [SessG, u_sub_date, u_sub_sess] = findgroups(sub_dates, sub_sess);
                    nSessions = max(SessG);
                    trials_per_sess = histcounts(SessG, 1:(nSessions+1));

                    T_Sess = table(u_sub_date, u_sub_sess, (1:nSessions)', 'VariableNames', {'D','S','OldID'});
                    T_Sess = sortrows(T_Sess, {'D','S'});
                    sorted_sess_indices = T_Sess.OldID;

                    if nCollapse > 0
                        nStages = nCollapse;
                        if nSessions < nCollapse
                            nStages = nSessions;
                            edges = 0:nStages;
                        else
                            edges = round(linspace(0, nSessions, nStages + 1));
                        end
                    else
                        if doAvg
                            nStages = 1;
                            edges = [0, nSessions];
                        else
                            nStages = nSessions;
                            edges = 0:nStages;
                        end
                    end

                    for s = 1:nStages
                        sess_start = edges(s) + 1;
                        sess_end   = edges(s+1);
                        target_sess_ids = sorted_sess_indices(sess_start:sess_end);
                        if isempty(target_sess_ids), continue; end

                        curr_out_row = curr_out_row + 1;
                        out_Meta_Loc(curr_out_row) = u_Loc(c);
                        out_Meta_Pic(curr_out_row) = u_Pic(c);
                        out_Meta_Pat(curr_out_row) = u_Pat(c);
                        out_Meta_Stage(curr_out_row) = s;
                        nSessInStage = length(target_sess_ids);
                        out_Meta_SessCount(curr_out_row) = nSessInStage;
                        out_Meta_DateRange(curr_out_row) = T_Sess.D(target_sess_ids(1)) + " to " + T_Sess.D(target_sess_ids(end));

                        for k = 1:length(target_sess_ids)
                            ss_id = target_sess_ids(k);
                            global_indices = idx_cond(SessG == ss_id);
                            Map_DestRow(global_indices) = curr_out_row;
                            nTrials = trials_per_sess(ss_id);
                            w = 1 / (nTrials * nSessInStage);
                            Map_Weight(global_indices) = w;
                        end
                    end
                end
                total_output_rows = curr_out_row;
                fprintf('  [Info] 映射构建完成: 将输出 %d 行数据。\n', total_output_rows);
            end

            % === 4. Pass 2: 极速加权累加 (Vectorized Accumulation) ===
            Accumulator = zeros(total_output_rows, nCh, win_len, 'single');
            unique_source_trials = unique(vec_SrcTrial);
            nBlocks = length(unique_source_trials);
            hWait = waitbar(0, 'Batch Processing...');

            for b = 1:nBlocks
                if mod(b, 50) == 0, waitbar(b/nBlocks, hWait); end
                uTrialIdx = unique_source_trials(b);
                mask = (vec_SrcTrial == uTrialIdx);
                these_onsets = vec_Onset(mask);
                these_dest   = Map_DestRow(mask);
                these_weight = Map_Weight(mask);
                valid_k = (these_dest > 0);
                if ~any(valid_k), continue; end
                these_onsets = these_onsets(valid_k);
                these_dest   = these_dest(valid_k);
                these_weight = these_weight(valid_k);
                raw_chunk = single(squeeze(obj.RawTensor(uTrialIdx, :, :)));
                u_dests = unique(these_dest);
                for d_idx = 1:length(u_dests)
                    target_row = u_dests(d_idx);
                    k_indices = (these_dest == target_row);
                    k_onsets  = these_onsets(k_indices);
                    k_weights = these_weight(k_indices);
                    local_sum = zeros(nCh, win_len, 'single');
                    for i = 1:length(k_onsets)
                        idx_s = k_onsets(i);
                        local_sum = local_sum + raw_chunk(:, idx_s : idx_s+win_len-1) * k_weights(i);
                    end
                    Accumulator(target_row, :, :) = Accumulator(target_row, :, :) + reshape(local_sum, [1, nCh, win_len]);
                end
            end
            close(hWait);

            % === 5. 收尾 ===
            epochData = Accumulator;
            epochMeta = table(out_Meta_Loc(1:total_output_rows), ...
                out_Meta_Pic(1:total_output_rows), ...
                out_Meta_Pat(1:total_output_rows), ...
                out_Meta_Stage(1:total_output_rows), ...
                out_Meta_SessCount(1:total_output_rows), ...
                out_Meta_DateRange(1:total_output_rows), ...
                'VariableNames', {'Location', 'PicID', 'Pattern', 'StageID', 'SessionsAveraged', 'DateRange'});

            % 去基线
            if isfield(obj.Config, 'RemoveBaseline') && obj.Config.RemoveBaseline
                epochData = epochData - mean(epochData(:,:,1:20), 3);
            end

            if verbose, fprintf('=== 切片完成 (耗时 %.2fs) ===\n', toc(tStart)); end

            if p.Results.Save
                obj.save_epoch_dataset(epochData, epochMeta, true, p.Results.SaveDir);
            end
        end

    end
end



