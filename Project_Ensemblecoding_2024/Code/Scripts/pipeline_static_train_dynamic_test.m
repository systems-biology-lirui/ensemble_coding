function pipeline_static_train_dynamic_test()
% Pipeline: Static Train -> Dynamic Test
% 
% Task 1: Train on SG Event (Avg 20-40ms), Test on SSVEP_B Fit/Res/Real.
% Task 2: Train on MGv SSVEP_A (Avg 40-60ms), Test on SSVEP_B Fit/Res/Real.

    %% 1. Configuration
    base_path_db = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\02_EpochDatabase\';
    base_path_fit = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Results\Figures\SSVEP_B2EVENT\';
    save_dir = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Results\Figures\StaticTrain_DynamicTest\';
    
    if ~exist(save_dir, 'dir'), mkdir(save_dir); end

    macaques = {'DG', 'QQ_new', 'QQ_old'};
    strategies = {'Strategy1', 'Strategy2', 'Strategy3'}; 

    % Decoding Parameters
    options.do_permutation = false;
    options.n_shuffles     = 5;
    options.n_repetitions  = 5;
    options.k_fold         = 5;
    options.time_smooth_win = 2; % For dynamic test data smoothing
    options.mode           = 'static_train_dynamic_test'; 

    % Load Channel Selection
    if exist('Yge_finalchannel.mat', 'file')
        load('Yge_finalchannel.mat', 'sel_channel');
    else
        warning('Yge_finalchannel.mat not found. Will use all channels.');
        sel_channel = struct();
    end

    target_ori_list = 1:18;
    n_ori = 18;
    n_pat = 6;

    %% 2. Main Loop
    for m = 1:length(macaques)
        monkey_name = macaques{m};
        
        % Get Channels
        if isfield(sel_channel, monkey_name)
            curr_channels = sel_channel.(monkey_name);
        else
            curr_channels = []; 
        end
        
        fprintf('==================================================\n');
        fprintf('Processing Monkey: %s\n', monkey_name);

        % =========================================================
        % Data Loading & Preparation
        % =========================================================
        
        % --- Load SG Data (Task 1 Source) ---
        sg_file = fullfile(base_path_db, sprintf('%s_SG_EVENT_MUA2_Epochs_Avg.mat', monkey_name));
        if exist(sg_file, 'file')
            d_sg = load(sg_file);
            [Mat_SG, ~] = NeuroTool.build_5d_matrix(d_sg.EpochDB, n_ori, n_pat, target_ori_list);
            % Mat_SG: [nOri, nPat, nTrial, nCh, nTime]
            
            % Average 20-40ms (indices) - Assuming 1ms/sample or check Fs
            % Usually indices match ms if Fs=1000. Assuming indices 20:40.
            % Check actual time vector if available, but assuming indices for now as per request.
            idx_win_sg = 20:40; 
            
            % Average over time -> [nOri, nPat, nTrial, nCh, 1]
            Mat_SG_Avg = mean(Mat_SG(:, :, :, :, idx_win_sg), 5);
        else
            warning('SG file missing: %s', sg_file);
            Mat_SG_Avg = [];
        end

        % --- Load MGv SSVEP_A Data (Task 2 Source) ---
        mgv_a_file = fullfile(base_path_db, sprintf('%s_MGv_SSVEP_A_MUA2_Epochs_Avg.mat', monkey_name));
        if exist(mgv_a_file, 'file')
            d_mgv_a = load(mgv_a_file);
            [Mat_MGv_A, ~] = NeuroTool.build_5d_matrix(d_mgv_a.EpochDB, n_ori, n_pat, target_ori_list);
            
            % Average 40-60ms
            idx_win_mgva = 40:60;
            Mat_MGv_A_Avg = mean(Mat_MGv_A(:, :, :, :, idx_win_mgva), 5);
        else
            warning('MGv_A file missing: %s', mgv_a_file);
            Mat_MGv_A_Avg = [];
        end


        % =========================================================
        % Iterate Strategies (SSVEP_B Targets)
        % =========================================================
        for s = 1:length(strategies)
            strat_name = strategies{s};
            fprintf('  -- Strategy: %s\n', strat_name);
            
            fit_file = fullfile(base_path_fit, sprintf('%s_SSVEP_FitResults_%s.mat', monkey_name, strat_name));
            if ~exist(fit_file, 'file')
                warning('Fit File not found: %s', fit_file);
                continue;
            end
            
            Data_Fit = load(fit_file);
            
            Test_Sets = struct();
            Test_Sets.Fit  = Data_Fit.Fit_Mat;
            Test_Sets.Res  = Data_Fit.Res_Mat_SSVEP;
            Test_Sets.Real = Data_Fit.Mat_MGv_B;
            
            types = fieldnames(Test_Sets);
            DecodingResults = struct();
            
            % Loop over Test Types (Fit, Res, Real)
            for t = 1:length(types)
                type_name = types{t};
                Test_Data_Full = Test_Sets.(type_name);
                
                [~, ~, nTrial_Test, ~, nTime_Test] = size(Test_Data_Full);
                
                % -------------------------------------------------
                % Prepare Test Data (Dynamic)
                % -------------------------------------------------
                % Task 1: 18 Ori
                Test_Data_18 = reshape(Test_Data_Full, [n_ori, n_pat*nTrial_Test, length(curr_channels), nTime_Test]);
                
                % Task 2: [1, 9] Ori
                Test_Data_2 = reshape(Test_Data_Full([1, 9], :, :, :, :), [2, n_pat*nTrial_Test, length(curr_channels), nTime_Test]);


                % -------------------------------------------------
                % Task 1: Train on SG (20-40)
                % -------------------------------------------------
                if ~isempty(Mat_SG_Avg)
                    fprintf('    >> Task 1 (SG 20-40) -> %s\n', type_name);
                    
                    % Prepare Train Data
                    [~, ~, nTrial_SG, ~, ~] = size(Mat_SG_Avg);
                    
                    % 18 Ori
                    Train_SG_18 = reshape(Mat_SG_Avg, [n_ori, n_pat*nTrial_SG, length(curr_channels), 1]);
                    res_18 = Master_Decoder(Train_SG_18, Test_Data_18, options);
                    DecodingResults.Task1_SG.(type_name).Ori18 = res_18;
                    
                    % [1, 9] Ori
                    Train_SG_2 = reshape(Mat_SG_Avg([1, 9], :, :, :, :), [2, n_pat*nTrial_SG, length(curr_channels), 1]);
                    res_2 = Master_Decoder(Train_SG_2, Test_Data_2, options);
                    DecodingResults.Task1_SG.(type_name).Ori2 = res_2;
                end
                
                % -------------------------------------------------
                % Task 2: Train on MGv_A (40-60)
                % -------------------------------------------------
                if ~isempty(Mat_MGv_A_Avg)
                    fprintf('    >> Task 2 (MGv_A 40-60) -> %s\n', type_name);
                    
                    % Prepare Train Data
                    [~, ~, nTrial_A, ~, ~] = size(Mat_MGv_A_Avg);
                    
                    % 18 Ori
                    Train_A_18 = reshape(Mat_MGv_A_Avg, [n_ori, n_pat*nTrial_A, length(curr_channels), 1]);
                    res_18 = Master_Decoder(Train_A_18, Test_Data_18, options);
                    DecodingResults.Task2_MGvA.(type_name).Ori18 = res_18;
                    
                    % [1, 9] Ori
                    Train_A_2 = reshape(Mat_MGv_A_Avg([1, 9], :, :, :, :), [2, n_pat*nTrial_A, length(curr_channels), 1]);
                    res_2 = Master_Decoder(Train_A_2, Test_Data_2, options);
                    DecodingResults.Task2_MGvA.(type_name).Ori2 = res_2;
                end
                
            end % End Test Types
            
            % Save Results
            save_name = sprintf('%s_%s_StaticTrain_DynamicTest.mat', monkey_name, strat_name);
            save_full = fullfile(save_dir, save_name);
            fprintf('  Saving to: %s\n', save_full);
            save(save_full, 'DecodingResults', '-v7.3');
            
        end % End Strategies
    end % End Monkeys
    fprintf('All tasks completed.\n');
end
