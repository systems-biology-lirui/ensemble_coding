function SSVEP_A_decoding_MGv_pipeline_new()
% SSVEP_A_decoding_MGv_Refactored
% 功能：对 SSVEP_A 数据进行纯解码分析 (18朝向, [1,9]朝向, Pattern)
% 更新：增加自动绘图与保存图片功能

    % clear; clc; %以此方式注释，便于被主程序调用

    %% 1. 参数配置 (Configuration)
    base_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\02_EpochDatabase\';
    
    % 结果与图片保存路径
    save_dir  = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Results\Figures\SSVEP_A_decoding\';
    if ~exist(save_dir, 'dir'), mkdir(save_dir); end

    macaques = {'DG', 'QQ_new', 'QQ_old'};
    labels   = {'MGv'};

    % 加载通道选择
    load('Yge_finalchannel.mat', 'sel_channel');

    % 解码器参数
    options.do_permutation = false;
    options.n_shuffles     = 5;
    options.n_repetitions  = 5; % 重复次数，用于计算误差棒或平均线
    options.k_fold         = 5;
    options.time_smooth_win = 2;
    options.mode           = 'temporal';

    % 数据参数
    target_ori_list = 1:18;
    n_ori = length(target_ori_list);
    n_pat = 6;

    %% 2. 初始化结果容器 (Initialization)
    result_18ori_plot   = cell(length(macaques), length(labels));
    result_2ori_plot    = cell(length(macaques), length(labels));
    result_pattern_plot = cell(length(macaques), length(labels));

    %% 3. 主循环 (Main Loop)
    for m = 1:length(macaques)
        monkey_name = macaques{m};
        
        % 获取当前猴子的通道
        if isfield(sel_channel, monkey_name)
            curr_channels = sel_channel.(monkey_name);
        else
            warning('未找到猴子 %s 的通道数据，使用所有通道', monkey_name);
            curr_channels = []; 
        end
        
        for l = 1:length(labels)
            label_name = labels{l};
            fprintf('==================================================\n');
            fprintf('正在处理: %s - %s\n', monkey_name, label_name);
            
            % --- 加载数据 ---
            file_path = fullfile(base_path, sprintf('%s_%s_SSVEP_A_MUA2_Epochs_Avg.mat', monkey_name, label_name));
            if ~exist(file_path, 'file')
                warning('文件不存在: %s', file_path);
                continue;
            end
            data = load(file_path);
            
            % --- 构建 5D 矩阵 ---
            % Mat_5D: [nOri, nPat, nTrial, nCh, nTime]
            [Mat_5D, ~] = NeuroTool.build_5d_matrix(data.EpochDB, n_ori, n_pat, target_ori_list);
            [nOri, nPat, nTrial, nCh, nTime] = size(Mat_5D);
            
            % =========================================================
            % Task 1: 18 Orientations Decoding
            % =========================================================
            fprintf('  >> Decoding Task 1: 18 Orientations...\n');
            Data_18 = reshape(Mat_5D, [nOri, nPat*nTrial, nCh, nTime]);
            res_18 = Master_Decoder(Data_18(:, :, curr_channels, :), [], options);
            
            % 提取 Accuracy (Mean over folds/reps usually handled by Master_Decoder output, but here we extract details)
            % 这里的 acc 维度通常是 [1, n_repetitions, n_time]
            acc_18_raw = reshape(cat(2, res_18.detailed.real_acc_dist{:}), [1, options.n_repetitions, length(res_18.acc_real_mean)]);
            shuffle_18_raw = cat(2, res_18.detailed.perm_acc_dist{:});
            
            result_18ori_plot{m,l}.acc = acc_18_raw;
            result_18ori_plot{m,l}.shufflechance = shuffle_18_raw;
            result_18ori_plot{m,l}.p = res_18.p_value;
            
            % =========================================================
            % Task 2: 2 Orientations [1, 9] Decoding
            % =========================================================
            fprintf('  >> Decoding Task 2: [1, 9] Orientations...\n');
            target_idx_2 = [1, 9];
            Mat_2 = Mat_5D(target_idx_2, :, :, :, :);
            Data_2 = reshape(Mat_2, [2, nPat*nTrial, nCh, nTime]);
            res_2 = Master_Decoder(Data_2(:, :, curr_channels, :), [], options);
            
            acc_2_raw = reshape(cat(2, res_2.detailed.real_acc_dist{:}), [1, options.n_repetitions, length(res_2.acc_real_mean)]);
            shuffle_2_raw = cat(2, res_2.detailed.perm_acc_dist{:});
            
            result_2ori_plot{m,l}.acc = acc_2_raw;
            result_2ori_plot{m,l}.shufflechance = shuffle_2_raw;
            result_2ori_plot{m,l}.p = res_2.p_value;
            
            % =========================================================
            % Task 3: Pattern Decoding (Per Orientation)
            % =========================================================
            fprintf('  >> Decoding Task 3: Pattern (Per Ori)...\n');
            temp_acc = [];
            temp_shuffle = [];
            
            for ori = 1:nOri
                % Input: [nPat, nTrial, nCh, nTime]
                Data_Pat = squeeze(Mat_5D(ori, :, :, :, :)); 
                res_pat = Master_Decoder(Data_Pat(:, :, curr_channels, :), [], options);
                
                temp_acc(ori, :, :) = cat(2, res_pat.detailed.real_acc_dist{:});
                temp_shuffle(ori, :, :) = cat(2, res_pat.detailed.perm_acc_dist{:});
            end
            
            result_pattern_plot{m,l}.acc = temp_acc;
            result_pattern_plot{m,l}.shufflechance = temp_shuffle;
            
            % =========================================================
            % 绘图与保存 (Plotting)
            % =========================================================
            fprintf('  >> 正在绘图...\n');
            h_fig = figure('Name', sprintf('%s - %s Decoding', monkey_name, label_name), ...
                'NumberTitle', 'off', 'Position', [100, 100, 1200, 400], 'Visible', 'off'); % Visible off 避免弹窗干扰
            
            % --- Subplot 1: 18 Ori ---
            subplot(1, 3, 1); hold on;
            mean_acc = squeeze(mean(acc_18_raw, 2)); % Average over reps
            mean_shuff = squeeze(mean(shuffle_18_raw, 1)); % Average over permutations
            plot(mean_acc, 'r', 'LineWidth', 1.5);
            plot(mean_shuff, 'k--', 'LineWidth', 1);
            title('Task 1: 18 Orientations');
            xlabel('Time Points'); ylabel('Accuracy');
            legend('Real', 'Chance'); grid on; ylim([0 1]);
            
            % --- Subplot 2: [1, 9] Ori ---
            subplot(1, 3, 2); hold on;
            mean_acc = squeeze(mean(acc_2_raw, 2));
            mean_shuff = squeeze(mean(shuffle_2_raw, 1));
            plot(mean_acc, 'r', 'LineWidth', 1.5);
            plot(mean_shuff, 'k--', 'LineWidth', 1);
            title('Task 2: Ori [1 vs 9]');
            xlabel('Time Points'); grid on; ylim([0 1]);
            
            % --- Subplot 3: Pattern (Average over all Oris) ---
            subplot(1, 3, 3); hold on;
            % temp_acc: [18, n_reps, n_time]
            % Step 1: Mean over repetitions -> [18, n_time]
            pat_reps_mean = squeeze(mean(temp_acc, 2)); 
            % Step 2: Mean over orientations -> [1, n_time]
            pat_total_mean = mean(pat_reps_mean, 1);
            
            % Shuffle similar logic
            shuff_reps_mean = squeeze(mean(temp_shuffle, 2)); % Assuming shuffle structure matches
            shuff_total_mean = mean(shuff_reps_mean, 1);
            
            plot(pat_total_mean, 'r', 'LineWidth', 1.5);
            plot(shuff_total_mean, 'k--', 'LineWidth', 1);
            title('Task 3: Pattern (Avg over 18 Ori)');
            xlabel('Time Points'); grid on; ylim([0 1]);
            
            % 保存图片
            img_filename = sprintf('%s_%s_Decoding_Perf.png', monkey_name, label_name);
            saveas(h_fig, fullfile(save_dir, img_filename));
            close(h_fig); % 关闭图像以释放内存
            
        end
    end

    %% 4. 保存数据结果 (Save Data)
    save_file = fullfile(save_dir, 'SSVEP_A_decoding_MGv.mat');
    fprintf('保存数据结果至: %s\n', save_file);
    save(save_file, 'result_pattern_plot', 'result_2ori_plot', 'result_18ori_plot');
    fprintf('完成。\n');
