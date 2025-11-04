function Event_analysis_pipeline()
    % Main script to run the electrophysiology data analysis pipeline.
    % Supports processing for different macaques (DG, QQ) by loading
    % macaque-specific configurations.
    %
    % The pipeline consists of:
    % 1. Signal Extraction: Processes raw data to extract neural signals for different experimental blocks.
    % 2. Decoding Analysis: Performs SVM-based decoding on the extracted signals.
    % 3. Plotting: Generates plots of decoding accuracy.

    clear;
    dbstop if error;
    rng('default'); % 重置随机数的生成

    % =========================================================================
    % USER-CONFIGURABLE PARAMETERS (Adjust these most frequently)
    % =========================================================================
    
    % --- Top-Level Choices ---
    USER_SETTINGS.MACAQUE_TO_PROCESS = 'QQ'; % Options: 'DG', 'QQ'
    % USER_SETTINGS.MACAQUE_TO_PROCESS = 'DG'; 

    % --- Pipeline Stage Flags ---
    USER_SETTINGS.RUN_SIGNAL_EXTRACTION = true;
    USER_SETTINGS.RUN_DECODING          = false;
    USER_SETTINGS.RUN_PLOTTING          = false;

    % --- Key Parameters for Signal Extraction ---
    preidx = {[2:4,9:14,17,18,22:25,27], ...    % QQ
        25:29, ...                                               % DG
        39:42};                                 
        
    USER_SETTINGS.EXTRACTION_DAYS         = preidx{3};  % Days for signal extraction
    USER_SETTINGS.EXTRACTION_DATA_TYPE    = 'LFP';       % 'MUA1', 'MUA2', 'LFP'
    USER_SETTINGS.EXTRACTION_BLOCKS       = {'SG','MGv','MGnv','SSGnv'};% {'MGv', 'MGnv', 'SG', 'blank'};

    % --- Key Parameters for Decoding ---
    USER_SETTINGS.DECODING_DAYS           = 25:29;        % Days for decoding analysis
    USER_SETTINGS.DECODING_BLOCKS         = {'MGv', 'MGnv', 'SG'};
    % 通道还是要改一下
    USER_SETTINGS.DECODING_CHANNELS       = [7, 9, 13, 14, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 30, 38, 42, 45, 51, 53, 61, 62, 66, 73, 76, 82, 83, 84, 86, 87, 89]+1; % coilselect
    USER_SETTINGS.DECODING_N_SHUFFLES     = 50;
    USER_SETTINGS.DECODING_MIN_TRIALS_CAP = 200;

    % --- Key Parameters for Plotting ---
    % (Often derived, but could be overridden if needed)
    % USER_SETTINGS.PLOT_CHANCE_LEVEL     = 1/18; 
    % =========================================================================

    % --- Get Full Experiment Configuration (incorporating user settings) ---
    config = get_experiment_config(USER_SETTINGS);
    
    % --- Create Output Directories (Optional: can be in get_experiment_config) ---
    % setup_directories(config.paths); % Call this helper if you have many paths
    % The current get_experiment_config handles directory creation.

    % --- Run Pipeline Stages ---
    if config.run_flags.signal_extraction
        fprintf('====== Starting Signal Extraction for %s ======\n', config.macaque_name);
        run_signal_extraction(config);
        fprintf('====== Signal Extraction for %s Complete ======\n', config.macaque_name);
    else
        fprintf('Skipping Signal Extraction for %s.\n', config.macaque_name);
    end

    if config.run_flags.decoding
        fprintf('====== Starting Decoding Process for %s ======\n', config.macaque_name);
        run_decoding_analysis(config);
        fprintf('====== Decoding Process for %s Complete ======\n', config.macaque_name);
    else
        fprintf('Skipping Decoding for %s.\n', config.macaque_name);
    end

    if config.run_flags.plotting
        fprintf('====== Starting Decoding Plotting for %s ======\n', config.macaque_name);
        run_plotting(config);
        fprintf('====== Decoding Plotting for %s Complete ======\n', config.macaque_name);
    else
        fprintf('Skipping Decoding Plotting for %s.\n', config.macaque_name);
    end

    fprintf('All selected processes for %s finished.\n', config.macaque_name);
