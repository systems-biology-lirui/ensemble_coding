% Process_SSVEP_SSGv_MGv_Strategies.m
% 逻辑：SSVEP 数据处理 (SSGv -> 拟合 -> MGv_SSVEP_B)
% 策略：包含 3 种不同的拟合时间窗口策略
% 解码测试：分别测试在 SSVEP_A (同分布) 和 EVENT (跨状态) 上的表现
function ssvepb_fitdecoding_pipeline_new()
% 在第一行加上 function 声明，函数名与文件名一致


% =========================================================================
% 1. 配置部分：定义猴子与时间窗口策略
% =========================================================================
macaque_list = {'DG', 'QQ_old', 'QQ_new'};
strategy_list = {'Strategy1', 'Strategy2', 'Strategy3'};

% 初始化策略配置结构体
StratConfig = struct();

% === 策略 1 配置 (全长) ===
StratConfig.Strategy1 = containers.Map();
StratConfig.Strategy1('DG')     = [30, 100];
StratConfig.Strategy1('QQ_old') = [30, 100];
StratConfig.Strategy1('QQ_new') = [30, 100];

% === 策略 2 配置 (峰值40点) ===
StratConfig.Strategy2 = containers.Map();
StratConfig.Strategy2('DG')     = [40, 80];
StratConfig.Strategy2('QQ_old') = [40, 80];
StratConfig.Strategy2('QQ_new') = [40, 80];

% === 策略 3 配置 (固定40点) ===
StratConfig.Strategy3 = containers.Map();
StratConfig.Strategy3('DG')     = [40, 60];
StratConfig.Strategy3('QQ_old') = [40, 60];
StratConfig.Strategy3('QQ_new') = [40, 60];

% 路径设置
base_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\02_EpochDatabase\';
save_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\03_ResultData\Temp_SSVEP\'; % 临时文件夹
result_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Results\Figures\SSVEP_B2EVENT\';
if ~exist(save_path, 'dir'), mkdir(save_path); end

