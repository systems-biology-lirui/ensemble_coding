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
        % 为了找到文件，必须传入 paradigm 和 dataType，或者由内部搜索
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

        function [epochData, epochMeta] = slice_epochs(obj, varargin)
            % 解析参数
            p = inputParser;
            addParameter(p, 'AverageRepeats', false, @islogical); % 新增开关
            addParameter(p, 'Verbose', true, @islogical);
            parse(p, varargin{:});
            doAvg = p.Results.AverageRepeats;
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
                    Accumulator = zeros(nGroups, nCh, win_len, 'int16');
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
                    chunk = long_data(1, :, idx_s:idx_e);

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
                epochData = int16(single(Accumulator) ./ Counts);

                % [修改点 4] 输出表中包含 DateCode
                epochMeta = table(tbl_Date, tbl_Sess, tbl_Loc, tbl_Pic, tbl_Pat, Counts, ...
                    'VariableNames', {'DateCode', 'SessionID', 'Location', 'PicID', 'Pattern', 'AvgCount'});
            else
                epochData = Accumulator;
                epochMeta = table(temp_DateCode, temp_Session, temp_Loc, temp_PicID, temp_Pattern, temp_SourceTrial, ...
                    'VariableNames', {'DateCode', 'SessionID', 'Location', 'PicID', 'Pattern', 'OriginTrialIdx'});
            end

            if verbose, fprintf('=== 完成 ===\n'); end
        end


    end
end