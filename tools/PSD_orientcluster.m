function[tar_ran_orient_data, tar_orient_data] = PSD_orientcluster(num, orient_matrix)
    tar_ran_orient_data = struct();
    for ori = 1:18
        tar_ran_orient_data.(sprintf('ori%d',ori)) = struct();
        oo = ori;
        for i = num
            load(fullfile('D:\Desktop',sprintf('ECtar_ransession%d.mat',i)));
            for trail = 1:length(orient_matrix.(sprintf('session%d',i)))
                if orient_matrix.(sprintf('session%d',i))(:,trail) == oo
                    for coil = 1:96
                        if ~isfield(tar_ran_orient_data.(sprintf('ori%d',ori)), (sprintf('coil%d',coil)))  % 检查字段是否已存在
                            tar_ran_orient_data.(sprintf('ori%d',ori)).(sprintf('coil%d',coil)) = [];
                        end
                        tar_ran_orient_data.(sprintf('ori%d',ori)).(sprintf('coil%d',coil)) = cat(1,tar_ran_orient_data.(sprintf('ori%d',ori)).(sprintf('coil%d',coil)),tar_ran.(sprintf('session%d',i)).(sprintf('coil%d',coil)).target_ra(trail,:));
                        
                    end
                end
            end
            clear tar_ran
        end
    end
    save("tar_ran_orient_data.mat","tar_ran_orient_data")
    clear tar_ran_orient_data
    
%     tar_orient_data = struct();
%     for ori = 1:18
%         tar_orient_data.(sprintf('ori%d',ori)) = struct();
%         oo = ori;
%         for i = num
%             load(fullfile('D:\Desktop',sprintf('ECtar_ransession%d.mat',i)));
%             for trail = 1:length(orient_matrix.(sprintf('session%d',i)))
%                 if orient_matrix.(sprintf('session%d',i))(:,trail) == oo
%                     for coil = 1:96
%                         if ~isfield(tar_orient_data.(sprintf('ori%d',ori)), (sprintf('coil%d',coil)))  % 检查字段是否已存在
%                             tar_orient_data.(sprintf('ori%d',ori)).(sprintf('coil%d',coil)) = [];
%                         end
%                         tar_orient_data.(sprintf('ori%d',ori)).(sprintf('coil%d',coil)) = cat(1,tar_orient_data.(sprintf('ori%d',ori)).(sprintf('coil%d',coil)),tar_ran.(sprintf('session%d',i)).(sprintf('coil%d',coil)).target(trail,:));
%                         
%                     end
%                 end
%             end
%             clear tar_ran
%         end
%     end
%     save("tar_orient_data.mat","tar_orient_data")
%     clear tar_orient_data
end