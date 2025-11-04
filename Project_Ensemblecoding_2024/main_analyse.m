% =========================================================================
%               MAIN ANALYSIS SCRIPT FOR SSVEP MACAQUE PROJECT
% =========================================================================
% This script serves as the main entry point for the entire analysis pipeline.
%
% To run the analysis:
% 1. Adjust the parameters in the "USER SETTINGS" section below.
% 2. Run this script from the MATLAB command window or editor.
%
% The script will automatically set up paths, load configurations, and
% execute the selected pipeline stages.
% =========================================================================

%% 1. INITIALIZE ENVIRONMENT
clear;                      % Clear workspace
clc;                        % Clear command window
close all;                  % Close all figures
dbstop if error;            % Enter debugger on error
rng('default');             % Reset random number generator for reproducibility

% <<<--- START: NEW CODE FOR LOGGING --- >>>
% --- Setup a dedicated log file for this run ---
log_dir = fullfile(fileparts(mfilename('fullpath')), 'logs');
if ~exist(log_dir, 'dir'), mkdir(log_dir); end

% Create a unique log file name with a timestamp
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
log_filename = fullfile(log_dir, sprintf('analysis_log_%s.txt', timestamp));

% Turn on logging to this file. All command window output will be saved.
diary(log_filename);

% Open the log file in the MATLAB editor to view output in real-time
edit(log_filename);
fprintf('Command window output is being logged to:\n%s\n\n', log_filename);
% <<<--- END: NEW CODE FOR LOGGING --- >>>

fprintf('============================================================\n');
fprintf('Initializing SSVEP Macaque Analysis Pipeline...\n');
fprintf('============================================================\n');

%% 2. SETUP PROJECT PATHS
% This section dynamically adds the necessary code folders to the MATLAB path.
% It ensures that the project is self-contained and runs on any machine.

% Get the full path to the directory where this script is located
project_root = fileparts(mfilename('fullpath'));
if isempty(project_root)
    project_root = pwd; % Fallback for running sections in editor
end

% Add the 'code' directory and all its subdirectories to the path
addpath(genpath(fullfile(project_root, 'code')));

fprintf('Project Root Directory: %s\n', project_root);
fprintf('Added ''code'' directory and its subdirectories to MATLAB path.\n\n');


%% 3. USER SETTINGS
% This is the primary section for user configuration.
% Adjust these settings to control which data is processed and which
% analysis stages are executed.
% -------------------------------------------------------------------------

% --- Top-Level Choices ---
USER_SETTINGS.MACAQUE_TO_PROCESS = 'QQ'; % Options: 'DG', 'QQ'

% --- Pipeline Stage Flags (true = run, false = skip) ---
USER_SETTINGS.RUN_SIGNAL_EXTRACTION = true;
USER_SETTINGS.RUN_DECODING          = false;
USER_SETTINGS.RUN_PLOTTING          = false;

% --- Key Parameters for Signal Extraction (Example from your original code) ---
% NOTE: More complex parameters like 'preidx' will be moved into the config file later.
% We keep simple, high-level choices here.
USER_SETTINGS.A_B                     = 'A';     % Which experimental set ('A' or 'B')
USER_SETTINGS.EXTRACTION_DATA_TYPE    = 'MUA2';  % 'MUA1', 'MUA2', 'LFP'
USER_SETTINGS.EXTRACTION_BLOCKS       = {'MGv'};
USER_SETTINGS.EXTRACTION_SSG_LOCATION = 1:13;


%% 4. LOAD FULL EXPERIMENT CONFIGURATION
% This function reads the USER_SETTINGS and loads all detailed paths,
% parameters, and metadata locations into a single 'config' struct.
% The project_root is passed to build relative paths.

fprintf('Loading experiment configuration for macaque: %s...\n', USER_SETTINGS.MACAQUE_TO_PROCESS);
config = get_experiment_config(project_root, USER_SETTINGS);
fprintf('Configuration loaded successfully.\n\n');


%% 5. EXECUTE ANALYSIS PIPELINE
% This section calls the main functions for each stage of the analysis
% based on the flags set in USER_SETTINGS.

fprintf('------------------------------------------------------------\n');
fprintf('Starting Pipeline Execution...\n');
fprintf('------------------------------------------------------------\n\n');

% --- Stage 1: Signal Extraction ---
if config.run_flags.signal_extraction
    fprintf('====== STAGE 1: SIGNAL EXTRACTION ======\n');
    run_signal_extraction(config); % This function will be moved to code/scripts/
    fprintf('====== STAGE 1: COMPLETE ======\n\n');
else
    fprintf('Skipping Stage 1: Signal Extraction.\n\n');
end

% --- Stage 2: Decoding ---
if config.run_flags.decoding
    fprintf('====== STAGE 2: DECODING ANALYSIS ======\n');
    run_decoding_analysis(config); % This function will be moved to code/scripts/
    fprintf('====== STAGE 2: COMPLETE ======\n\n');
else
    fprintf('Skipping Stage 2: Decoding Analysis.\n\n');
end

% --- Stage 3: Plotting ---
if config.run_flags.plotting
    fprintf('====== STAGE 3: PLOTTING RESULTS ======\n');
    run_plotting(config); % This function will be moved to code/scripts/
    fprintf('====== STAGE 3: COMPLETE ======\n\n');
else
    fprintf('Skipping Stage 3: Plotting Results.\n\n');
end

fprintf('============================================================\n');
fprintf('All selected processes for %s have finished.\n', config.macaque_name);
fprintf('============================================================\n');
diary off;
fprintf('Logging stopped. Final log saved to %s\n', log_filename);