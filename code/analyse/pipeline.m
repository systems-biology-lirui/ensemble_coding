clear;
load('D:\Desktop\Ensemble coding\data\datanum.mat');
load('D:\Desktop\Ensemble coding\data\ECpatch_oridata.mat');
days = [16];%天数，不建议多，可能会卡死


%这个是用来数据种类的
block = 'EC';
type = 4; % EC=0,SC=1,patch=2(0815的patch用1),最后一次的EC用4，patch用3；

days_timeseries = struct();
days_timeseries_block = struct();
for day = days

    %这两个是选数据日期的，只要改第二位就行，一共四个
    name = a{1,day};
    time = a{2,day};
    path = sprintf('D:\\Desktop\\Ensemble coding\\data\\%sdata',time);%数据存储路径

    %下面的应该不需要改
    num = datanum.(sprintf('data%s',time)).(block);

    % 导入数据
    [timeseries, stimres, stimIDs, MUAs] = load_matrix(num, name, path);

    % 进行id回溯
    % 这里没删除对于target1和target2的分别，是作为一个检查存在。
    [stimIDs_new] = real_sequence(num, stimres, stimIDs);
    
    %下面的分组内容，如果要做mua，就将timeseries位置改为MUA就行
    if day < 16 %不包括最后一天的
        if type <2 %EC或者SC
            %block分组（target，random，blank）
            [cluster,cluster_data] = clusterdata(num, stimIDs_new, timeseries, type, name);        
            % 分角度(依据target位置分的)
            [orient_matrix, orient_data]=orient_cluster(num, cluster, cluster_data, type,stimIDs_new);
            % tuning
            [ori_tuning] = oriECSC_tuningold(num,type,stimIDs_new,timeseries);

        else %patch
            %block
            [cluster,cluster_data] = patchcluster(num, stimIDs_new, timeseries);
            %ori,location
            [ori_data] = patchcluster2(cluster,num);
            %tuning
            [ori_tuning] = ori_tuningpatchold(num,stimIDs_new,timeseries);
        end
    else%EC相同patch
        if type ==3%patch
            idx1 = [296,177,205,325];
            idx2 = [17,10,12];
            [cluster,clusterdata_patch] = newECpatchcluster(idx1,idx2,num,timeseries);
            [patch_tuning]=neworituning(stimIDs_new,cluster_patch);%tuniing
        elseif type ==4 %EC
            [cluster_EC,EC_tuning_data] = EC_tuning(num,stimIDs_new,timeseries);
        end
    end
 
end



