function[cluster,cluster_data] = clusterdata(num, stimIDs_new, timeseries, type,name)
    cluster = struct();
    cluster_data = struct();
    for i = num
        %% 找出target
        a = stimIDs_new.(sprintf('session%d',i));
        mat = a(mod(1:72,4)==0,:);
        if type == 0
            mat1 = floor((mat-1)/18)+1;
        elseif type == 1
            mat1 = mod(mat,18);
        elseif type == 2
            mat1 = mod((mat-floor((mat-1)/108)),18);
        end
        %检查是否值相同
        %% 
        
        uniqueColumns2 = [];%取所有target
        uniqueColumns1 = [];
        aa = [];
        for col = 1:size(mat1, 2)
            uniqueValues = unique(mat1(:, col));
            aa(col) = length(uniqueValues);
            if type == 0
                if length(uniqueValues) <= 1 && uniqueValues ~= 19
                    uniqueColumns1(end+1) = col;
                end
            elseif type == 1
                if length(uniqueValues) <= 1 && mat(1, col) ~= 109
                    uniqueColumns1(end+1) = col;
                end
            elseif type == 2
                if length(uniqueValues) <= 1 && mat(1, col) ~= 1405
                    uniqueColumns1(end+1) = col;
                end
            end
        end
        %% 

        if type == 0
            %% 提取出target，random，blank
            cluster.(sprintf('session%d',i)).target1 = uniqueColumns1;
            cluster.(sprintf('session%d',i)).target2 = uniqueColumns2;
            if name == 738
                cluster.(sprintf('session%d',i)).blank = find(mat(1,:)>379);
            else
                cluster.(sprintf('session%d',i)).blank = find(mat(1,:)>324);
            end
            cluster.(sprintf('session%d',i)).random = setdiff(setdiff(1:66, cluster.(sprintf('session%d',i)).target1),cluster.(sprintf('session%d',i)).blank);
        elseif type == 1
            cluster.(sprintf('session%d',i)).target1 = uniqueColumns1;
            cluster.(sprintf('session%d',i)).target2 = uniqueColumns2;
            cluster.(sprintf('session%d',i)).blank = find(all(mat>=109));
            cluster.(sprintf('session%d',i)).random = setdiff(setdiff(1:66, cluster.(sprintf('session%d',i)).target1),cluster.(sprintf('session%d',i)).blank);
        elseif type == 2
            cluster.(sprintf('session%d',i)).target1 = uniqueColumns1;
            cluster.(sprintf('session%d',i)).target2 = uniqueColumns2;
            cluster.(sprintf('session%d',i)).blank = find(mat(1,:)>=1405);
            cluster.(sprintf('session%d',i)).random = setdiff(setdiff(1:143, cluster.(sprintf('session%d',i)).target1),cluster.(sprintf('session%d',i)).blank);
        end
        %时间序列的分离
        coil_target2_time = [];
        coil_target1_time = [];
        coil_blank_time = [];
        coil_random_time = [];
%         for coil = 1:96
%             for tar = 1:length(cluster.(sprintf('session%d',i)).target1)
%                 tar1 = cluster.(sprintf('session%d',i)).target1(tar);
%                 coil_target1_time(tar,:)=timeseries.(sprintf('session%d',i))(tar1,coil,:);
%             end
%             for tar = 1:length(cluster.(sprintf('session%d',i)).target2)
%                 tar2 = cluster.(sprintf('session%d',i)).target2(tar);
%                 coil_target2_time(tar,:)=timeseries.(sprintf('session%d',i))(tar2,coil,:);
%             end
%             for bl = 1:length(cluster.(sprintf('session%d',i)).blank)
%                 bl1 = cluster.(sprintf('session%d',i)).blank(bl);
%                 coil_blank_time(bl,:)= timeseries.(sprintf('session%d',i))(bl1,coil,:);
%             end
%             for ra = 1:length(cluster.(sprintf('session%d',i)).random)
%                 ra1 = cluster.(sprintf('session%d',i)).random(ra);
%                 coil_random_time(ra,:)=timeseries.(sprintf('session%d',i))(ra1,coil,:);
%             end
%     
%             cluster_data.(sprintf('session%d',i)).(sprintf('coil%d',coil)).target1 = coil_target1_time;
%             cluster_data.(sprintf('session%d',i)).(sprintf('coil%d',coil)).target2 = coil_target2_time;
%             cluster_data.(sprintf('session%d',i)).(sprintf('coil%d',coil)).random = coil_random_time;
%             cluster_data.(sprintf('session%d',i)).(sprintf('coil%d',coil)).blank = coil_blank_time;
%         end
        for coil = 1:96
            for tar = 1:length(cluster.(sprintf('session%d',i)).target1)
                tar1 = cluster.(sprintf('session%d',i)).target1(tar);
                coil_target1_time(tar,:)=timeseries.(sprintf('session%d',i))(tar1,coil,:);
            end
            for tar = 1:length(cluster.(sprintf('session%d',i)).target2)
                tar2 = cluster.(sprintf('session%d',i)).target2(tar);
                coil_target2_time(tar,:)=timeseries.(sprintf('session%d',i))(tar2,coil,:);
            end
            for bl = 1:length(cluster.(sprintf('session%d',i)).blank)
                bl1 = cluster.(sprintf('session%d',i)).blank(bl);
                coil_blank_time(bl,:)= timeseries.(sprintf('session%d',i))(bl1,coil,:);
            end
            for ra = 1:length(cluster.(sprintf('session%d',i)).random)
                ra1 = cluster.(sprintf('session%d',i)).random(ra);
                coil_random_time(ra,:)=timeseries.(sprintf('session%d',i))(ra1,coil,:);
            end
    
            cluster_data.(sprintf('session%d',i)).(sprintf('coil%d',coil)).target1 = coil_target1_time;
            cluster_data.(sprintf('session%d',i)).(sprintf('coil%d',coil)).target2 = coil_target2_time;
            cluster_data.(sprintf('session%d',i)).(sprintf('coil%d',coil)).random = coil_random_time;
            cluster_data.(sprintf('session%d',i)).(sprintf('coil%d',coil)).blank = coil_blank_time;
        end
        %t_b = mean(coil_target_time,1)-mean(coil_blank_time,1);
    
    end
end
