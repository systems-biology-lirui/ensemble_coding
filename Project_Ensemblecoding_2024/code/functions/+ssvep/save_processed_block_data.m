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
