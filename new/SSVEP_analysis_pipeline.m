function SSVEP_analysis_pipeline()
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
    USER_SETTINGS.A_B                     = 'A';
    % QQ 后两天的通道数量不对，先不进行采集
    preidx = {[1,5:8,11:13,15,17,18,21:23,25:27]; ...   % QQ_A
        [9,10,14,16,19,20,24,27,28,29]; ...             % QQ_B
        [32]; % QQ_A new
        [34]; % QQ_B new
        [3:15]; ...                                     % DG_A
        [16:23]};                                       % DG_B

    USER_SETTINGS.EXTRACTION_DAYS         = preidx{1};     % Days for signal extraction
    USER_SETTINGS.EXTRACTION_DATA_TYPE    = 'MUA2';              % 'MUA1', 'MUA2', 'LFP'
    USER_SETTINGS.EXTRACTION_BLOCKS       = {'MGv'};
    USER_SETTINGS.EXTRACTION_SSG_LOCATION = 1:13;                % 内存的原因，对于位置进行分离
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
    config.common.A_B             = USER_SETTINGS.A_B;
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
    
    % TrailDataRearrage parameters
    config.TrialDataParams.condition       = -1:2:17;
    config.TrialDataParams.triallength     = 1:1640;
    config.TrialDataParams.ssglocation     = USER_SETTINGS.EXTRACTION_SSG_LOCATION;
    
    % --- Macaque-Specific Path Settings ---
    if config.is_DG
        config.paths.base           = 'D:\Ensemble coding\DGdata\';
        config.paths.raw_data_input = fullfile(config.paths.base,'500hzdata');
        config.paths.stim_info      = fullfile(config.paths.base, 'tooldata','DG_metadata_SSVEP.mat');
        config.paths.session_idx    = fullfile(config.paths.base, 'tooldata', 'DGSessionIdx.mat');
    elseif config.is_QQ
        config.paths.base           = 'D:\Ensemble coding\QQdata\';
        config.paths.raw_data_input = fullfile(config.paths.base,'500hzdata');
        % config.paths.raw_data_input = 'D:\Ensemble coding\tools\1B_MUA';
        config.paths.stim_info      = fullfile(config.paths.base,'tooldata','QQ_metadata_SSVEP.mat');
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
    % if any(~ismember(config.decode_params.selected_blocks, config.common.all_block_names))
    %     invalid_blocks = config.decode_params.selected_blocks(~ismember(config.decode_params.selected_blocks, config.common.all_block_names));
    %     error('Invalid block name(s) in USER_SETTINGS.DECODING_BLOCKS for %s: %s', config.macaque_name, strjoin(invalid_blocks, ', '));
    % end
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
    
    if strcmpi(config.common.A_B,'A')
        L = 1;
        C = 5;
        E = 2;
        gg = 3;
    elseif strcmpi(config.common.A_B,'B')
        L = 5;
        C = 8;
        E = 6;
        gg = 7;
    else
        error('Wrong A_B Option');
    end

    % Initialize data structures to hold processed data for all selected blocks
    processed_data_all_blocks = initialize_block_data_structures(config.process_params.selected_blocks);
    
    all_session_repeat_nums = cell(length(config.process_params.Days), 0); 

    for day_loop_idx = 1:length(config.process_params.Days)
        current_day_val = config.process_params.Days(day_loop_idx);
        fprintf('-- Processing Day: %d for %s --\n', current_day_val, config.macaque_name);

        % Determine sessions to process for this day
        if config.is_DG
            if strcmp(config.process_params.selected_blocks,'SSGnv')
                z = 6;
            elseif strcmp(config.process_params.selected_blocks,'SSGv')
                z = 8;
            else
                z = 3:5;
            end
            session_file_numbers = [sessionIdx_data{z, current_day_val}];
            u_day_prefix = sprintf('u%d', sessionIdx_data{1, current_day_val});
            raw_file_name_template = sprintf('%s2-%s-%%03d-500hz.mat', config.macaque_name, u_day_prefix);
        elseif config.is_QQ
            real_session_indices_for_day = sessionIdx_data{C, current_day_val}; % Actual session number (1-indexed)
            session_file_numbers = sessionIdx_data{C+1, current_day_val}; % File numbers for QQ
            u_day_prefix = sessionIdx_data{1, current_day_val};
            raw_file_name_template = sprintf('%s2-%s-%%03d-500hz.mat', config.macaque_name, u_day_prefix);
            % raw_file_name_template = sprintf('MUA_Data%s2_%s-%%03d.mat', config.macaque_name, u_day_prefix);
        end
        
        if day_loop_idx == 1 && ~isempty(session_file_numbers) % Pre-allocate for max sessions on first day
            all_session_repeat_nums = cell(length(config.process_params.Days), length(session_file_numbers));
        elseif isempty(session_file_numbers)
            fprintf('Warning: No sessions scheduled for day %d.\n', current_day_val);
            continue;
        end

        for session_loop_idx = 1:length(session_file_numbers)
            current_session_filenum = session_file_numbers(session_loop_idx);
            fprintf('Session File: %03d\n', current_session_filenum);

            raw_data_filepath = fullfile(config.paths.raw_data_input, sprintf(raw_file_name_template, current_session_filenum));
            if ~exist(raw_data_filepath, 'file')
                fprintf('Warning: Raw data file not found: %s. Skipping session.\n', raw_data_filepath);
                continue;
            end
            
            load(raw_data_filepath, 'Datainfo');
            
            % Determine session_factor (trial-specific metadata)
            if config.is_DG
                
                metadata_day_idx = find(strcmp({stim_metadata.Meta_data{:,gg}}, u_day_prefix));
                % DG uses session_loop_idx directly related to the order in Meta_data for that day_prefix
                
                if strcmp(config.process_params.selected_blocks,'SSGnv')
                    pp = length([SessionIdx{3:5,current_day_val}]);
                    original_session_factor = stim_metadata.Meta_data{metadata_day_idx(session_loop_idx+pp),L};
                elseif strcmp(config.process_params.selected_blocks,'SSGv')
                    pp = length([SessionIdx{3:6,current_day_val}]);
                    original_session_factor = stim_metadata.Meta_data{metadata_day_idx(session_loop_idx+pp),L};
                else
                    original_session_factor = stim_metadata.Meta_data{metadata_day_idx(session_loop_idx),L};
                end
            elseif config.is_QQ % 这一块也要进行修改以便代码一致
                current_real_session_num = real_session_indices_for_day(session_loop_idx);
                stim_lookup_key = sessionIdx_data{3, current_day_val}; % e.g., 'event_A'
                metadata_day_idx = find(strcmp({stim_metadata.Meta_data{:,E}}, stim_lookup_key));
                % Find the entry in final_sessions that corresponds to current_real_session_num
                original_session_factor = stim_metadata.Meta_data{metadata_day_idx(current_real_session_num),L};
            end
            
            % Rearrange trials based on response codes
            ReFactor = IdxRearrage(Datainfo.VSinfo.sMbmInfo.respCode, original_session_factor);
            
            % Select MUA/LFP data based on config
            mua_lfp_idx = config.process_params.MUA_LFP;
            if strcmpi(mua_lfp_idx,'MUA1') 
                neural_data_for_session = Datainfo.trial_MUA{1};
            elseif strcmpi(mua_lfp_idx,'MUA2') 
                neural_data_for_session = Datainfo.trial_MUA{2};
            elseif strcmpi(mua_lfp_idx,'LFP') 
                neural_data_for_session = Datainfo.trial_LFP;
            else
                error('Invalid MUA_LFP_idx in config.');
            end

            % Process pictures within trials (rearrange, baseline, etc.)
            [session_repeat_counts, session_clustered_data] = TrialDataRearrange(config, ReFactor, neural_data_for_session);
            
            all_session_repeat_nums{day_loop_idx, session_loop_idx} = session_repeat_counts;
            % a = size(processed_data_all_blocks.MGv(1).Pic_Ori,1);
            % Concatenate data from this session into the main data structures
            % A = size(processed_data_all_blocks.SG(1).Data,1);
            processed_data_all_blocks = update_block_data_with_session(processed_data_all_blocks, session_clustered_data, config.process_params.selected_blocks);
        end
    end
    
    % Save the processed data for each block
    save_processed_block_data(config, processed_data_all_blocks);
