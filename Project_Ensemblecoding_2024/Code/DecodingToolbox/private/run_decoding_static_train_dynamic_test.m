function results = run_decoding_static_train_dynamic_test(data_train, data_test, config)
% RUN_DECODING_STATIC_TRAIN_DYNAMIC_TEST
% 
% Description:
%   Trains a decoder on a static dataset (data_train) - e.g., averaged over a specific time window.
%   Tests the decoder on each time point of a dynamic dataset (data_test).
%
% Input:
%   data_train: Training dataset.
%               Dimensions: [n_cluster, n_repeat_train, n_coil, 1] (or n_time=1 effectively)
%               The code assumes this data is already averaged or represents a single "static" state.
%               If n_time > 1, it will be treated as if it's the only time point available.
%
%   data_test:  Testing dataset.
%               Dimensions: [n_cluster, n_repeat_test, n_coil, n_time]
%               The decoder will be tested on each time point of this dataset.
%
%   config:     Configuration struct from parse_and_validate_options.
%
% Output:
%   results:    Structure containing decoding results.
%               - .acc_real_mean: [1, n_time_test] vector of accuracies.
%               - .p_value: [1, n_time_test] vector of p-values (if permutation enabled).
%               - .detailed: Detailed distribution of accuracies.

    % --- 1. Initialization ---
    fprintf('Initializing for Static Train -> Dynamic Test decoding...\n');
    
    [~, n_repeat_train, ~, n_time_train] = size(data_train);
    [~, n_repeat_test, ~, n_time_test] = size(data_test);
    
    if n_time_train > 1
        warning('Training data has %d time points. Using the first one (or ensure input is 1 time point).', n_time_train);
    end
    
    % Create labels
    labels_train = repelem((1:config.n_cluster)', n_repeat_train);
    labels_test  = repelem((1:config.n_cluster)', n_repeat_test);
    
    % Initialize outputs
    acc_real_mean = zeros(1, n_time_test);
    p_value = [];
    perm_accuracies_mean = [];
    tmp_real_acc_dist = cell(1, n_time_test);
    tmp_perm_acc_dist = cell(1, n_time_test);
    
    if config.do_permutation
        p_value = ones(1, n_time_test);
        perm_accuracies_mean = zeros(1, n_time_test);
    end
    
    % --- 2. Prepare Training Data (Once) ---
    % Since training data is static, we prepare it once.
    % We use t_idx = 1 because the input should be [..., ..., ..., 1]
    % If data_train has more time points, prepare_data_for_timepoint will handle it based on index 1.
    % Ideally, caller should pass pre-averaged data.
    
    % Note: prepare_data_for_timepoint might expect a time index.
    % If data_train is [n_cluster, n_repeat, n_coil, 1], we access index 1.
    X_train_static = prepare_data_for_timepoint(data_train, 1, 0); % 0 window for static
    
    % --- 3. Dynamic Testing Loop (parfor) ---
    parfor t_test_idx = 1:n_time_test
        
        if mod(t_test_idx, 20) == 0 || t_test_idx == 1
            fprintf('Testing on time point %d/%d...\n', t_test_idx, n_time_test);
        end
        
        % Prepare Test Data for current time point
        X_test_t = prepare_data_for_timepoint(data_test, t_test_idx, config.time_smooth_win);
        
        % --- 3.1 Calculate Real Accuracy ---
        % Reusing perform_gat_cv_step:
        % It splits X_train_static into K-folds for training.
        % It tests on the FULL X_test_t.
        real_accuracies_reps = perform_gat_cv_step(X_train_static, labels_train, X_test_t, labels_test, config);
        
        acc_real_mean(t_test_idx) = mean(real_accuracies_reps);
        tmp_real_acc_dist{t_test_idx} = real_accuracies_reps;
        
        % --- 3.2 Permutation Test ---
        if config.do_permutation
            % Reusing run_permutation_test_gat
            perm_accuracies_at_t = run_permutation_test_gat(X_train_static, labels_train, X_test_t, labels_test, config);
            
            perm_accuracies_mean(t_test_idx) = mean(perm_accuracies_at_t);
            tmp_perm_acc_dist{t_test_idx} = perm_accuracies_at_t;
            
            [~, p] = ttest2(real_accuracies_reps, perm_accuracies_at_t, 'Tail', 'right', 'Vartype', 'unequal');
            p_value(t_test_idx) = p;
        end
    end
    
    % --- 4. Compile Results ---
    results = struct();
    results.acc_real_mean = acc_real_mean;
    results.p_value = p_value;
    results.perm_accuracies_mean = perm_accuracies_mean;
    results.config = config;
    results.detailed.real_acc_dist = tmp_real_acc_dist;
    results.detailed.perm_acc_dist = tmp_perm_acc_dist;
    results.info = 'Decoder trained on static data_train, tested dynamically on data_test.';

end