% =========================================================================
% 主循环：遍历猴子
% =========================================================================
for m_idx = 1:length(macaque_list)
    macaque = macaque_list{m_idx};

    fprintf('######################################################\n');
    fprintf('正在处理猴子: %s (%d/%d)\n', macaque, m_idx, length(macaque_list));
    fprintf('######################################################\n');

    %% Step 1: 加载并预处理 SSGv (SSVEP Basis)
    % 数据加载独立于策略
    clearvars -except macaque macaque_list m_idx base_path save_path result_path StratConfig strategy_list;

    fprintf('[Step 1] 正在加载 SSGv (SSVEP Basis)...\n');
    data_ssgv = load(fullfile(base_path, sprintf('%s_SSGv_SSVEP_B_MUA2_Epochs_Avg.mat',macaque)));
    meta_ssgv = data_ssgv.EpochDB.Meta;
    raw_ssgv  = data_ssgv.EpochDB.Data;
    clear data_ssgv;
    [~, nChs, nTime] = size(raw_ssgv);

    target_ori_list = 1:18;
    n_ori = 18; n_pat = 6; n_loc = 12;

    % 计算 SSGv 最小 Trial
    valid_counts = [];
    for o = 1:n_ori
        for p = 1:n_pat
            for l = 1:n_loc
                idx = find(meta_ssgv.Location == l & meta_ssgv.PicID == target_ori_list(o) & meta_ssgv.Pattern == p);
                if ~isempty(idx), valid_counts(end+1) = length(idx); end
            end
        end
    end
    min_trials_ssgv = min(valid_counts);

    % 构建 SSGv 矩阵
    Mat_SSGv = zeros(n_loc, n_ori, n_pat, min_trials_ssgv, nChs, nTime, 'single');
    idx1 = [];
    for l = 1:n_loc
        for o = 1:n_ori
            for p = 1:n_pat
                idx = find(meta_ssgv.Location == l & meta_ssgv.PicID == target_ori_list(o) & meta_ssgv.Pattern == p);
                if isempty(idx), idx = idx1; end; idx1 = idx;
                Mat_SSGv(l, o, p, :, :, :) = single(raw_ssgv(idx(1:min_trials_ssgv), :, :));
            end
        end
    end
    save(fullfile(save_path, 'Preprocessed_SSGv_single.mat'), 'Mat_SSGv', 'min_trials_ssgv', '-v7.3');
    fprintf('  Step 1 完成: SSGv 已保存。\n');

    %% Step 2: 加载并预处理 MGv (SSVEP & EVENT)
    clearvars -except macaque macaque_list m_idx base_path save_path result_path StratConfig strategy_list;

    fprintf('[Step 2] 正在加载 MGv 数据 (SSVEP & EVENT)...\n');
    % SSVEP B (Target for Fitting)
    data_b = load(fullfile(base_path, sprintf('%s_MGv_SSVEP_B_MUA2_Epochs_Avg.mat',macaque)));
    % SSVEP A (Test Set 1)
    data_a = load(fullfile(base_path, sprintf('%s_MGv_SSVEP_A_MUA2_Epochs_Avg.mat',macaque)));
    % EVENT A (Test Set 2)
    data_evt = load(fullfile(base_path, sprintf('%s_MGv_EVENT_MUA2_Epochs_Avg.mat',macaque)));

    meta_b = data_b.EpochDB.Meta; raw_b = data_b.EpochDB.Data;
    meta_a = data_a.EpochDB.Meta; raw_a = data_a.EpochDB.Data;
    meta_e = data_evt.EpochDB.Meta; raw_e = data_evt.EpochDB.Data;
    clear data_b data_a data_evt;

    [~, nChs_b, nTime] = size(raw_b);
    [~, nChs_a, ~] = size(raw_a);
    [~, nChs_e, nTime_evt] = size(raw_e);
    nChs = min([nChs_a, nChs_b, nChs_e]);
    target_ori_list = 1:18; n_ori = 18; n_pat = 6;

    % 计算最小 Trial 数
    cts_b = []; cts_a = []; cts_e = [];
    for o = 1:n_ori
        for p = 1:n_pat
            idx = find(meta_b.PicID == target_ori_list(o) & meta_b.Pattern == p);
            if ~isempty(idx), cts_b(end+1) = length(idx); end

            idx = find(meta_a.PicID == target_ori_list(o) & meta_a.Pattern == p);
            if ~isempty(idx), cts_a(end+1) = length(idx); end

            idx = find(meta_e.PicID == target_ori_list(o) & meta_e.Pattern == p);
            if ~isempty(idx), cts_e(end+1) = length(idx); end
        end
    end
    min_trials_b = min(cts_b);
    min_trials_a = min(cts_a);
    min_trials_e = min(cts_e);

    fprintf('  MGv Trials -> SSVEP_B:%d, SSVEP_A:%d, EVENT:%d\n', min_trials_b, min_trials_a, min_trials_e);

    % 构建矩阵
    Mat_MGv_SSVEP_B = zeros(n_ori, n_pat, min_trials_b, nChs, nTime, 'single');
    Mat_MGv_SSVEP_A = zeros(n_ori, n_pat, min_trials_a, nChs, nTime, 'single');
    Mat_MGv_EVENT = zeros(n_ori, n_pat, min_trials_e, nChs, nTime_evt, 'single');

    idx_b1 = [];
    for o = 1:n_ori
        for p = 1:n_pat
            % SSVEP B (拟合目标，需回退)
            idx = find(meta_b.PicID == target_ori_list(o) & meta_b.Pattern == p);
            if isempty(idx), idx = idx_b1; end; idx_b1 = idx;
            Mat_MGv_SSVEP_B(o, p, :, :, :) = single(raw_b(idx(1:min_trials_b), 1:nChs, :));

            % SSVEP A (Test 1，无需回退)
            idx = find(meta_a.PicID == target_ori_list(o) & meta_a.Pattern == p);
            if ~isempty(idx)
                Mat_MGv_SSVEP_A(o, p, :, :, :) = single(raw_a(idx(1:min_trials_a), 1:nChs, :));
            end

            % EVENT A (Test 2，无需回退)
            idx = find(meta_e.PicID == target_ori_list(o) & meta_e.Pattern == p);
            if ~isempty(idx)
                Mat_MGv_EVENT(o, p, :, :, :) = single(raw_e(idx(1:min_trials_e), 1:nChs, :));
            end
        end
    end
    save(fullfile(save_path, 'Preprocessed_MGv_single.mat'), ...
        'Mat_MGv_SSVEP_B', 'Mat_MGv_SSVEP_A', 'Mat_MGv_EVENT', ...
        'min_trials_b', 'min_trials_a', 'min_trials_e', '-v7.3');
    fprintf('  Step 2 完成: MGv 已保存。\n');

    % =====================================================================
    % 策略循环：拟合与解码
    % =====================================================================
    for s_idx = 1:length(strategy_list)
        curr_strat_name = strategy_list{s_idx};

        if isKey(StratConfig.(curr_strat_name), macaque)
            curr_time_segment = StratConfig.(curr_strat_name)(macaque);
        else
            error('配置错误：未找到 %s 的 %s 窗口', macaque, curr_strat_name);
        end

        fprintf('\n------------------------------------------------------\n');
        fprintf('执行策略: %s | 窗口: [%d, %d]\n', curr_strat_name, curr_time_segment(1), curr_time_segment(2));
        fprintf('------------------------------------------------------\n');

        %% Step 3: Fitting (SSGnv -> MGnv_B using Strategy Window)
        % 不清除循环变量

        % 加载数据
        D_SSGv = load(fullfile(save_path, 'Preprocessed_SSGv_single.mat'));
        D_MGv  = load(fullfile(save_path, 'Preprocessed_MGv_single.mat'));

        % 对齐拟合用的 Trial (SSGv 和 MGv_B)
        global_min = min([D_SSGv.min_trials_ssgv, D_MGv.min_trials_b]);
        Mat_SSGv  = D_SSGv.Mat_SSGv(:, :, :, 1:global_min, :, :);
        Mat_MGv_B = D_MGv.Mat_MGv_SSVEP_B(:, :, 1:global_min, :, :);

        % Test Data
        Mat_MGv_A_SSVEP = D_MGv.Mat_MGv_SSVEP_A;
        Mat_MGv_A_EVENT = D_MGv.Mat_MGv_EVENT;
        clear D_SSGv D_MGv;

        [n_loc, n_ori, n_pat, n_trial, nChs, nTime] = size(Mat_SSGv);
        Fit_Mat = zeros(n_ori, n_pat, n_trial, nChs, nTime, 'single');
        method = 'linear_unconstrained';

        % --- 逐 Trial 拟合 ---
        for o = 1:n_ori
            for p = 1:n_pat
                tmp_ssgv = squeeze(Mat_SSGv(:, o, p, :, :, :));
                Avg_SSGv = squeeze(mean(tmp_ssgv, 2));
                Basis_Input = permute(Avg_SSGv, [2, 3, 1]);

                tmp_mgv_b = squeeze(Mat_MGv_B(o, p, :, :, :));
                Target_Input_Mean = squeeze(mean(tmp_mgv_b, 1));

                % 使用当前策略窗口
                [~, W, ~] = trial_fitting(Target_Input_Mean, Basis_Input, method, curr_time_segment);

                Weights_Loc = W(:, 2:end);
                Bias = W(:, 1);

                for ch = 1:nChs
                    data_ch = squeeze(tmp_ssgv(:, :, ch, :));
                    w_ch = Weights_Loc(ch, :);
                    weighted_sum = zeros(n_trial, nTime, 'single');
                    for l = 1:n_loc
                        weighted_sum = weighted_sum + squeeze(data_ch(l, :, :)) * w_ch(l);
                    end
                    Fit_Mat(o, p, :, ch, :) = weighted_sum + Bias(ch);
                end
            end
        end

        % 计算残差 (基于 SSVEP_B)
        Res_Mat_SSVEP = Mat_MGv_B - Fit_Mat;

        % 保存拟合结果
        save(fullfile(result_path, sprintf('%s_SSVEP_FitResults_%s.mat', macaque, curr_strat_name)), ...
            'Mat_MGv_A_SSVEP', 'Mat_MGv_A_EVENT', 'Mat_MGv_B', 'Fit_Mat', 'Res_Mat_SSVEP', '-v7.3');
        fprintf('  [Step 3] 拟合完成 (%s)\n', curr_strat_name);

        %% Step 6: Decoding (Test on SSVEP & EVENT)

        fprintf('  [Step 6] 开始解码 (Test Types: SSVEP, EVENT)\n');
        load('Yge_finalchannel.mat','sel_channel');
        channels = sel_channel.(sprintf('%s',macaque));


        options.do_permutation = false;
        options.n_shuffles = 5;
        options.n_repetitions = 5;
        options.k_fold = 5;
        options.time_smooth_win = 2;
        options.mode = 'cross_condition';

        [n_ori, n_pat, n_trial, n_ch, n_time] = size(Fit_Mat);
        DecodingResults = struct();

        % 定义两种测试模式
        test_types = {'SSVEP', 'EVENT'};

        for t_idx = 1:length(test_types)
            curr_type = test_types{t_idx};

            % 确定测试数据 (Ground Truth)
            if strcmp(curr_type, 'SSVEP')
                Real_Test_Data = Mat_MGv_A_SSVEP;
            else
                Real_Test_Data = Mat_MGv_A_EVENT;
            end

            [~, ~, n_trial_test, ~, n_time_test] = size(Real_Test_Data);

            % --- Task 1: 18 Orientations ---
            target_ori_18 = 1:18;
            d_fit  = reshape(Fit_Mat(target_ori_18,:,:,:,:),       [18, n_pat*n_trial, n_ch, n_time]);
            d_res  = reshape(Res_Mat_SSVEP(target_ori_18,:,:,:,:), [18, n_pat*n_trial, n_ch, n_time]);
            d_real = reshape(Mat_MGv_B(target_ori_18,:,:,:,:),     [18, n_pat*n_trial, n_ch, n_time]);
            d_test = reshape(Real_Test_Data(target_ori_18,:,:,:,:),[18, n_pat*n_trial_test, n_ch, n_time_test]);

            DecodingResults.(curr_type).Ori18.Fit  = Master_Decoder(d_fit(:,:,channels,:),   d_test(:,:,channels,:), options);
            DecodingResults.(curr_type).Ori18.Res  = Master_Decoder(d_res(:,:,channels,:),   d_test(:,:,channels,:), options);
            DecodingResults.(curr_type).Ori18.Real = Master_Decoder(d_real(:,:,channels,:),  d_test(:,:,channels,:), options);

            % --- Task 2: [1, 9] Orientations ---
            target_ori_19 = [1, 9];
            d_fit  = reshape(Fit_Mat(target_ori_19,:,:,:,:),       [2, n_pat*n_trial, n_ch, n_time]);
            d_res  = reshape(Res_Mat_SSVEP(target_ori_19,:,:,:,:), [2, n_pat*n_trial, n_ch, n_time]);
            d_real = reshape(Mat_MGv_B(target_ori_19,:,:,:,:),     [2, n_pat*n_trial, n_ch, n_time]);
            d_test = reshape(Real_Test_Data(target_ori_19,:,:,:,:),[2, n_pat*n_trial_test, n_ch, n_time_test]);

            DecodingResults.(curr_type).Ori19.Fit  = Master_Decoder(d_fit(:,:,channels,:),   d_test(:,:,channels,:), options);
            DecodingResults.(curr_type).Ori19.Res  = Master_Decoder(d_res(:,:,channels,:),   d_test(:,:,channels,:), options);
            DecodingResults.(curr_type).Ori19.Real = Master_Decoder(d_real(:,:,channels,:),  d_test(:,:,channels,:), options);

            % --- Task 3: Pattern Decoding ---
            acc_fit_sum = 0; acc_res_sum = 0; acc_real_sum = 0;
            for o = 1:18
                d_fit_sl = squeeze(Fit_Mat(o, :, :, channels, :));
                d_res_sl = squeeze(Res_Mat_SSVEP(o, :, :, channels, :));
                d_real_sl = squeeze(Mat_MGv_B(o, :, :, channels, :));
                d_test_sl = squeeze(Real_Test_Data(o, :, :, channels, :));

                res_fit = Master_Decoder(d_fit_sl, d_test_sl, options);
                res_res = Master_Decoder(d_res_sl, d_test_sl, options);
                res_real = Master_Decoder(d_real_sl, d_test_sl, options);

                acc_fit_sum = acc_fit_sum + res_fit.acc_real_mean;
                acc_res_sum = acc_res_sum + res_res.acc_real_mean;
                acc_real_sum = acc_real_sum + res_real.acc_real_mean;
            end
            DecodingResults.(curr_type).Pattern.Fit_Avg  = acc_fit_sum / 18;
            DecodingResults.(curr_type).Pattern.Res_Avg  = acc_res_sum / 18;
            DecodingResults.(curr_type).Pattern.Real_Avg = acc_real_sum / 18;
        end

        % === 保存与绘图 ===
        save(fullfile(result_path, sprintf('%s_SSVEP_Decoding_Results_%s.mat', macaque, curr_strat_name)), 'DecodingResults');

        figure('Name', sprintf('%s SSVEP - %s', macaque, curr_strat_name), 'NumberTitle', 'off', 'Position', [100, 100, 1200, 800]);

        types_plot = {'SSVEP', 'EVENT'};
        for i = 1:2
            ctype = types_plot{i};
            base_idx = (i-1)*3;

            % Task 1
            subplot(2, 3, base_idx+1); hold on;
            plot(DecodingResults.(ctype).Ori18.Fit.acc_real_mean, 'r', 'LineWidth', 1.5);
            plot(DecodingResults.(ctype).Ori18.Res.acc_real_mean, 'b', 'LineWidth', 1.5);
            plot(DecodingResults.(ctype).Ori18.Real.acc_real_mean, 'k', 'LineWidth', 1.5);
            title(sprintf('[%s] 18 Ori', ctype)); legend('Fit','Res','Real'); grid on;

            % Task 2
            subplot(2, 3, base_idx+2); hold on;
            plot(DecodingResults.(ctype).Ori19.Fit.acc_real_mean, 'r', 'LineWidth', 1.5);
            plot(DecodingResults.(ctype).Ori19.Res.acc_real_mean, 'b', 'LineWidth', 1.5);
            plot(DecodingResults.(ctype).Ori19.Real.acc_real_mean, 'k', 'LineWidth', 1.5);
            title(sprintf('[%s] Ori [1,9]', ctype)); grid on;

            % Task 3
            subplot(2, 3, base_idx+3); hold on;
            plot(DecodingResults.(ctype).Pattern.Fit_Avg, 'r', 'LineWidth', 1.5);
            plot(DecodingResults.(ctype).Pattern.Res_Avg, 'b', 'LineWidth', 1.5);
            plot(DecodingResults.(ctype).Pattern.Real_Avg, 'k', 'LineWidth', 1.5);
            title(sprintf('[%s] Pattern (Avg)', ctype)); grid on;
        end

        saveas(gcf, fullfile(result_path, sprintf('%s_SSVEP_Decoding_Plot_%s.png', macaque, curr_strat_name)));

        fprintf('  [Step 6] 解码完成 (%s)\n', curr_strat_name);

    end % 结束策略循环

end % 结束猴子循环

fprintf('所有 SSVEP 处理任务完成！\n');
end