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