end

function block_data_structs = initialize_block_data_structures(selected_blocks)
    block_data_structs = struct();
    % Define a template for block conditions (e.g., orientations)
    base_condition_template = struct('Block', [], 'Location', [], 'Target_Ori', [], 'Pic_Ori', [], 'Pattern', [], 'Data',[]);
    condition = -1:2:17;
    if ismember('MGv', selected_blocks)
        block_data_structs.MGv = repmat(base_condition_template, 1, 10);
        for i = 1:10; block_data_structs.MGv(i).Block = 'MGv'; block_data_structs.MGv(i).Target_Ori = condition(i); end
    end
    if ismember('MGnv', selected_blocks)
        block_data_structs.MGnv = repmat(base_condition_template, 1, 10);
        for i = 1:10; block_data_structs.MGnv(i).Block = 'MGnv'; block_data_structs.MGnv(i).Target_Ori = condition(i); end
    end
    if ismember('SG', selected_blocks)
        block_data_structs.SG = repmat(base_condition_template, 1, 10);
        for i = 1:10; block_data_structs.SG(i).Block = 'SG'; block_data_structs.SG(i).Target_Ori = condition(i); end
    end
    if ismember('SSGnv', selected_blocks)
        num_ssgnv_conditions = 13 * 10; % 13 locations, 18 orientations
        block_data_structs.SSGnv = repmat(base_condition_template, 1, num_ssgnv_conditions);
        idx = 1;
        for loc = 1:13
            for ori = 1:10
                block_data_structs.SSGnv(idx).Block = 'SSGnv';
                block_data_structs.SSGnv(idx).Location = loc;
                block_data_structs.SSGnv(idx).Target_Ori = condition(ori);
                idx = idx + 1;
            end
        end
    end
    if ismember('blank', selected_blocks)
        block_data_structs.blank = []; % Blank is often treated as a cell for easier cat
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


