figure;
for i = 1:94
    if ismember(i,leftchanel)
        color = 'b';
    else
        color = 'r';
    end
hold on;viscircles([SPNLY.xlocation(i),SPNLY.ylocation(i)],SPNLY.radius(i),'Color',color);
end
%%
label = 'MGv';
QQ_old = load(sprintf('D:\\ensemble_coding\\QQdata\\Processed_Event\\QQ_EVENT_Days2_27_MUA2_%s.mat',label));
QQ_new = load(sprintf('D:\\ensemble_coding\\QQdata\\Processed_Event\\QQ_EVENT_Days39_42_MUA2_%s.mat',label));
for location =1
    disp(location)
data1 = [];
for ori = 1:18
data1(:,ori,:) = squmean(QQ_old.(label)(ori+(location-1)*18).Data(1:162,1:94,:),1);
end
data2 = [];
for ori = 1:18
data2(:,ori,:) = squmean(QQ_new.(label)(ori+(location-1)*18).Data(1:80,:,:),1);
end
data = cat(2,mean(data1,2),mean(data2,2));
ChannelMap_LR(data,'QQ','line',1:100);
end
%%
nn = cell(100,5);
for t = 1:100
    for f = 1:5
        dd = mm{t, f}(2, 1).Linear;
        nn{t,f} = dd;
    end
    n1(t,:) = squmean(cat(2,nn{t,:}),2);
end
nn = cell(100,5);
for t = 1:100
    for f = 1:5
        dd = mm1{t, f}(2, 1).Linear;
        nn{t,f} = dd;
    end
    n2(t,:) = squmean(cat(2,nn{t,:}),2);
end
for t = 1:100
    w_A = n1(t,:);
    w_B = n2(t,:);
    
    % --- 计算两个向量的角度差 ---
    % 公式: cos(theta) = (wA · wB) / (||wA|| * ||wB||)
    cos_theta = dot(w_A, w_B) / (norm(w_A) * norm(w_B));
    
    % 处理浮点数精度问题，确保cos_theta在[-1, 1]范围内
    cos_theta = max(min(cos_theta, 1), -1);
    
    angle_rad = acos(cos_theta);
    angle_deg = rad2deg(angle_rad);
    
    % 解码向量的方向是任意的（w 和 -w 定义的是同一个超平面）
    % 因此，我们通常关心的是它们之间的锐角，即它们所定义的“解码轴”的相似度
    acute_angle_deg = min(angle_deg, 180 - angle_deg);
    
    angle_diffs(t) = angle_deg;
end
plot(angle_diffs)

%%
for ori = 1:18
    SG(ori).Data = SG(ori).Data(1:80,:,:);
end

channnels = [46,81,74];
data = cat(4,SG.Data);
meanori_sg = squmean(data,4);
plotdata = squmean(data(:,channnels,:,:),4);
figure;
stdline_LR(permute(plotdata,[1,3,2]));
%%
for ori = 1:18
    for pattern = 1:6
        idx = (ori-1)*18+(pattern-1)*3+1;
        data(ori,pattern,:,:,:) = FigureOriMap.EC(:,idx,:,:);
    end
end
data = permute(data,[2,3,4,5,1]);
decodingdata = reshape(data,[6*15,126,95,18]);
decodingdata = permute(decodingdata,[4,1,3,2]);
selected_coil_final=[74,67,68,72,45,38,40,86,7,87,58,91,92,25,94,29,64,61,56,30];
[acc_real_mean1, p_value, perm_accuracies_mean,detailed_results,mm] = SVM_Decoding_LR(decodingdata(:,:,selected_coil_final,:),0,50);


decodingdata = [];
for ori = 1:18
    decodingdata(ori,:,:,:) = MGnv(ori).Data(1:85,:,:);
