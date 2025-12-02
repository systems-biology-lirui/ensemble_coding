classdef Analyzer < handle
    % NEUROQC.ANALYZER 
    % 信号质量评估与基础特征分析工具箱
    % 
    % 用法:
    %   qc = NeuroQC.Analyzer(dataTensor, metaTable, fs, timeVec);
    %   qc.detect_bad_trials('Threshold', 500);
    %   qc.check_channel_correlation();
    %   qc.plot_report();
    
    properties
        Data        % [nTrials, nCh, nTime] (Single/Double)
        Meta        % Table with trial info
        Fs          % Sampling Rate
        TimeVec     % Time vector (ms)
        
        % 状态记录
        BadTrials   % Logical mask [nTrials x 1] (True = Bad)
        BadChannels % Logical mask [nCh x 1] (True = Bad)
        
        % 统计信息
        Stats       % Struct 存储计算出的统计量 (SNR, Correlation等)
    end
    
    methods
        function obj = Analyzer(data, meta, fs, timeVec)
            % 构造函数
            % data: [nTrials, nCh, nPoints]
            % meta: Table (必须包含与 nTrials 对应的行数)
            % fs:   采样率 (Hz)
            % timeVec: 时间向量 (ms)
            
            if nargin < 4, timeVec = []; end
            
            obj.Data = data;
            obj.Meta = meta;
            obj.Fs = fs;
            obj.TimeVec = timeVec;
            
            [nTrials, nCh, ~] = size(data);
            obj.BadTrials = false(nTrials, 1);
            obj.BadChannels = false(nCh, 1);
            obj.Stats = struct();
        end
        
        % ============================================================
        % 1. 试次剔除 (Trial Rejection)
        % ============================================================
        function [mask, nRemoved] = detect_bad_trials(obj, varargin)
            % DETECT_BAD_TRIALS 基于幅度阈值或标准差检测坏试次
            % 参数:
            %   'Method': 'absolute' (绝对值), 'std' (标准差倍数)
            %   'Threshold': 阈值 (absolute: uV, std: 倍数)
            %   'Channels': 指定检查的通道 (默认全部)
            
            p = inputParser;
            addParameter(p, 'Method', 'std', @ischar); % 默认为 std 方法
            addParameter(p, 'Threshold', 5, @isnumeric); % 默认 5倍标准差
            addParameter(p, 'Channels', [], @isnumeric);
            addParameter(p, 'Apply', true, @islogical); % 是否应用到 obj.BadTrials
            parse(p, varargin{:});
            
            method = p.Results.Method;
            thr = p.Results.Threshold;
            chans = p.Results.Channels;
            
            if isempty(chans)
                % 检查所有非坏通道
                d = obj.Data(:, ~obj.BadChannels, :);
            else
                d = obj.Data(:, chans, :);
            end
            
            % d is [nTrials, nChSubset, nTime]
            
            if strcmp(method, 'absolute')
                % 计算每个 Trial 的最大绝对幅值
                metric = max(abs(d), [], [2, 3]);
                mask = metric > thr;
                
            elseif strcmp(method, 'std')
                % 基于标准差剔除 (Z-score approach)
                % 1. 计算每个 Trial 的平均能量 (RMS) 或 Max Amplitude
                % 这里我们使用 Max Amplitude 作为特征指标，因为 artifact 通常表现为大幅值
                trial_max_amps = max(abs(d), [], [2, 3]);
                
                % 2. 计算总体分布的 Mean 和 Std (使用 robust 统计量以防受异常值影响)
                mu = median(trial_max_amps);
                sigma = 1.4826 * median(abs(trial_max_amps - mu)); % MAD estimator for sigma
                
                % 3. 设定阈值: Mean + N * Std
                cutoff = mu + thr * sigma;
                
                mask = trial_max_amps > cutoff;
                metric = trial_max_amps;
                
                fprintf('[QC] STD剔除策略: Median=%.1f, Sigma=%.1f, Cutoff=%.1f (Threshold=%d*Std)\n', ...
                    mu, sigma, cutoff, thr);
            else
                error('Unknown method: %s', method);
            end
            
            nRemoved = sum(mask);
            ratio = nRemoved / length(mask) * 100;
            
            fprintf('[QC] 坏试次检测 (%s): 发现 %d/%d (%.1f%%) 异常试次。\n', ...
                method, nRemoved, length(mask), ratio);
            
            if p.Results.Apply
                obj.BadTrials = obj.BadTrials | mask;
            end
            
            % 记录统计
            obj.Stats.MaxAmp = metric;
        end
        
        % ============================================================
        % 2. 通道相关性检查 (Channel Correlation)
        % ============================================================
        function [R, badChans] = check_channel_correlation(obj, varargin)
            % CHECK_CHANNEL_CORRELATION 计算通道间相关性
            % 只有相关性极低(可能是断路)或极高(可能是短路)的通道需要关注
            
            p = inputParser;
            addParameter(p, 'Threshold', 0.1, @isnumeric); % 平均相关系数低于此值视为异常
            addParameter(p, 'Apply', false, @islogical);    % 默认不自动剔除通道，仅警告
            parse(p, varargin{:});
            
            thr = p.Results.Threshold;
            
            % 使用有效 Trial 计算
            valid_data = obj.Data(~obj.BadTrials, :, :);
            [~, nCh, ~] = size(valid_data);
            
            fprintf('[QC] 正在计算通道相关性矩阵 (%d Channels)...\n', nCh);
            
            % 展平数据: [nTrials*nTime, nCh]
            % 这种方式计算的是“信号波形相似度”
            X = permute(valid_data, [1, 3, 2]);
            X = reshape(X, [], nCh);
            
            % 计算相关系数矩阵
            R = corrcoef(X);
            obj.Stats.CorrMat = R;
            
            % 计算每个通道与其他通道的平均相关性 (排除对角线)
            R_nodiag = R - eye(nCh);
            mean_r = sum(R_nodiag, 2) / (nCh - 1);
            obj.Stats.MeanCorr = mean_r;
            
            badChans = mean_r < thr;
            nBad = sum(badChans);
            
            if nBad > 0
                fprintf('  ! [Warn] 发现 %d 个通道平均相关性低于 %.2f (可能接触不良)\n', nBad, thr);
                bad_idx = find(badChans);
                if length(bad_idx) < 10
                    fprintf('    Indices: %s\n', mat2str(bad_idx'));
                end
            else
                fprintf('  [Pass] 所有通道相关性正常 (Min: %.2f)\n', min(mean_r));
            end
            
            if p.Results.Apply
                obj.BadChannels = obj.BadChannels | badChans;
            end
        end
        
        % ============================================================
        % 3. 可视化 (Visualization)
        % ============================================================
        function plot_amplitude_dist(obj, varargin)
            % 绘制试次幅值分布直方图
            % 可选参数: 'Threshold' (用于在图中画线)
            
            p = inputParser;
            addParameter(p, 'Threshold', [], @isnumeric);
            parse(p, varargin{:});
            thr = p.Results.Threshold;

            if ~isfield(obj.Stats, 'MaxAmp')
                % 如果还没计算过，先默认跑一次 (Method=std, Apply=false)
                obj.detect_bad_trials('Method', 'std', 'Apply', false); 
            end
            
            figure('Color','w', 'Name', 'Trial Amplitude Distribution');
            histogram(obj.Stats.MaxAmp, 50, 'Normalization', 'probability');
            xlabel('Max Amplitude (uV)');
            ylabel('Probability');
            title('Trial Max Amplitude Distribution');
            grid on;
            
            % 标记阈值线
            hold on;
            yl = ylim;
            
            % 优先使用传入的阈值，否则尝试计算自适应阈值
            if ~isempty(thr)
                line_val = thr;
                label = sprintf('Manual Thr (%.1f)', thr);
            else
                % 尝试恢复 std 阈值
                mu = median(obj.Stats.MaxAmp);
                sigma = 1.4826 * median(abs(obj.Stats.MaxAmp - mu));
                % 假设默认 5 sigma
                line_val = mu + 5 * sigma;
                label = sprintf('Auto Thr (%.1f)', line_val);
            end

            plot([line_val line_val], yl, 'r--', 'LineWidth', 2);
            text(line_val, yl(2)*0.9, [' ' label], 'Color', 'r', 'FontWeight', 'bold');
        end
        
        function plot_correlation_matrix(obj)
            % 绘制相关性热力图
            if ~isfield(obj.Stats, 'CorrMat')
                obj.check_channel_correlation();
            end
            
            figure('Color','w', 'Name', 'Channel Correlation');
            imagesc(obj.Stats.CorrMat);
            colormap('jet');
            colorbar;
            clim([-1 1]);
            title('Channel Correlation Matrix');
            xlabel('Channel ID');
            ylabel('Channel ID');
            axis square;
        end
        
        % ============================================================
        % 4. 基础分析：朝向选择性 / PSTH
        % ============================================================
        function plot_psth_by_condition(obj, groupCol, varargin)
            % PLOT_PSTH_BY_CONDITION 按条件绘制 PSTH
            % groupCol: MetaTable 中的列名 (string), 例如 'PicID' 或 'Pattern'
            
            p = inputParser;
            addParameter(p, 'Channels', [], @isnumeric); % 默认平均所有好通道
            addParameter(p, 'Smooth', 0, @isnumeric);    % 平滑窗口 (points)
            parse(p, varargin{:});
            
            chans = p.Results.Channels;
            if isempty(chans)
                chans = find(~obj.BadChannels);
            end
            
            % 检查列是否存在
            if ~ismember(groupCol, obj.Meta.Properties.VariableNames)
                error('MetaTable 中不存在列: %s', groupCol);
            end
            
            groups = obj.Meta.(groupCol);
            [G, u_groups] = findgroups(groups);
            nConds = length(u_groups);
            
            % 准备数据 (只用好 Trial)
            valid_mask = ~obj.BadTrials;
            
            % 时间轴
            if isempty(obj.TimeVec)
                nT = size(obj.Data, 3);
                t = 1:nT;
            else
                t = obj.TimeVec;
            end
            
            figure('Color','w', 'Name', sprintf('PSTH by %s', groupCol));
            hold on;
            
            colors = lines(nConds);
            
            for i = 1:nConds
                % 筛选当前条件的 Valid Trials
                idx = (G == i) & valid_mask;
                if sum(idx) == 0, continue; end
                
                % 提取数据: [nSubTrials, nSelCh, nTime]
                sub_data = obj.Data(idx, chans, :);
                
                % 计算平均: 先 Trial 平均，再 Channel 平均
                % [nSelCh, nTime]
                mean_trial = squeeze(mean(sub_data, 1)); 
                
                if isvector(mean_trial) && length(chans)==1
                    % 如果只有一个通道，squeeze 后是 [nTime, 1] 或 [1, nTime]
                    grand_avg = mean_trial(:)';
                else
                    % [nSelCh, nTime] -> [1, nTime]
                    grand_avg = mean(mean_trial, 1);
                end
                
                % 平滑
                if p.Results.Smooth > 0
                    grand_avg = smoothdata(grand_avg, 'gaussian', p.Results.Smooth);
                end
                
                plot(t, grand_avg, 'Color', colors(i,:), 'LineWidth', 1.5, ...
                    'DisplayName', sprintf('%s=%s', groupCol, string(u_groups(i))));
            end
            
            xlabel('Time (ms)');
            ylabel('Amplitude (uV)');
            title(sprintf('PSTH grouped by %s (Avg %d Chans)', groupCol, length(chans)));
            legend('show');
            grid on;
        end
        % ============================================================
        % 5. 进阶分析：朝向选择性调谐曲线 (Orientation Tuning Curve)
        % ============================================================
        function plot_tuning_curve(obj, varargin)
            % PLOT_TUNING_CURVE 绘制朝向选择性曲线
            % 假设 'PicID' 代表不同的朝向角度 (例如 0, 45, 90...)
            % 或者 Meta 中有一列明确叫 'Orientation'
            
            p = inputParser;
            addParameter(p, 'Channels', [], @isnumeric);
            addParameter(p, 'GroupCol', 'PicID', @ischar); 
            addParameter(p, 'Window', [], @isnumeric); % [t_start, t_end] 响应计算窗口
            parse(p, varargin{:});
            
            chans = p.Results.Channels;
            colName = p.Results.GroupCol;
            win = p.Results.Window;
            
            if isempty(chans)
                chans = find(~obj.BadChannels);
            end
            
            if ~ismember(colName, obj.Meta.Properties.VariableNames)
                error('MetaTable 中没有列: %s', colName);
            end
            
            % 1. 确定时间窗口索引
            if isempty(win)
                % 默认取整个 Epoch
                t_idx = true(size(obj.TimeVec));
                win_str = 'Full Epoch';
            else
                t_idx = (obj.TimeVec >= win(1)) & (obj.TimeVec <= win(2));
                win_str = sprintf('[%d, %d] ms', win(1), win(2));
            end
            
            % 2. 计算每个 Trial 在窗口内的响应强度 (例如 Mean Firing Rate or RMS)
            % data: [nTrials, nCh, nTime]
            % -> mean over time -> [nTrials, nCh]
            trial_resp = mean(obj.Data(:, chans, t_idx), 3);
            
            % 再对 Channel 取平均 -> [nTrials, 1]
            trial_resp_avg = mean(trial_resp, 2);
            
            % 3. 按条件分组统计
            groups = obj.Meta.(colName);
            [G, u_angles] = findgroups(groups);
            u_angles = single(u_angles);
            % 剔除坏 Trial
            valid_mask = ~obj.BadTrials;
            
            nConds = length(u_angles);
            mean_resp = zeros(nConds, 1);
            sem_resp  = zeros(nConds, 1);
            
            for i = 1:nConds
                idx = (G == i) & valid_mask;
                if sum(idx) == 0, continue; end
                
                vals = trial_resp_avg(idx);
                mean_resp(i) = mean(vals);
                sem_resp(i)  = std(vals) / sqrt(length(vals));
            end
            
            % 4. 绘图
            figure('Color','w', 'Name', sprintf('Tuning Curve (%s)', colName));
            errorbar(u_angles, mean_resp, sem_resp, '-o', 'LineWidth', 2, 'CapSize', 10);
            
            xlabel(sprintf('Orientation / Condition (%s)', colName));
            ylabel('Response Amplitude (uV)');
            title({sprintf('Tuning Curve (Avg %d Chans)', length(chans)), ...
                   sprintf('Window: %s', win_str)});
            grid on;
            
            % 如果是角度，可能需要极坐标展示 (Polar Plot)
            % 简单的启发式判断: 如果值在 [0, 360] 范围内且数量 > 4
            if all(u_angles >= 0 & u_angles <= 360) && length(u_angles) > 4
                 % 添加极坐标子图
                 % 注意: polarplot 需要弧度
                 rads = deg2rad(u_angles);
                 % 为了闭合曲线，添加第一个点到末尾
                 rads_cycle = [rads; rads(1)];
                 resp_cycle = [mean_resp; mean_resp(1)];
                 
                 figure('Color','w', 'Name', 'Polar Tuning');
                 polarplot(rads_cycle, resp_cycle, '-o', 'LineWidth', 2);
                 title('Polar Tuning Plot');
            end
        end
        % ============================================================
        % 6. 噪声去除 (Noise Removal)
        % ============================================================
        function remove_periodic_noise(obj, varargin)
            % REMOVE_PERIODIC_NOISE 去除特定频率的周期性噪声
            % 专为MUA等离散信号设计，使用频谱插值而非陷波滤波器
            %
            % 参数:
            %   'TargetFreq': 目标频率 (默认 100Hz)
            %   'Bandwidth':  带宽 (默认 2Hz)
            
            p = inputParser;
            addParameter(p, 'TargetFreq', 100, @isnumeric);
            addParameter(p, 'Bandwidth', 2, @isnumeric);
            parse(p, varargin{:});
            
            f0 = p.Results.TargetFreq;
            bw = p.Results.Bandwidth;
            
            fprintf('[QC] 正在去除 %.1f Hz 周期性噪声 (BW=%.1f Hz)...\n', f0, bw);
            
            % 调用 NeuroAlgo 中的算法
            % obj.Data is [nTrials, nCh, nTime]
            % remove_periodic_noise 支持 2D or 3D input
            
            try               
                obj.Data = NeuroAlgo.remove_periodic_noise(obj.Data, obj.Fs, f0, bw);
                fprintf('  [Done] 噪声去除完成。\n');
            catch ME
                fprintf('  [Error] 噪声去除失败: %s\n', ME.message);
            end
        end
    end
end