end

%% Local Functions (辅助函数)

function [Mat_5D, min_trials] = build_5d_matrix(EpochDB, n_ori, n_pat, target_ori_list)
    % 辅助函数：构建 5D 矩阵 [nOri, nPat, nTrial, nCh, nTime]
    Meta = EpochDB.Meta;
    Data = EpochDB.Data;
    [~, nCh, nTime] = size(Data);
    
    counts = [];
    for o = 1:n_ori
        for p = 1:n_pat
            idx = find(Meta.PicID == target_ori_list(o) & Meta.Pattern == p);
            if ~isempty(idx)
                counts(end+1) = length(idx);
            end
        end
    end
    
    if isempty(counts)
        error('未找到符合条件的数据');
    end
    min_trials = min(counts);
    
    Mat_5D = zeros(n_ori, n_pat, min_trials, nCh, nTime, 'single');
    
    idx_fallback = [];
    for o = 1:n_ori
        for p = 1:n_pat
            idx = find(Meta.PicID == target_ori_list(o) & Meta.Pattern == p);
            if isempty(idx)
                if isempty(idx_fallback)
                    warning('数据存在空缺且无法回退，请检查原始数据完整性');
                    continue; 
                end
                idx = idx_fallback;
            else
                idx_fallback = idx;
            end
            curr_data = Data(idx(1:min_trials), :, :);
            Mat_5D(o, p, :, :, :) = single(curr_data);
        end
    end
end