function [repeatnum_per_ori, ClusterData] = TrialDataRearrange(config, ReFactor, trialdata)
    % Extracts and baseline-corrects neural data for specified pictures in each trial.
    locationselect = config.TrialDataParams.ssglocation;
    % Initialize structures
    repeatnum_per_ori(1:18) = struct('MGv',0,'MGnv',0,'SG',0); % Counts per orientation for specific blocks
    ClusterData = struct(...
        'MGv',  {cell(3, 10)}, ... % {1,ori}=Data, {2,ori}=Pattern
        'MGnv', {cell(3, 10)}, ...
        'SG',   {cell(3, 10)}, ...
        'SSGnv',{cell(2, 13, 10)}, ... % {loc,ori}=Data (QQ processing specific)
        'blank',[]);      % Store raw blank trials

    % Time parameters from config
    t = config.TrialDataParams;
    
    uniqueChars = unique({ReFactor.Block});  % 返回 {'A', 'B', 'C', 'D'}

    charIndices = cell(1, length(uniqueChars));

    for i = 1:length(uniqueChars)
        charIndices{i} = find(strcmp({ReFactor.Block}, uniqueChars{i}));
    end
    

    for i = 1:length(uniqueChars)
        currentBlock = uniqueChars{i};
        currentBlockidx = ReFactor(charIndices{i});
        if strcmp(currentBlock,'SSGnv')
            for loc = locationselect
                condition = -1:2:17;
                for condi = 1:length(-1:2:17)
                    idx = [currentBlockidx.Location] == loc & [currentBlockidx.Condition] == condition(condi);
                    idx = charIndices{i}(idx);
                    data = trialdata(idx, 1:96, 1:1640);
                    filteredData = data - mean(data(:,:,1:100),3);
                    % if any(isnan(data(:))) || any(isinf(data(:)))
                    % disp(min(data(:)));
                    % disp(max(data(:)));
                    % end
                    % filteredData = filtfilt(b, a, single(data)')'; % 滤波
                    % filteredData = reshape(filteredData,[1,96,1640]);
                    ClusterData.SSGnv{1, loc, condi} = int16(filteredData);

                    ClusterData.SSGnv{2, loc,condi} = int16([ReFactor(idx).Stim_Sequence]);
                end
            end
        elseif strcmp(currentBlock,'SSGv')
            for loc = locationselect
                condition = -1:2:17;
                for condi = 1:length(-1:2:17)
                    idx = [currentBlockidx.Location] == loc & [currentBlockidx.Condition] == condition(condi);
                    idx = charIndices{i}(idx);
                    data = trialdata(idx, 1:96, 1:1640);
                    filteredData = data - mean(data(:,:,1:100),3);
                    % if any(isnan(data(:))) || any(isinf(data(:)))
                    %     disp(min(data(:)));
                    %     disp(max(data(:)));
                    % end
                    % filteredData = filtfilt(b, a, single(data)')'; % 滤波
                    % filteredData = reshape(filteredData,[1,96,1640]);
                    ClusterData.SSGnv{1, loc, condi} = int16(filteredData);

                    ClusterData.SSGnv{2, loc,condi} = int16([ReFactor(idx).Stim_Sequence]);
                end
            end
        elseif strcmp(currentBlock,'blank')
            idx = charIndices{i};
            ClusterData.blank = cat(1,ClusterData.blank,single(trialdata(idx,1:94,1:1640)));
        else
            condition = t.condition;
            for condi = 1:length(condition)
                idx1 = [currentBlockidx.Condition] == condition(condi);
                idx = charIndices{i}(idx1);
                data = trialdata(idx, 1:94, t.triallength);
                filteredData = data - mean(data(:,:,1:100),3);
                % filteredData = filtfilt(b, a, single(data)')'; % 滤波
                % filteredData = reshape(filteredData,[1,96,1640]);
                ClusterData.(currentBlock){1,condi} = int16(filteredData);
                ClusterData.(currentBlock){2,condi} = cat(1,ReFactor(idx).Stim_Sequence);
                ClusterData.(currentBlock){3,condi} = cat(1,ReFactor(idx).Pattern);
            end
        end
    end
    
end

function current_block_data = update_block_data_with_session(current_block_data, session_cluster_data, selected_blocks_for_processing)
    condition = -1:2:17;
    for i = 1:length(selected_blocks_for_processing)
        block_name = selected_blocks_for_processing{i};
        
        if ~isfield(current_block_data, block_name) || ~isfield(session_cluster_data, block_name)
            continue; % Block not initialized or no data for it in this session
        end

        if strcmpi(block_name, 'blank')
            if isempty(current_block_data.blank)
                current_block_data.blank = session_cluster_data.blank;
            else
                current_block_data.blank = cat(1, current_block_data.blank, session_cluster_data.blank);
            end
          
        elseif strcmpi(block_name, 'SSGnv') % SSGnv from ClusterData is {loc, ori} cell
            if isfield(session_cluster_data, 'SSGnv') && ~isempty(session_cluster_data.SSGnv)
                for loc = 1:size(session_cluster_data.SSGnv, 2)
                    for cond = 1:size(session_cluster_data.SSGnv, 3)
                        if ~isempty(session_cluster_data.SSGnv{1,loc, cond})
                            struct_idx = find([current_block_data.SSGnv.Location] == loc & ...
                                              [current_block_data.SSGnv.Target_Ori] == condition(cond));
                            if ~isempty(struct_idx)
                                current_block_data.SSGnv(struct_idx).Data = cat(1, current_block_data.SSGnv(struct_idx).Data, session_cluster_data.SSGnv{1, loc, cond});
                                current_block_data.SSGnv(struct_idx).Pic_Ori = cat(1, current_block_data.SSGnv(struct_idx).Pic_Ori, session_cluster_data.SSGnv{2,loc, cond});
                                current_block_data.SSGnv(struct_idx).Target_Ori = condition(cond);
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
                        current_block_data.(block_name)(cond).Data = cat(1, current_block_data.(block_name)(cond).Data, session_cluster_data.(block_name){1,cond});
                        current_block_data.(block_name)(cond).Target_Ori = condition(cond);
                        current_block_data.(block_name)(cond).Pattern = cat(1, current_block_data.(block_name)(cond).Pattern, session_cluster_data.(block_name){3,cond});
                        current_block_data.(block_name)(cond).Pic_Ori = cat(1, current_block_data.(block_name)(cond).Pic_Ori, session_cluster_data.(block_name){2,cond});
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
    location_idx = sprintf('Location%d_%d',config.TrialDataParams.ssglocation(1),config.TrialDataParams.ssglocation(end));
    block_names = fieldnames(processed_data);
    for i = 1:length(block_names)
        current_block_name = block_names{i};
        data_to_save = processed_data.(current_block_name);
        
        if strcmp(config.common.A_B,'B') && strcmp(current_block_name,'SSGnv')
            current_block_name = 'SSGv';
        end
        % Basic check for emptiness before saving
        is_data_empty = false;

        if ~is_data_empty
            if strcmp(current_block_name,'SSGnv')||strcmp(current_block_name,'SSGv')
                save_filename = sprintf('%sSSVEP_%s_%s_%s_%s.mat', file_prefix, days_str, mua_lfp_str,current_block_name,location_idx);
            else
                save_filename = sprintf('%sSSVEP_%s_%s_%s.mat', file_prefix, days_str, mua_lfp_str, current_block_name);
            end
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


