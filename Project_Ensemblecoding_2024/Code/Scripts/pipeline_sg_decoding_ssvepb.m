function pipeline_sg_decoding_ssvepb()
% Pipeline: Train on SG_EVENT, Test on SSVEP_B (Fit, Res, Real)
% Mode: Cross-GAT (Train on SG time, Test on SSVEP time)
% Task: Orientation Decoding (18 Ori & [1,9] Ori)

    %% 1. Configuration
    base_path_db = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Data\02_EpochDatabase\';
    base_path_fit = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Results\Figures\SSVEP_B2EVENT\';
    save_dir = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Results\Figures\SG_Decoding_SSVEPb\';
    
    if ~exist(save_dir, 'dir'), mkdir(save_dir); end

    macaques = {'DG', 'QQ_new', 'QQ_old'};
    strategies = {'Strategy1', 'Strategy2', 'Strategy3'}; 

    % Decoding Parameters
    options.do_permutation = false;
    options.n_shuffles     = 5;
    options.n_repetitions  = 5; % Increase repetitions for stable results
    options.k_fold         = 5;
    options.time_smooth_win = 2;
    options.mode           = 'cross_gat'; 

    % Load Channel Selection
    if exist('Yge_finalchannel.mat', 'file')
        load('Yge_finalchannel.mat', 'sel_channel');
    else
        warning('Yge_finalchannel.mat not found. Will use all channels.');
        sel_channel = struct();
    end

    % Parameters for 5D Matrix Construction
    target_ori_list = 1:18;
    n_ori = 18;
    n_pat = 6; % Assuming SG has 6 patterns/phases

    %% 2. Main Loop
    for m = 1:length(macaques)
        monkey_name = macaques{m};
        
        % Get Channels
        if isfield(sel_channel, monkey_name)
            curr_channels = sel_channel.(monkey_name);
        else
            curr_channels = []; 
        end
        
        % --- Step 1: Load and Prepare SG Data (Train) ---
        fprintf('==================================================\n');
        fprintf('Processing Monkey: %s\n', monkey_name);
        
        sg_file = fullfile(base_path_db, sprintf('%s_SG_EVENT_MUA2_Epochs_Avg.mat', monkey_name));
        if ~exist(sg_file, 'file')
            warning('SG File not found: %s', sg_file);
            continue;
        end
        
        fprintf('  Loading SG Data: %s\n', sg_file);
        data_sg = load(sg_file);
        
        % Construct 5D Matrix for SG
        % Mat_SG: [nOri, nPat, nTrial, nCh, nTime]
        try
            [Mat_SG, ~] = NeuroTool.build_5d_matrix(data_sg.EpochDB, n_ori, n_pat, target_ori_list);
        catch ME
            warning(ME.identifier, 'Failed to build 5D matrix for SG data: %s', ME.message);
            continue;
        end
        
        [~, ~, nTrial_SG, ~, nTime_SG] = size(Mat_SG);
        fprintf('  SG Data Loaded. Size: %s\n', mat2str(size(Mat_SG)));

        % Pre-reshape SG Data for Decoding Tasks
        % Task 1: 18 Orientations
        % Reshape to [nOri, nPat*nTrial, nCh, nTime]
        Train_Data_18 = reshape(Mat_SG, [n_ori, n_pat*nTrial_SG, length(curr_channels), nTime_SG]);
        
        % Task 2: [1, 9] Orientations
        % Extract [1, 9] then reshape
        % target_idx_2 = [1, 9];
        % Mat_SG_2 = Mat_SG(target_idx_2, :, :, :, :);
        % Train_Data_2 = reshape(Mat_SG_2, [2, n_pat*nTrial_SG, length(curr_channels), nTime_SG]);


        % --- Step 2: Iterate over Strategies (SSVEP_B Fit Results) ---
        for s = 1:length(strategies)
            strat_name = strategies{s};
            fprintf('  -- Strategy: %s\n', strat_name);
            
            fit_file = fullfile(base_path_fit, sprintf('%s_SSVEP_FitResults_%s.mat', monkey_name, strat_name));
            if ~exist(fit_file, 'file')
                warning('Fit File not found: %s', fit_file);
                continue;
            end
            
            Data_Fit = load(fit_file);
            % Contains: Fit_Mat, Res_Mat_SSVEP, Mat_MGv_B (Real)
            
            Test_Sets = struct();
            Test_Sets.Fit  = Data_Fit.Fit_Mat;
            Test_Sets.Res  = Data_Fit.Res_Mat_SSVEP;
            Test_Sets.Real = Data_Fit.Mat_MGv_B;
            
            types = fieldnames(Test_Sets);
            DecodingResults = struct();
            
            % --- Step 3: Decoding (Orientation Decoding) ---
            for t = 1:length(types)
                type_name = types{t};
                Test_Data_Full = Test_Sets.(type_name);
                
                fprintf('    >> Decoding Test Type: %s\n', type_name);
                
                [~, ~, nTrial_Test, ~, nTime_Test] = size(Test_Data_Full);
                
                % Prepare Test Data
                % Task 1: 18 Orientations
                Test_Data_18 = reshape(Test_Data_Full, [n_ori, n_pat*nTrial_Test, length(curr_channels), nTime_Test]);
                
                % Task 2: [1, 9] Orientations
                % Mat_Test_2 = Test_Data_Full(target_idx_2, :, :, :, :);
                % Test_Data_2 = reshape(Mat_Test_2, [2, n_pat*nTrial_Test, length(curr_channels), nTime_Test]);
                
                % Run Cross-GAT Decoder
                fprintf('       Running 18-Ori Decoding...\n');
                res_18 = Master_Decoder(Train_Data_18, Test_Data_18, options);
                DecodingResults.(type_name).Ori18 = res_18;
                
                % fprintf('       Running [1 vs 9] Decoding...\n');
                % res_2 = Master_Decoder(Train_Data_2, Test_Data_2, options);
                % DecodingResults.(type_name).Ori2 = res_2;

            end
            
            % --- Step 4: Save Results ---
            save_name = sprintf('%s_%s_SG2SSVEPb_CrossGAT.mat', monkey_name, strat_name);
            save_full = fullfile(save_dir, save_name);
            fprintf('  Saving to: %s\n', save_full);
            save(save_full, 'DecodingResults', '-v7.3');
            
        end
    end
    fprintf('All tasks completed.\n');
end
