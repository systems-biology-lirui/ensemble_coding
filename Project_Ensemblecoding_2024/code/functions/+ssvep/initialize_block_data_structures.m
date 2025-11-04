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