end

%% ------------------------- CONFIGURATION FUNCTION ------------------------ %%
function config = get_experiment_config(USER_SETTINGS)
    % Loads all experiment-specific configurations for the given macaque,
    % based on USER_SETTINGS provided from the main script.
    
    config.macaque_name = upper(USER_SETTINGS.MACAQUE_TO_PROCESS);
    config.is_DG = strcmpi(config.macaque_name, 'DG');
    config.is_QQ = strcmpi(config.macaque_name, 'QQ');

    % --- Run Flags (Controlled by USER_SETTINGS) ---
    config.run_flags.signal_extraction = USER_SETTINGS.RUN_SIGNAL_EXTRACTION;
    config.run_flags.decoding          = USER_SETTINGS.RUN_DECODING;
    config.run_flags.plotting          = USER_SETTINGS.RUN_PLOTTING;
    
    % --- Common Settings (Less frequently changed) ---
    config.common.MUA_LFP_options = {'MUA1','MUA2','LFP'};   
    config.common.all_block_names = {'MGv', 'MGnv', 'SG', 'SSGnv', 'blank'}; % For validation

    % --- Parameters for Signal Extraction ---
    config.process_params.Days            = USER_SETTINGS.EXTRACTION_DAYS;
    config.process_params.MUA_LFP         = USER_SETTINGS.EXTRACTION_DATA_TYPE; % Validate this against common.MUA_LFP_options if needed
    config.process_params.selected_blocks = USER_SETTINGS.EXTRACTION_BLOCKS;

    % ReFactor field names (Typically fixed for a dataset)
    config.ReFactorFields.block           = 'Block';
    config.ReFactorFields.stim_sequence   = 'Stim_Sequence';
    config.ReFactorFields.pattern         = 'Pattern';
    config.ReFactorFields.location        = 'Location';

    % PicDataRearrange parameters (Parameters for epoching, often dataset/experiment specific but less frequently changed than days/blocks)
    config.PicDataParams.beforesti_samples        = 100;
    config.PicDataParams.pictime_samples          = 20;
    config.PicDataParams.timewindow_relative      = -19:80; % Relative to picture onset in samples
    config.PicDataParams.pics_indices_in_sequence = [1,14,27,40]; % Which pictures in trial sequence to analyze
    config.PicDataParams.num_channels             = 94; % Assumed fixed, or could be derived from data

    % --- Parameters for Decoding ---
    config.decode_params.Days                 = USER_SETTINGS.DECODING_DAYS;
    config.decode_params.selected_blocks      = USER_SETTINGS.DECODING_BLOCKS;
    config.decode_params.coilselect           = USER_SETTINGS.DECODING_CHANNELS;
    config.decode_params.orientation_clusternum = 18; % Number of orientation clusters to decode
    config.decode_params.n_shuffles           = USER_SETTINGS.DECODING_N_SHUFFLES;
    config.decode_params.min_trials_cap       = USER_SETTINGS.DECODING_MIN_TRIALS_CAP; 
    
    % Derived decoding parameters (depend on other settings)
    config.decode_params.MUA_LFP_str          = config.process_params.MUA_LFP; % Use the one from extraction for consistency, or allow separate user setting
    config.decode_params.output_prefix_svm    = sprintf('%s_orientationSVM', config.macaque_name); 
    config.decode_params.intermediate_save_prefix = sprintf('DecodingcontentEvent_Ori_%s_', config.macaque_name);

    % --- Parameters for Plotting ---
    config.plot_params.MUA_LFP_decode_str = config.decode_params.MUA_LFP_str; % Derived from decoding
    config.plot_params.Days_decode_range_for_filename = config.decode_params.Days; % Derived
    config.plot_params.chance_level       = 1 / config.decode_params.orientation_clusternum; % Derived
    if isfield(USER_SETTINGS, 'PLOT_CHANCE_LEVEL') && ~isempty(USER_SETTINGS.PLOT_CHANCE_LEVEL)
        config.plot_params.chance_level = USER_SETTINGS.PLOT_CHANCE_LEVEL; % Allow override
    end
    config.plot_params.accuracy_file_prefix = config.decode_params.output_prefix_svm; % Derived
    config.plot_params.colors             = [62,181,95; 233,173,107; 120,158,175; 142,50,40]/255; % Usually fixed

    % --- Macaque-Specific Path Settings ---
    if config.is_DG
        config.paths.base           = 'D:\ensemble_coding\DGdata\';
        config.paths.raw_data_input = fullfile(config.paths.base,'500hzdata');
        config.paths.stim_info      = fullfile(config.paths.base, 'tooldata','DG_metadata_Event.mat');
        config.paths.session_idx    = fullfile(config.paths.base, 'tooldata', 'DGSessionIdx.mat');
    elseif config.is_QQ
        config.paths.base           = 'D:\ensemble_coding\QQdata\';
        config.paths.raw_data_input = fullfile(config.paths.base,'500hzdata');
        config.paths.stim_info      = fullfile(config.paths.base,'tooldata','QQ_metadata_Event.mat');
        config.paths.session_idx    = fullfile(config.paths.base,'tooldata', 'QQSessionIdx.mat');
    else
        error('Invalid macaque_name: %s. Choose "DG" or "QQ".', config.macaque_name);
    end
    
    % Common paths based on macaque base path
    config.paths.processed_event_output = fullfile(config.paths.base, 'Processed_Event', filesep);
    config.paths.decoding_results_output = fullfile('D:\Ensemble plot\', [config.macaque_name 'decoding'], filesep);

    % Ensure output directories exist
    if ~exist(config.paths.processed_event_output, 'dir'); mkdir(config.paths.processed_event_output); end
    if ~exist(config.paths.decoding_results_output, 'dir'); mkdir(config.paths.decoding_results_output); end

    % Validate selected blocks (using common list)
    if any(~ismember(config.process_params.selected_blocks, config.common.all_block_names))
        invalid_blocks = config.process_params.selected_blocks(~ismember(config.process_params.selected_blocks, config.common.all_block_names));
        error('Invalid block name(s) in USER_SETTINGS.EXTRACTION_BLOCKS for %s: %s', config.macaque_name, strjoin(invalid_blocks, ', '));
    end
    if any(~ismember(config.decode_params.selected_blocks, config.common.all_block_names))
        invalid_blocks = config.decode_params.selected_blocks(~ismember(config.decode_params.selected_blocks, config.common.all_block_names));
        error('Invalid block name(s) in USER_SETTINGS.DECODING_BLOCKS for %s: %s', config.macaque_name, strjoin(invalid_blocks, ', '));
    end
end

%% ------------------------- SIGNAL EXTRACTION --------------------------- %%
function run_signal_extraction(config)
    % Main function for processing raw data and extracting neural signals.

    % Load session indexing and stimulus metadata
    fprintf('Loading session index from: %s\n', config.paths.session_idx);
    load(config.paths.session_idx,'SessionIdx');
    
    sessionIdx_data = SessionIdx;
    fprintf('Loading stimulus metadata from: %s\n', config.paths.stim_info);
    stim_metadata = load(config.paths.stim_info, 'Meta_data'); % DG: Meta_data


    % Initialize data structures to hold processed data for all selected blocks
    processed_data_all_blocks = initialize_block_data_structures(config.process_params.selected_blocks);
    
    all_session_repeat_nums = cell(length(config.process_params.Days), 0); 

    for day_loop_idx = 1:length(config.process_params.Days)
        current_day_val = config.process_params.Days(day_loop_idx);
        fprintf('-- Processing Day: %d for %s --\n', current_day_val, config.macaque_name);

        % Determine sessions to process for this day
        if config.is_DG
            session_file_numbers = [sessionIdx_data{3:6, current_day_val}]; % 这个位置要记得改一下
            u_day_prefix = sprintf('u%d', sessionIdx_data{1, current_day_val});
            raw_file_name_template = sprintf('%s2-%s-%%03d-500hz.mat', config.macaque_name, u_day_prefix);
        elseif config.is_QQ
            real_session_indices_for_day = sessionIdx_data{11, current_day_val}; % Actual session number (1-indexed)
            session_file_numbers = sessionIdx_data{12, current_day_val}; % File numbers for QQ
            u_day_prefix = sessionIdx_data{1, current_day_val};
            raw_file_name_template = sprintf('%s2-%s-%%03d-500hz.mat', config.macaque_name, u_day_prefix);
        end
        
        if day_loop_idx == 1 && ~isempty(session_file_numbers) % Pre-allocate for max sessions on first day
            all_session_repeat_nums = cell(length(config.process_params.Days), length(session_file_numbers));
        elseif isempty(session_file_numbers)
            fprintf('Warning: No sessions scheduled for day %d.\n', current_day_val);
            continue;
        end

        for session_loop_idx = 1:length(session_file_numbers)
            current_session_filenum = session_file_numbers(session_loop_idx);
            fprintf('  Session File: %03d\n', current_session_filenum);

            raw_data_filepath = fullfile(config.paths.raw_data_input, sprintf(raw_file_name_template, current_session_filenum));
            if ~exist(raw_data_filepath, 'file')
                fprintf('Warning: Raw data file not found: %s. Skipping session.\n', raw_data_filepath);
                continue;
            end
            
            load(raw_data_filepath, 'Datainfo');

            % Determine session_factor (trial-specific metadata)
            if config.is_DG
                metadata_day_idx = find(strcmp({stim_metadata.Meta_data{:,3}}, u_day_prefix));
                % DG uses session_loop_idx directly related to the order in Meta_data for that day_prefix
                original_session_factor = stim_metadata.Meta_data{metadata_day_idx(session_loop_idx),1};
            elseif config.is_QQ % 这一块也要进行修改以便代码一致
                current_real_session_num = real_session_indices_for_day(session_loop_idx);
                stim_lookup_key = sessionIdx_data{3, current_day_val}; % e.g., 'event_A'
                metadata_day_idx = find(strcmp({stim_metadata.Meta_data{:,2}}, stim_lookup_key));
                % Find the entry in final_sessions that corresponds to current_real_session_num
                original_session_factor = stim_metadata.Meta_data{metadata_day_idx(current_real_session_num),1};
            end
            
            % Rearrange trials based on response codes
            ReFactor = IdxRearrage(Datainfo.VSinfo.sMbmInfo.respCode, original_session_factor);
            
            % Select MUA/LFP data based on config
            mua_lfp_idx = config.process_params.MUA_LFP;
            if strcmpi(mua_lfp_idx,'MUA1') 
                neural_data_for_session = Datainfo.trial_MUA{1};
            elseif strcmpi(mua_lfp_idx,'MUA2') 
                if length(Datainfo.trial_MUA) ==1
                    neural_data_for_session = Datainfo.trial_MUA{1};
                else
                    neural_data_for_session = Datainfo.trial_MUA{2};
                end
            elseif strcmpi(mua_lfp_idx,'LFP') 
                neural_data_for_session = Datainfo.trial_LFP;
            else
                error('Invalid MUA_LFP_idx in config.');
            end

            % Process pictures within trials (rearrange, baseline, etc.)
            [session_repeat_counts, session_clustered_data] = PicDataRearrange(config, ReFactor, neural_data_for_session);
            
            all_session_repeat_nums{day_loop_idx, session_loop_idx} = session_repeat_counts;
            
            % Concatenate data from this session into the main data structures
            processed_data_all_blocks = update_block_data_with_session(processed_data_all_blocks, session_clustered_data, config.process_params.selected_blocks);
        end
    end
    
    % Save the processed data for each block
    save_processed_block_data(config, processed_data_all_blocks);
end

function block_data_structs = initialize_block_data_structures(selected_blocks)
    block_data_structs = struct();
    % Define a template for block conditions (e.g., orientations)
    base_condition_template = struct('BlockName', [], 'Location', [], 'Pic_Ori', [], 'Pattern', [], 'Data',[], 'Phase', []);

    if ismember('MGv', selected_blocks)
        block_data_structs.MGv = repmat(base_condition_template, 1, 18);
        for i = 1:18; block_data_structs.MGv(i).BlockName = 'MGv'; block_data_structs.MGv(i).Pic_Ori = i; end
    end
    if ismember('MGnv', selected_blocks)
        block_data_structs.MGnv = repmat(base_condition_template, 1, 18);
        for i = 1:18; block_data_structs.MGnv(i).BlockName = 'MGnv'; block_data_structs.MGnv(i).Pic_Ori = i; end
    end
    if ismember('SG', selected_blocks)
        block_data_structs.SG = repmat(base_condition_template, 1, 18);
        for i = 1:18; block_data_structs.SG(i).BlockName = 'SG'; block_data_structs.SG(i).Pic_Ori = i; end
    end
    if ismember('SSGnv', selected_blocks)
        num_ssgnv_conditions = 13 * 18; % 13 locations, 18 orientations
        block_data_structs.SSGnv = repmat(base_condition_template, 1, num_ssgnv_conditions);
        idx = 1;
        for loc = 1:13
            for ori = 1:18
                block_data_structs.SSGnv(idx).BlockName = 'SSGnv';
                block_data_structs.SSGnv(idx).Location = loc;
                block_data_structs.SSGnv(idx).Pic_Ori = ori;
                idx = idx + 1;
            end
        end
    end
    if ismember('blank', selected_blocks)
        block_data_structs.blank = cell(1,1); % Blank is often treated as a cell for easier cat
    end
end

function ReFactor = IdxRearrage(respCode, session_factor)
for i = 1:length(respCode)
    if respCode(i) ~= 1
        session_factor(end+1) = session_factor(i);

    end
end
idx = respCode ~= 1;
session_factor(idx) = [];
ReFactor = session_factor;
end


function [repeatnum_per_ori, ClusterData] = PicDataRearrange(config, ReFactor, trial_MUA_LFP_data)
    % Extracts and baseline-corrects neural data for specified pictures in each trial.

    % Initialize structures
    repeatnum_per_ori(1:18) = struct('MGv',0,'MGnv',0,'SG',0); % Counts per orientation for specific blocks
    ClusterData = struct(...
        'MGv',  {cell(2, 18)}, ... % {1,ori}=Data, {2,ori}=Pattern
        'MGnv', {cell(2, 18)}, ...
        'SG',   {cell(2, 18)}, ...
        'SSGnv',{cell(2, 13, 18)}, ... % {loc,ori}=Data (QQ processing specific)
        'blank',{cell(1,1)});      % Store raw blank trials

    % Time parameters from config
    p = config.PicDataParams;
    total_timewindow_len = length(p.timewindow_relative);

    for trial_idx = 1:length(ReFactor)
        current_trial_info = ReFactor(trial_idx);
        
        % Get block name, handling DG's cell format
        raw_block_name = current_trial_info.(config.ReFactorFields.block);
        if config.is_DG && iscell(raw_block_name)
            block_name_str = raw_block_name{1};
        else
            block_name_str = raw_block_name;
        end

        if strcmpi(block_name_str, 'blank')
            ClusterData.blank = cat(1, ClusterData.blank, ...
                single(trial_MUA_LFP_data(trial_idx, 1:p.num_channels, :))); % Store full trial for blank
            continue;
        end
        
        % For SSGnv (primarily QQ's processing pathway shown in original)
        if strcmpi(block_name_str, 'SSGnv') 
            loc = current_trial_info.(config.ReFactorFields.location);
            for pic_seq_idx = p.pics_indices_in_sequence
                pattern = current_trial_info.(config.ReFactorFields.pattern)(pic_seq_idx);
                ori = current_trial_info.(config.ReFactorFields.stim_sequence)(pic_seq_idx);
                
                % Calculate time window for this picture
                start_sample_abs = p.beforesti_samples + (pic_seq_idx-1)*p.pictime_samples + p.timewindow_relative(1);
                time_indices = start_sample_abs : (start_sample_abs + total_timewindow_len - 1);
                
                current_epoch_data = int16(trial_MUA_LFP_data(trial_idx, 1:p.num_channels, time_indices));
                
                % Baseline: first 'pictime_samples' of the current epoch's window
                baseline_data = int16(mean(current_epoch_data(:,:, 1:p.pictime_samples), 3));
                filtered_data = current_epoch_data - baseline_data;
                
                ClusterData.SSGnv{1, loc, ori} = cat(1, ClusterData.SSGnv{1, loc, ori}, filtered_data);
                ClusterData.SSGnv{2, loc, ori} = cat(1, ClusterData.SSGnv{2, loc, ori}, pattern);
            end
        % For MGv, MGnv, SG blocks
        elseif ismember(block_name_str, {'MGv', 'MGnv', 'SG'})
            if ~isfield(current_trial_info, config.ReFactorFields.stim_sequence)
                fprintf('Warning: Trial %d, Block %s missing stim_sequence. Skipping pics.\n', trial_idx, block_name_str);
                continue;
            end
            for pic_seq_idx = p.pics_indices_in_sequence
                ori = current_trial_info.(config.ReFactorFields.stim_sequence)(pic_seq_idx);
                pattern_val = current_trial_info.(config.ReFactorFields.pattern)(pic_seq_idx);
                
                if isfield(repeatnum_per_ori(ori), block_name_str)
                    repeatnum_per_ori(ori).(block_name_str) = repeatnum_per_ori(ori).(block_name_str) + 1;
                end
                
                start_sample_abs = p.beforesti_samples + (pic_seq_idx-1)*p.pictime_samples + p.timewindow_relative(1);
                time_indices = start_sample_abs : (start_sample_abs + total_timewindow_len - 1);
                
                current_epoch_data = single(trial_MUA_LFP_data(trial_idx, 1:p.num_channels, time_indices));
                baseline_data = mean(current_epoch_data(:,:, 1:p.pictime_samples), 3);
                filtered_data = current_epoch_data - baseline_data;
                
                ClusterData.(block_name_str){1,ori} = cat(1, ClusterData.(block_name_str){1,ori}, filtered_data);
                ClusterData.(block_name_str){2,ori} = cat(1, ClusterData.(block_name_str){2,ori}, pattern_val);
            end
        end
    end
end

function updated_block_data = update_block_data_with_session(current_block_data, session_cluster_data, selected_blocks_for_processing)
    updated_block_data = current_block_data; % Operate on a copy

    for i = 1:length(selected_blocks_for_processing)
        block_name = selected_blocks_for_processing{i};
        
        if ~isfield(updated_block_data, block_name) || ~isfield(session_cluster_data, block_name)
            continue; % Block not initialized or no data for it in this session
        end

        if strcmpi(block_name, 'blank')
            if ~isempty(session_cluster_data.blank) && ~isempty(session_cluster_data.blank{1})
                 % Ensure updated_block_data.blank is initialized if it's the first non-empty data
                if isempty(updated_block_data.blank{1}) 
                    updated_block_data.blank = session_cluster_data.blank;
                else
                    updated_block_data.blank = cat(1, updated_block_data.blank, session_cluster_data.blank);
                end
            end
        elseif strcmpi(block_name, 'SSGnv') % SSGnv from ClusterData is {loc, ori} cell
            if isfield(session_cluster_data, 'SSGnv') && ~isempty(session_cluster_data.SSGnv)
                for loc = 1:size(session_cluster_data.SSGnv, 2)
                    for cond = 1:size(session_cluster_data.SSGnv, 3)
                        if ~isempty(session_cluster_data.SSGnv{1, loc, cond})
                            struct_idx = find([updated_block_data.SSGnv.Location] == loc & ...
                                              [updated_block_data.SSGnv.Pic_Ori] == cond, 1);
                            if ~isempty(struct_idx)
                                updated_block_data.SSGnv(struct_idx).Data = cat(1, updated_block_data.SSGnv(struct_idx).Data, session_cluster_data.SSGnv{1, loc, cond});
                                updated_block_data.SSGnv(struct_idx).Pattern = cat(1, updated_block_data.SSGnv(struct_idx).Pattern, session_cluster_data.SSGnv{2, loc, cond});
                            end
                        end
                    end
                end
            end
        else % For MGv, MGnv, SG: ClusterData.(block_name) is {2, 18} cell
            if isfield(session_cluster_data, block_name) && ~isempty(session_cluster_data.(block_name))
                num_conditions = size(session_cluster_data.(block_name), 2);
                for cond = 1:num_conditions
                    if ~isempty(session_cluster_data.(block_name){1,cond}) % Check data part
                        updated_block_data.(block_name)(cond).Data = cat(1, updated_block_data.(block_name)(cond).Data, session_cluster_data.(block_name){1,cond});
                        updated_block_data.(block_name)(cond).Pattern = cat(1, updated_block_data.(block_name)(cond).Pattern, session_cluster_data.(block_name){2,cond});
                    end
                end
            end
        end
    end
end

function save_processed_block_data(config, processed_data)
    output_dir = config.paths.processed_event_output;
    days_str = sprintf('Days%d_%d', config.process_params.Days(1), config.process_params.Days(end));
    mua_lfp_str = config.process_params.MUA_LFP;
    
    file_prefix = '';
    if config.is_DG
        file_prefix = 'DG_';
    elseif config.is_QQ
        file_prefix = 'QQ_';
    end

    block_names = fieldnames(processed_data);
    for i = 1:length(block_names)
        current_block_name = block_names{i};
        data_to_save = processed_data.(current_block_name);
        
        % Basic check for emptiness before saving
        is_data_empty = false;
        if strcmp(current_block_name, 'blank')
            if iscell(data_to_save) && (isempty(data_to_save) || isempty(data_to_save{1}))
                is_data_empty = true;
            end
        elseif isstruct(data_to_save) && isfield(data_to_save, 'Data') && isempty(data_to_save(1).Data)
            is_data_empty = true; % Check first condition's Data field
        elseif isempty(data_to_save)
             is_data_empty = true;
        end

        if ~is_data_empty
            save_filename = sprintf('%sEVENT_%s_%s_%s.mat', file_prefix, days_str, mua_lfp_str, current_block_name);
            save_filepath = fullfile(output_dir, save_filename);
            
            fprintf('Saving %s data to %s\n', current_block_name, save_filepath);
            % To save the variable with its dynamic name (e.g., 'MGv') inside the .mat file
            eval([current_block_name ' = data_to_save;']);
            save(save_filepath, current_block_name, '-v7.3');
            clear(current_block_name); % Clean up the temporary workspace variable
        else
            fprintf('Skipping save for empty or unpopulated block: %s\n', current_block_name);
        end
    end
    
    % Optionally, save all_repeat_nums
    % repeat_nums_filename = sprintf('%sEVENT_%s_%s_AllRepeatNums.mat', file_prefix, days_str, mua_lfp_str);
    % save(fullfile(output_dir, repeat_nums_filename), 'all_repeat_nums', '-v7.3');
    % fprintf('Saved all_repeat_nums to %s\n', repeat_nums_filename);
end