end
selected_coil_final=[74,67,68,72,45,38,40,86,7,87,58,91,92,25,94,29,64,61,56,30];
[acc_real_mean1, p_value, perm_accuracies_mean,detailed_results,mm] = SVM_Decoding_LR(decodingdata(:,:,selected_coil_final,:),0,50);
hold on
plot(acc_real_mean1)
plot(11:110,smooth(acc_real_mean1))

mgnvdata_nor = mgnvdata - squmean(mgnvdata(:,1:30),2);
mgvdata_nor = mgvdata - squmean(mgvdata(:,1:30),2);
for t = 1:100
    corl(t) = corr2(lr.mgnvdata(:,t),lr.mgvdata(:,t));
end
figure;
plot(corl)


%% 构建EVENT的拟合和残差结果
a = {'DG','QQ','QQ'};
b = {'DG','QQ_old','QQ_new'};
c = {'LFP','MUA2'};
d = [25,29; 2,27; 39,42];
e = [140;162;83];
label = {'MGnv','SSGnv'};
load('sel_channel_Yge.mat','sel_channel');

for macaque_idx = 3
    macaque = a{macaque_idx};
    file_path = sprintf('D:/ensemble_coding/%sdata/Processed_Event/',macaque);
    for data_idx = 1:2
        mua_lfp = c{data_idx};
        channels = sel_channel.(b{macaque_idx});
        
        % subtitles = {'channelsnum = 20','channelsnum = 45','channelsnum = 20','channelsnum = 45'};

        for i = 1:length(label)
            data_date = d(macaque_idx,:);
            filename = sprintf('%s_EVENT_Days%d_%d_%s_%s.mat',macaque,data_date(1),data_date(2),mua_lfp,label{i});
            file_idx{i} = fullfile(file_path,filename);
            load(file_idx{i});
        end
        for ori = 1:18
            channelnum = 96;
            meanssg = zeros(96,100,12,'single');
            if macaque_idx == 3
                meanssg = zeros(94,100,12,'single');
                channelnum = 94;
            end
            for location = 1:12
                idx = (location-1)*18 + ori;
                meanssg(:,:,location) = squmean(SSGnv(idx).Data(:,1:channelnum,:),1);
            end
            meanmgnv = squmean(MGnv(ori).Data(:,1:channelnum,:),1);
            [all_r_squared, all_weights, ~] = trial_fitting(meanmgnv, meanssg, 'linear_constrained', [31,100]);
        end
        detail.(b{macaque_idx}).(mua_lfp).R = all_r_squared;
        detail.(b{macaque_idx}).(mua_lfp).W = all_weights;
        for ori = 1:18
            fitMGnv(ori).BlockName = 'fitMGnv'; 
            fitMGnv(ori).Pic_Ori = ori; 
            fitMGnv(ori).Data = zeros(e(macaque_idx),channelnum,100,'single');
            resMGnv(ori).BlockName = 'resMGnv'; 
            resMGnv(ori).Pic_Ori = ori; 
            resMGnv(ori).Data = zeros(e(macaque_idx),channelnum,100,'single');
            for location = 1:12
                idx = (location-1)*18 + ori;
                for trial = 1:e(macaque_idx)
                    for channel = 1:channelnum
                        dd = single(squeeze(SSGnv(idx).Data(trial,channel,:))*all_weights(channel,location));
                        fitMGnv(ori).Data(trial,channel,:) = fitMGnv(ori).Data(trial,channel,:)+reshape(dd,[1,1,100]);
                    end
                end
            end
            resMGnv(ori).Data = MGnv(ori).Data(1:e(macaque_idx),1:channelnum,:)-fitMGnv(ori).Data;
        end
        outputlabel = {'fitMGnv','resMGnv'};
        for i = 1:length(outputlabel)
            data_date = d(macaque_idx,:);
            filename = sprintf('%s_EVENT_Days%d_%d_%s_%s.mat',macaque,data_date(1),data_date(2),mua_lfp,outputlabel{i});
            file_idx{i} = fullfile(file_path,filename);
            save(file_idx{i},outputlabel{i});
        end
    end
        
end
