function [cluster_EC,EC_tuning_data] = EC_tuning(num,stimIDs_new,timeseries)
%给出trail label（EC）
cluster_EC = {};
idx1 = [296,177,205,325];
for i = num+1 
    fieldnn = sprintf('session%d',i-1);
    m = stimIDs_new.(fieldnn)(1,:);
    for mm = 1:length(m)
        n2 =find(idx1==m(mm));
        cluster_EC{i}(mm,1) = n2;
    end
end
%EC     
%定位
load('D:\Desktop\Ensemble coding\data\ECpatch_oridata.mat')
EC_tuning = {};
for m = [0,6]
    fieldnn = sprintf('session%d',m);
    for trail = 1:length(stimIDs_new.(fieldnn)(1,:))
        if stimIDs_new.(fieldnn)(1,trail)~=325
            for flash =1:72
                idx=stimIDs_new.(fieldnn)(flash,trail);
                EC_tuning{m+1}(flash,trail) = mean(fakesaber_1(:,idx),1);
            end
        else
            EC_tuning{m+1}(1:72,trail) = -1;
        end
    end
end

%标准化处理----减基线+归一化
EC_norm = {};
for m = num
    fieldnn = sprintf('session%d',m);
    for trail = 1:160
        for coil = 1:96
            base = mean(squeeze(timeseries.(fieldnn)(trail,coil,1:100)),1);
            data=timeseries.(fieldnn)(trail,coil,370:1540)-base;%取420到1440，但是考虑去时间窗口时候的前后，所以扩大了点
            data1 = normalize(data,3,"range",[0,1]);
            EC_norm{m+1}(trail,coil,:) = data;
        end
    end
end
idx = [];
data = [];
EC_tuning_data = cell(1,18);
for ori =1:18
    for m = [0,6]
        
        for trail = 1:160
            idx = find(EC_tuning{m+1}(:,trail)==10*ori);
            for num = 1:length(idx)
                idx1 = idx(num);
                if idx1>16 && idx1<65
                    data = EC_norm{m+1}(trail,1:96,((idx1-17)*20+51-50):((idx1-17)*20+50+100));%由于数据已经剪切过，因此不需要加100
                    if isempty(EC_tuning_data{ori})
                        EC_tuning_data{ori} = data;
                    else
                        EC_tuning_data{ori} = cat(1,EC_tuning_data{ori},data);
                    end
                end
            end
        end
    end
end