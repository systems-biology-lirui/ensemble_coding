% Process_Event_SSGnv_MGnv_Strategies.m
% 逻辑：全 EVENT 数据处理
% 拟合：SSGnv (Basis) -> 拟合 -> MGnv (Target)
% 解码：Train on {MGnv, Fit, Res}, Test on {MGv}
% 策略：包含 3 种不同的时间窗口策略
function event_fitdecoding_pipeline_new()


% =========================================================================
% 1. 配置部分：定义猴子与时间窗口策略
% =========================================================================
macaque_list = {'DG', 'QQ_old', 'QQ_new'};
strategy_list = {'Strategy1', 'Strategy2', 'Strategy3'};

% 初始化策略配置结构体
StratConfig = struct();

% --- 策略 1 配置 (例如: Early / Onset) ---
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
% 临时文件放 Temp_Event 文件夹，防止覆盖
save_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\03_ResultData\Temp_Event\';
result_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Results\Figures\EVENTMGnv2MGv\';
if ~exist(save_path, 'dir'), mkdir(save_path); end

% =========================================================================
% 主循环：遍历猴子
% =========================================================================
for m_idx = 1:length(macaque_list)
    macaque = macaque_list{m_idx};

    fprintf('######################################################\n');
    fprintf('正在处理猴子: %s (%d/%d)\n', macaque, m_idx, length(macaque_list));
    fprintf('######################################################\n');

    %% Step 1: 加载并预处理 SSGnv (Basis)
    % 注意：数据加载不依赖于策略，因此放在外层循环
    clearvars -except macaque macaque_list m_idx base_path save_path result_path StratConfig strategy_list;

    fprintf('[Step 1] 正在加载 SSGnv (EVENT Basis)...\n');
    % 文件名假设为 SSGnv_EVENT
    data_ssgnv = load(fullfile(base_path, sprintf('%s_SSGnv_EVENT_MUA2_Epochs_Avg.mat',macaque)));
    meta_ssgnv = data_ssgnv.EpochDB.Meta;
    raw_ssgnv  = data_ssgnv.EpochDB.Data;
    clear data_ssgnv;
    [~, nChs, nTime] = size(raw_ssgnv);

    target_ori_list = 1:18;
    n_ori = 18; n_pat = 6; n_loc = 12;

    % 计算最小 Trial
    valid_counts = [];
    for o = 1:n_ori
        for p = 1:n_pat
            for l = 1:n_loc
                idx = find(meta_ssgnv.Location == l & meta_ssgnv.PicID == target_ori_list(o) & meta_ssgnv.Pattern == p);
                if ~isempty(idx), valid_counts(end+1) = length(idx); end
            end
        end
    end
    min_trials_ssgnv = min(valid_counts);
    fprintf('  SSGnv 最小 Trial: %d\n', min_trials_ssgnv);

    % 构建 SSGnv 矩阵
    Mat_SSGnv = zeros(n_loc, n_ori, n_pat, min_trials_ssgnv, nChs, nTime, 'single');
    idx1 = [];
    for l = 1:n_loc
        for o = 1:n_ori
            for p = 1:n_pat
                idx = find(meta_ssgnv.Location == l & meta_ssgnv.PicID == target_ori_list(o) & meta_ssgnv.Pattern == p);
                if isempty(idx), idx = idx1; end; idx1 = idx;
                Mat_SSGnv(l, o, p, :, :, :) = single(raw_ssgnv(idx(1:min_trials_ssgnv), :, :));
            end
        end
    end
    save(fullfile(save_path, 'Pre_SSGnv_Event.mat'), 'Mat_SSGnv', 'min_trials_ssgnv', '-v7.3');

    %% Step 2: 加载并预处理 MGnv (Target) 和 MGv (Test)
    clearvars -except macaque macaque_list m_idx base_path save_path result_path StratConfig strategy_list;

    fprintf('[Step 2] 正在加载 MGnv (Fit Target) 和 MGv (Test Data)...\n');
    % MGnv: EVENT B (用于被拟合)
    data_mgnv = load(fullfile(base_path, sprintf('%s_MGnv_EVENT_MUA2_Epochs_Avg.mat',macaque)));
    % MGv: EVENT A (用于做独立的测试集)
    data_mgv  = load(fullfile(base_path, sprintf('%s_MGv_EVENT_MUA2_Epochs_Avg.mat',macaque)));

    meta_mgnv = data_mgnv.EpochDB.Meta; raw_mgnv = data_mgnv.EpochDB.Data;
    meta_mgv  = data_mgv.EpochDB.Meta;  raw_mgv  = data_mgv.EpochDB.Data;
    clear data_mgnv data_mgv;

    [~, nChs_nv, nTime] = size(raw_mgnv);
    [~, nChs_v, ~] = size(raw_mgv);
    nChs = min(nChs_nv, nChs_v);
    target_ori_list = 1:18; n_ori = 18; n_pat = 6;

    % 计算最小 Trial
    cts_nv = []; cts_v = [];
    for o = 1:n_ori
        for p = 1:n_pat
            idx = find(meta_mgnv.PicID == target_ori_list(o) & meta_mgnv.Pattern == p);
            if ~isempty(idx), cts_nv(end+1) = length(idx); end
            idx = find(meta_mgv.PicID == target_ori_list(o) & meta_mgv.Pattern == p);
            if ~isempty(idx), cts_v(end+1) = length(idx); end
        end
    end
    min_trials_mgnv = min(cts_nv);
    min_trials_mgv  = min(cts_v);
    fprintf('  MGnv Trial: %d, MGv Trial: %d\n', min_trials_mgnv, min_trials_mgv);

    % 构建矩阵
    Mat_MGnv = zeros(n_ori, n_pat, min_trials_mgnv, nChs, nTime, 'single');
    Mat_MGv  = zeros(n_ori, n_pat, min_trials_mgv,  nChs, nTime, 'single');

    % MGnv (Target) - 带回退
    idx_1 = [];
    for o = 1:n_ori
        for p = 1:n_pat
            idx = find(meta_mgnv.PicID == target_ori_list(o) & meta_mgnv.Pattern == p);
            if isempty(idx), idx = idx_1; end; idx_1 = idx;
            Mat_MGnv(o, p, :, :, :) = single(raw_mgnv(idx(1:min_trials_mgnv), 1:nChs, :));
        end
    end

    % MGv (Test) - 不带回退 (测试集应保持真实)
    for o = 1:n_ori
        for p = 1:n_pat
            idx = find(meta_mgv.PicID == target_ori_list(o) & meta_mgv.Pattern == p);
            if ~isempty(idx)
                Mat_MGv(o, p, :, :, :) = single(raw_mgv(idx(1:min_trials_mgv), 1:nChs, :));
            end
        end
    end
    save(fullfile(save_path, 'Pre_MG_Event.mat'), 'Mat_MGnv', 'Mat_MGv', 'min_trials_mgnv', 'min_trials_mgv', '-v7.3');

    % =====================================================================
    % 策略循环：针对不同时间窗口进行拟合与解码
    % =====================================================================
    for s_idx = 1:length(strategy_list)
        curr_strat_name = strategy_list{s_idx};

        % 获取当前策略的时间窗口
        if isKey(StratConfig.(curr_strat_name), macaque)
            curr_time_segment = StratConfig.(curr_strat_name)(macaque);
        else
            error('配置错误：未找到 %s 的 %s 窗口', macaque, curr_strat_name);
        end

        fprintf('\n------------------------------------------------------\n');
        fprintf('执行策略: %s | 窗口: [%d, %d]\n', curr_strat_name, curr_time_segment(1), curr_time_segment(2));
        fprintf('------------------------------------------------------\n');

        %% Step 3: Fitting (SSGnv -> MGnv)
        % 不清除循环变量

        % 加载数据
        D_Basis  = load(fullfile(save_path, 'Pre_SSGnv_Event.mat'));
        D_Target = load(fullfile(save_path, 'Pre_MG_Event.mat'));

        % 对齐拟合用的 Trial (SSGnv 和 MGnv 需要一致)
        global_min = min([D_Basis.min_trials_ssgnv, D_Target.min_trials_mgnv]);

        Mat_SSGnv = D_Basis.Mat_SSGnv(:, :, :, 1:global_min, :, :);
        Mat_MGnv  = D_Target.Mat_MGnv(:, :, 1:global_min, :, :);
        Mat_MGv   = D_Target.Mat_MGv; % Test set

        clear D_Basis D_Target;

        [n_loc, n_ori, n_pat, n_trial, nChs, nTime] = size(Mat_SSGnv);
        Fit_Mat = zeros(n_ori, n_pat, n_trial, nChs, nTime, 'single');
        method = 'linear_unconstrained';

        % --- 逐 Trial 拟合 ---
        for o = 1:n_ori
            for p = 1:n_pat
                % Basis
                tmp_ssgnv = squeeze(Mat_SSGnv(:, o, p, :, :, :));
                Avg_SSGnv = squeeze(mean(tmp_ssgnv, 2));
                Basis_Input = permute(Avg_SSGnv, [2, 3, 1]);

                % Target
                tmp_mgnv = squeeze(Mat_MGnv(o, p, :, :, :));
                Target_Input_Mean = squeeze(mean(tmp_mgnv, 1));

                % Fitting (使用当前策略窗口)
                [~, W, ~] = trial_fitting(Target_Input_Mean, Basis_Input, method, curr_time_segment);

                Weights_Loc = W(:, 2:end);
                Bias = W(:, 1);

                % Reconstruct
                for ch = 1:nChs
                    data_ch = squeeze(tmp_ssgnv(:, :, ch, :));
                    w_ch = Weights_Loc(ch, :);
                    weighted_sum = zeros(n_trial, nTime, 'single');
                    for l = 1:n_loc
                        weighted_sum = weighted_sum + squeeze(data_ch(l, :, :)) * w_ch(l);
                    end
                    Fit_Mat(o, p, :, ch, :) = weighted_sum + Bias(ch);
                end
            end
        end

        Res_Mat = Mat_MGnv - Fit_Mat;

        % 保存结果 (带策略后缀)
        save(fullfile(result_path, sprintf('%s_Event_FitResults_%s.mat', macaque, curr_strat_name)), ...
            'Mat_MGnv', 'Mat_MGv', 'Fit_Mat', 'Res_Mat', '-v7.3');
        fprintf('  [Step 3] 拟合完成 (%s)\n', curr_strat_name);

        %% Step 4: Decoding on MGv

        fprintf('  [Step 4] 开始解码 (Train: MGnv/Fit/Res -> Test: MGv)\n');
        load('Yge_finalchannel.mat','sel_channel');
        channels = sel_channel.(sprintf('%s',macaque));

        options.do_permutation = false;
        options.n_shuffles = 5;
        options.n_repetitions = 5;
        options.k_fold = 5;
        options.time_smooth_win = 4;
        options.mode = 'cross_condition';

        [n_ori, n_pat, n_trial, n_ch, n_time] = size(Fit_Mat);
        [~, ~, n_trial_test, ~, ~] = size(Mat_MGv);

        DecodingResults = struct();

        % === Task 1: 18 Orientations ===
        target_ori_18 = 1:18;
        d_fit  = reshape(Fit_Mat(target_ori_18,:,:,:,:),   [18, n_pat*n_trial, n_ch, n_time]);
        d_res  = reshape(Res_Mat(target_ori_18,:,:,:,:),   [18, n_pat*n_trial, n_ch, n_time]);
        d_real = reshape(Mat_MGnv(target_ori_18,:,:,:,:),  [18, n_pat*n_trial, n_ch, n_time]);
        d_test = reshape(Mat_MGv(target_ori_18,:,:,:,:),   [18, n_pat*n_trial_test, n_ch, n_time]);

        DecodingResults.Ori18.Fit  = Master_Decoder(d_fit(:,:,channels,:),   d_test(:,:,channels,:), options);
        DecodingResults.Ori18.Res  = Master_Decoder(d_res(:,:,channels,:),   d_test(:,:,channels,:), options);
        DecodingResults.Ori18.Real = Master_Decoder(d_real(:,:,channels,:),  d_test(:,:,channels,:), options);

        % === Task 2: [1, 9] Orientations ===
        target_ori_19 = [1, 9];
        d_fit  = reshape(Fit_Mat(target_ori_19,:,:,:,:),   [2, n_pat*n_trial, n_ch, n_time]);
        d_res  = reshape(Res_Mat(target_ori_19,:,:,:,:),   [2, n_pat*n_trial, n_ch, n_time]);
        d_real = reshape(Mat_MGnv(target_ori_19,:,:,:,:),  [2, n_pat*n_trial, n_ch, n_time]);
        d_test = reshape(Mat_MGv(target_ori_19,:,:,:,:),   [2, n_pat*n_trial_test, n_ch, n_time]);

        DecodingResults.Ori19.Fit  = Master_Decoder(d_fit(:,:,channels,:),   d_test(:,:,channels,:), options);
        DecodingResults.Ori19.Res  = Master_Decoder(d_res(:,:,channels,:),   d_test(:,:,channels,:), options);
        DecodingResults.Ori19.Real = Master_Decoder(d_real(:,:,channels,:),  d_test(:,:,channels,:), options);

        % === 保存与绘图 ===
        save(fullfile(result_path, sprintf('%s_Event_Decoding_Results_%s.mat', macaque, curr_strat_name)), 'DecodingResults');

        figure('Name', sprintf('%s - %s', macaque, curr_strat_name), 'NumberTitle', 'off', 'Position', [100, 100, 1000, 400]);

        subplot(1, 2, 1); hold on;
        plot(DecodingResults.Ori18.Fit.acc_real_mean, 'r', 'LineWidth', 1.5);
        plot(DecodingResults.Ori18.Res.acc_real_mean, 'b', 'LineWidth', 1.5);
        plot(DecodingResults.Ori18.Real.acc_real_mean, 'k', 'LineWidth', 1.5);
        title(sprintf('Task: 18 Ori (%s)', curr_strat_name));
        legend('Fit','Res','Real(MGnv)'); grid on;

        subplot(1, 2, 2); hold on;
        plot(DecodingResults.Ori19.Fit.acc_real_mean, 'r', 'LineWidth', 1.5);
        plot(DecodingResults.Ori19.Res.acc_real_mean, 'b', 'LineWidth', 1.5);
        plot(DecodingResults.Ori19.Real.acc_real_mean, 'k', 'LineWidth', 1.5);
        title(sprintf('Task: 1 vs 9 (%s)', curr_strat_name)); grid on;

        saveas(gcf, fullfile(result_path, sprintf('%s_Event_Decoding_Plot_%s.png', macaque, curr_strat_name)));

        fprintf('  [Step 4] 解码完成 (%s)\n', curr_strat_name);

    end % 结束策略循环

end % 结束猴子循环

fprintf('所有 Event 处理任务完成！\n');
end