function config = get_experiment_config(project_root, USER_SETTINGS)
% GET_EXPERIMENT_CONFIG - Creates a comprehensive configuration structure for the SSVEP analysis.
%
% This function takes high-level user settings and the project's root directory
% to generate a detailed 'config' struct containing all necessary paths and
% parameters for the analysis pipeline.
%
% USAGE:
%   config = get_experiment_config(project_root, USER_SETTINGS);
%
% INPUTS:
%   project_root - String. The absolute path to the project's root folder.
%   USER_SETTINGS - Struct. A struct containing user-defined choices from main_analysis.m.
%
% OUTPUTS:
%   config - Struct. A detailed configuration struct used by all subsequent scripts.

    %% 1. TRANSFER USER SETTINGS & BASIC INFO
    config.macaque_name = upper(USER_SETTINGS.MACAQUE_TO_PROCESS);
    config.is_DG = strcmpi(config.macaque_name, 'DG');
    config.is_QQ = strcmpi(config.macaque_name, 'QQ');

    % --- Run Flags ---
    config.run_flags.signal_extraction = USER_SETTINGS.RUN_SIGNAL_EXTRACTION;
    config.run_flags.decoding          = USER_SETTINGS.RUN_DECODING;
    config.run_flags.plotting          = USER_SETTINGS.RUN_PLOTTING;

    % --- Common Settings ---
    config.common.A_B             = USER_SETTINGS.A_B;
    config.common.MUA_LFP_options = {'MUA1','MUA2','LFP'};
    config.common.all_block_names = {'MGv', 'MGnv', 'SG', 'SSGnv', 'blank'};


    %% 2. DEFINE SESSION INDICES (Replaces 'preidx')
    % This section makes the cryptic 'preidx' variable human-readable.
    session_indices.QQ_A     = [1,5:8,11:13,15,17,18,21:23,25:27];
    session_indices.QQ_B     = [9,10,14,16,19,20,24,27,28,29];
    session_indices.DG_A     = [3:15];
    session_indices.DG_B     = [16:23];

    % Select the correct indices based on user settings
    selected_indices_field = [config.macaque_name, '_', config.common.A_B];
    if isfield(session_indices, selected_indices_field)
        extraction_days = session_indices.(selected_indices_field);
    else
        % Fallback for cases like 'QQ_A_new' if you want to handle them
        warning('Session indices for %s not explicitly defined. Check logic.', selected_indices_field);
        extraction_days = [];
    end

    %% 3. SET PROCESSING PARAMETERS
    % --- Signal Extraction Parameters ---
    config.process_params.Days            = extraction_days;
    config.process_params.MUA_LFP         = USER_SETTINGS.EXTRACTION_DATA_TYPE;
    config.process_params.selected_blocks = USER_SETTINGS.EXTRACTION_BLOCKS;

    % --- TrialDataRearrange Parameters ---
    config.TrialDataParams.condition       = -1:2:17;
    config.TrialDataParams.triallength     = 1:1640;
    config.TrialDataParams.ssglocation     = USER_SETTINGS.EXTRACTION_SSG_LOCATION;

    % --- ReFactor Field Names (Dataset-specific constants) ---
    config.ReFactorFields.block           = 'Block';
    config.ReFactorFields.stim_sequence   = 'Stim_Sequence';
    config.ReFactorFields.pattern         = 'Pattern';
    config.ReFactorFields.location        = 'Location';


    %% 4. DEFINE ALL PATHS RELATIVE TO PROJECT ROOT
    % This is the core of making the project portable. NO MORE HARDCODED PATHS.
    
    data_base_path    = fullfile(project_root, 'data');
    results_base_path = fullfile(project_root, 'results');

    % --- Input Paths ---
    macaque_raw_data_path = fullfile(data_base_path, 'raw', config.macaque_name);
    
    config.paths.raw_data_input = fullfile(macaque_raw_data_path, '500hzdata');
    config.paths.stim_info      = fullfile(macaque_raw_data_path, 'metadata', [config.macaque_name, '_metadata_SSVEP.mat']);
    config.paths.session_idx    = fullfile(macaque_raw_data_path, 'metadata', [config.macaque_name, 'SessionIdx.mat']);

    % --- Output Paths ---
    config.paths.processed_data_output   = fullfile(data_base_path, 'processed', config.macaque_name);
    config.paths.decoding_results_output = fullfile(results_base_path, 'decoding', config.macaque_name); % Example for decoding results

    % --- Ensure Output Directories Exist ---
    if ~exist(config.paths.processed_data_output, 'dir'); mkdir(config.paths.processed_data_output); end
    if ~exist(config.paths.decoding_results_output, 'dir'); mkdir(config.paths.decoding_results_output); end


    %% 5. VALIDATE SETTINGS
    % This section ensures that user inputs are valid before starting the heavy processing.
    if ~ismember(config.process_params.MUA_LFP, config.common.MUA_LFP_options)
        error('Invalid EXTRACTION_DATA_TYPE: "%s". Choose from: %s', config.process_params.MUA_LFP, strjoin(config.common.MUA_LFP_options, ', '));
    end
    
    if any(~ismember(config.process_params.selected_blocks, config.common.all_block_names))
        invalid_blocks = config.process_params.selected_blocks(~ismember(config.process_params.selected_blocks, config.common.all_block_names));
        error('Invalid block name(s) in USER_SETTINGS.EXTRACTION_BLOCKS: %s', strjoin(invalid_blocks, ', '));
    end

    if config.is_DG == false && config.is_QQ == false
        error('Invalid MACAQUE_TO_PROCESS: "%s". Choose "DG" or "QQ".', config.macaque_name);
    end

end