function[orient_matrix, orient_data]=orient_cluster(num, cluster,cluster_data, type, stimIDs_new)
   
%% 
orient_matrix = struct();
    for i = 1:length(num)
        ii = num(i);
        idx = cluster.(sprintf('session%d',ii)).target1;
        matrixsti = stimIDs_new.(sprintf('session%d',ii));
        ori1 = matrixsti(mod(1:72,4)==0,idx);
        if type == 0
            ori2 = floor((ori1-1)/18)+1;
        elseif type == 1
            ori2 = mod(ori1,18);
        elseif type == 2
            ori2 = mod(ori1-floor((ori1-1)/108),18);
        end
    
        for trail = 1:length(ori2(1,:))
            uniqueValues = unique(ori2(:, trail));
            if length(uniqueValues)== 1
                orient_matrix.(sprintf('session%d',ii))(:,trail) = uniqueValues;
            else
                uniqueValues = mode(ori2(:, trail));
                if length(uniqueValues) >1
                    uniqueValues = uniqueValues(find(mod(uniqueValues,2)==0,1));
                end
                orient_matrix.(sprintf('session%d',ii))(:,trail) = uniqueValues;
            end
        end
    end
    %% 

    orient_data = struct();
    for ori = 1:2:17
        orient_data.(sprintf('ori%d',ori)) = struct();
        oo = ori ;
        for i = num
            for trail = 1:length(orient_matrix.(sprintf('session%d',i)))
                if orient_matrix.(sprintf('session%d',i))(:,trail) == oo
                    for coil = 1:96
                        if ~isfield(orient_data.(sprintf('ori%d',ori)), (sprintf('coil%d',coil)))  % 检查字段是否已存在
                            orient_data.(sprintf('ori%d',ori)).(sprintf('coil%d',coil)) = [];
                        end
                        orient_data.(sprintf('ori%d',ori)).(sprintf('coil%d',coil)) = cat(1,orient_data.(sprintf('ori%d',ori)).(sprintf('coil%d',coil)),cluster_data.(sprintf('session%d',i)).(sprintf('coil%d',coil)).target1(trail,1:1640));

                    end
                end
            end
        end
    end
end
