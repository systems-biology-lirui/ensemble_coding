function [patch_tuning]=neworituning(stimIDs_new,cluster_patch)
load('D:\Desktop\Ensemble coding\data\ECpatch_oridata.mat')
%提取出ECtrail 的ori
oriidx = {stimIDs_new.session0(:,1);stimIDs_new.session0(:,2);stimIDs_new.session0(:,3)}
for i =1:3
    for j =1:72
        oriidx{i}(j,2:13) = fakesaber_1(:,oriidx{i}(j,1))';
        oriidx{i}(j,14) = mean(oriidx{i}(j,2:13),2);
    end
end

%由于只有三种trail，可以直接对应的上
load('d:/desktop/labelnew.mat');
ori_patch = {};
nonEmptyIndices = find(~cellfun('isempty', cluster_patch));
for i = nonEmptyIndices
    for trail = 1:length(cluster_patch{i}(:,1))
        idx1 = cluster_patch{i}(trail,1);
        idx2 = cluster_patch{i}(trail,3);
        if idx1 <4
            if idx2 <13
                ori_patch{i}(trail,:) = oriidx{idx1}(:,idx2+1);
            else
                ori_patch{i}(trail,:) = oriidx{idx1}(:,14);
            end
        else
            ori_patch{i}(trail,:) = -1;%代表空
        end
    end
end
%ori还是分成18个角度吧，采用四舍五入的方法
ori_patch1 = {};
for i = nonEmptyIndices
    ori_patch1{i} = round(ori_patch{i}/10)*10;
end
%0 to 180，结果发现有些位置会缺角度
for i = nonEmptyIndices
    for trail = 1:length(cluster_patch{i}(:,1))
        if cluster_patch{i}(trail,3) ~= 0
            idx3 = find(ori_patch1{i}(trail,:)==0);
            ori_patch1{i}(trail,idx3) = 180;
        end
    end
end
patch_tuning = cell(18,12);
nonEmptyIndices = find(~cellfun('isempty', cluster_patch));
for ori = 1:18
    for location = 1:12
        for i = nonEmptyIndices
            fieldnn = sprintf('session%d',i);            
            idxtu1 = find(cluster_patch{i}(:,3)==location);
            for trail = 1:length(idxtu1)
                trail1 = idxtu1(trail);
                idxtu2 = find(ori_patch1{i}(trail1,:)==ori*10);
                if ~isempty(idxtu2)
                    for nu = 1:length(idxtu2)
                        idxtu3 = idxtu2(nu)
                        if idxtu3>16 & idxtu3 <65
                            data = timeseries.(fieldnn)(trail1,:,100+idxtu3*20-50:100+idxtu3*20+100);%时间 窗口
                            if isempty(patch_tuning{ori,location})
                                patch_tuning{ori,location}=data;
                            else
                                patch_tuning{ori,location} = mean(cat(1,patch_tuning{ori,location},data),1);
                            end
                        end
                    end
                end
            end
        end
    end
end

