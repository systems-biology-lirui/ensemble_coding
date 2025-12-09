function pipeline_ssvep_b_decoding_mgv_crossgat()
% Pipeline for SSVEP_B Decoding with Cross-GAT
% 
% Goal:
% 1. Load data from SSVEP_B2EVENT (Fit, Res, Real from SSVEP_B).
% 2. Train on SSVEP_A (Mat_MGv_A_SSVEP).
% 3. Test on SSVEP_B (Fit, Res, Real).
% 4. Perform decoding for each orientation (Pattern decoding).
% 5. Use 'cross-gat' mode in Master_Decoder.

    %% 1. Configuration
    base_path = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Results\Figures\SSVEP_B2EVENT\';
    save_dir  = 'D:\ensemble_coding\Project_Ensemblecoding_2024\Results\Figures\SSVEP_B_CrossGAT\';
    if ~exist(save_dir, 'dir'), mkdir(save_dir); end

    macaques = {'DG', 'QQ_new', 'QQ_old'};
    strategies = {'Strategy1'}; % Iterate over strategies used in fitdecoding

    % Decoding Parameters
    options.do_permutation = false;
    options.n_shuffles     = 5;
    options.n_repetitions  = 1;
    options.k_fold         = 5;
    options.time_smooth_win = 0;
    options.mode           = 'cross_gat'; % User requested 'cross-gat' (using valid mode string)

    % Load Channel Selection
    if exist('Yge_finalchannel.mat', 'file')
        load('Yge_finalchannel.mat', 'sel_channel');
    else
        warning('Yge_finalchannel.mat not found. Will use all channels if not specified.');
        sel_channel = struct();
    end

    %% 2. Main Loop
    for m = 1:length(macaques)
        monkey_name = macaques{m};
        
        % Get Channels
        if isfield(sel_channel, monkey_name)
            curr_channels = sel_channel.(monkey_name);
        else
            curr_channels = []; % Use all if not defined
            warning('No channel selection for %s', monkey_name);
        end

        for s = 1:length(strategies)
            strat_name = strategies{s};
            fprintf('==================================================\n');
            fprintf('Processing: %s - %s\n', monkey_name, strat_name);
            
            % Load Data
            file_name = sprintf('%s_SSVEP_FitResults_%s.mat', monkey_name, strat_name);
            file_path = fullfile(base_path, file_name);
            
            if ~exist(file_path, 'file')
                warning('File not found: %s', file_path);
                continue;
            end
            
            fprintf('  Loading data...\n');
            Data = load(file_path);
            % Data contains: 'Mat_MGv_A_SSVEP', 'Mat_MGv_A_EVENT', 'Mat_MGv_B', 'Fit_Mat', 'Res_Mat_SSVEP'
            
            % Mat Dimensions: [nOri, nPat, nTrial, nCh, nTime]
            % Training Data: SSVEP_A
            Train_Data_Full = Data.Mat_MGv_A_SSVEP;
            
            % Testing Data Types
            Test_Sets = struct();
            Test_Sets.Fit = Data.Fit_Mat;
            Test_Sets.Res = Data.Res_Mat_SSVEP;
            Test_Sets.Real = Data.Mat_MGv_B;
            
            clear Data
            types = fieldnames(Test_Sets);
            
            [nOri, nPat, nTrial_Train, nCh, nTime_Train] = size(Train_Data_Full);
            [~, ~, nTrial_Test, ~, nTime_Test] = size(Test_Sets.Fit);
            
            % Initialize Result Storage
            % We will store results for each Type (Fit, Res, Real) and each Orientation
            DecodingResults = struct();
            
            %% 3. Decoding Loop (Per Orientation, Pattern Decoding)
            fprintf('  Starting Decoding (Train: SSVEP_A, Test: SSVEP_B Fit/Res/Real)...\n');
            
            for t = 1:length(types)
                type_name = types{t};
                Test_Data_Full = Test_Sets.(type_name);
                
                fprintf('    >> Testing on %s...\n', type_name);
                
                % Iterate over 18 Orientations
                for ori = 1:nOri
                    % Prepare Data for this Orientation
                    % Shape: [nPat, nTrial, nCh, nTime]
                    d_train = squeeze(Train_Data_Full(ori, :, :, curr_channels, :));
                    d_test  = squeeze(Test_Data_Full(ori, :, :, curr_channels, :));
                    
                    % Run Decoder
                    % Pattern Decoding: Classes are Patterns (1..6)
                    % d_train: [6, nTrial, nCh, nTime]
                    
                    res = Master_Decoder(d_train, d_test, options);
                    
                    % Store Result
                    % Usually we care about accuracy map (Time x Time) for GAT
                    % If 'cross-gat', result should contain 'acc_matrix' or similar?
                    % Master_Decoder return structure depends on implementation.
                    % Assuming standard output.
                    
                    DecodingResults.(type_name).Ori(ori).result = res;
                    
                    % Print progress every few orientations
                    if mod(ori, 6) == 0
                        fprintf('       Ori %d/18 done.\n', ori);
                    end
                end
            end
            
            %% 4. Save Results
            save_file = fullfile(save_dir, sprintf('%s_%s_CrossGAT_Results.mat', monkey_name, strat_name));
            fprintf('  Saving results to: %s\n', save_file);
            save(save_file, 'DecodingResults', '-v7.3');
            
            %% 5. Plotting (Optional/Basic)
            % Since it's Cross-GAT, we might want to plot diagonal or full map.
            % For now, just save the data as requested.
            
        end
    end
    fprintf('All tasks completed.\n');
end