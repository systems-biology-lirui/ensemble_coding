%% linshi
session_idxall{1} = [14:16,1:13];
session_idxall{2} = [1:13,16,15,NaN];
session_idxall{3} = [1:14,NaN,16];
session_idxall{4} = [1:14,16,15];
session_idxall{5} = [1:16];
all_data = cell(1,16);
for dayday = 1:5
    session_idx = session_idxall{dayday};
    ori_idx = cell(length(session_idx),1);
    for session =1:length(session_idx)
        
        if ~isnan(session_idx(session))
            load(sprintf('/home/dclab2/Ensemble coding/data/12%02ddata/DG2-u78%d-%03d-500Hz.mat',dayday+8,dayday+1,session-1));
            trailnum = 6916;
            TrialStimID=reshape(Datainfo.Seq.StimID,[52 trailnum/52])';
            RealOrdid = [];
            RealOrdbuffid = TrialStimID;
            RealOrdbufferrorid = [];
            for kk = 1:length(Datainfo.VSinfo.sMbmInfo.respCode)
                RealOrdid = [RealOrdid;RealOrdbuffid(kk,:)];
                if Datainfo.VSinfo.sMbmInfo.respCode(kk)==1
                else
                    RealOrdbuffid = cat(1,RealOrdbuffid,RealOrdbuffid(kk,:));
                end
            end
            RealTrialID=find(Datainfo.VSinfo.sMbmInfo.respCode==1);
            StimID=RealOrdid(RealTrialID,:);
            
            StimID = StimID';
            %%patch
            if session_idx(session) < 14 
                ori = [];
                for x = 1:52
                    for y = 1:133
                        if StimID(x,y) ~=1405
                            ori(x,y) =mod(StimID(x,y)-(session_idx(session)-1)*108,18);
                            if ori(x,y)==0
                                ori(x,y)=18;
                            end
                        else
                            ori(x,y) = 19;
                        end
                    end
                end
                
                %%EC
            elseif session_idx(session) ==14|| session_idx(session) > 16
                ori = [];
                for x = 1:52
                    for y = 1:133
                        if StimID(x,y) ~=325
                            ori(x,y) =floor((StimID(x,y)-1)/18+1);
                        else
                            ori(x,y) = 19;
                        end
                    end
                end
                %%SC
            else
                ori = [];
                for x = 1:52
                    for y = 1:133
                        if StimID(x,y) ~=109
                            ori(x,y) =mod(StimID(x,y),18);
                            if ori(x,y)==0
                                ori(x,y)=18;
                            end
                        else
                            ori(x,y) = 19;
                        end
                    end
                end
            end
            ori_idx{session}=ori;
            orientation_data = cell(2,19);
            for trial = 1:133
                for block = 1:4
                    window = (100+260*(block-1)+1):(100+260*(block-1)+1)+100;
                    
                    baseline = squeeze(mean(Datainfo.trial_MUA{2}(trial,1:96,1:100),3));
                    MUA = squeeze(Datainfo.trial_MUA{2}(trial,1:96,window))-baseline';
                    %LFP = Datainfo.trial_LFP(trial,1:96,window);
                    orientation = ori(1+13*(block-1),trial);
                    orientation_data{1,orientation} = cat(3,orientation_data{1,orientation},MUA);
                    %orientation_data{2,orientation} = cat(1,orientation_data{2,orientation},LFP);
                end
            end
            if isempty(all_data{session_idx(session)})
                all_data{session_idx(session)} = orientation_data;
            else
                for y= 1:19
                    for x = 1:1
                        all_data{session_idx(session)}{x,y} = orientation_data{x,y}+all_data{session_idx(session)}{x,y};
                    end
                end
            end
            clearvars -except all_data session session_idx ori_idx session_idxall dayday
            disp(session)
        end
        
    end
end


    %%
%     for orientation = 1:18
%         plot(squeeze(mean(orientation_data{1,orientation}(:,96,:),1)))
%         hold on
%     end
%     hold off
%     %%
%     for trial = 1:28
%         plot(squeeze(orientation_data{1,1}(trial,96,:)));
%         hold on
%     end
%     %%
data1 = cell(16,2);
for session = 1:16
    for i = 1
        data1{session,i} = zeros(96,101);
        for orientation = 1:18
            data = squeeze(mean(all_data{session}{i,orientation},3));
            data1{session,i} =data1{session,i}+data;
        end
    end
end

fs = 500;
cutoff_frequency = 49;  % 截止频率为49 Hz
order = 4;              % 滤波器的阶数

% 设计巴特沃斯低通滤波器
[b, a] = butter(order, cutoff_frequency/(fs/2), 'low');
for x = 1:16
    for coil = 1:96
        data2{x,1}(coil,:) = filtfilt(b,a,data1{x,1}(coil,:));
    end
end
for x= 1:16
    aa(x,:) = data1{x,1}(18,:);
end
aa =aa';
%%
for coil = 1:32
for coil2 = 1:32
test1=corrcoef(filtfilt(b,a,testdata2(coil,:)),filtfilt(b,a,testdata2(coil2,:)));
pearsonmatrix2(coil,coil2)=test1(1,2);
end
end
%%
for coil = 1:96
for coil2 = 1:96
test1=corrcoef(filtfilt(b,a,newtest(coil,:)),filtfilt(b,a,newtest(coil2,:)));
pearsonmatrix(coil,coil2)=test1(1,2);
end
end
%%
 load('/home/dclab2/Ensemble coding/data/chanmap.mat')
 for coil = 1:96
     
     n = find(ChanMap == coil);
     subplot(10,10,n)
     for location = 1:14
         
         plot(smooth(data2{location,1}(coil,:)));
         hold on
     end
     subtitle(coil)
end
%%
for session = 1:17
    for orientation = 1:18
        for coil = 1:96
            tuning_curve{session}(coil,orientation) = max(smooth(squeeze(data1{session,1}(coil,1:50,orientation+1)),5));
        end
    end
end
%%
for coil = 1:96
    tuning_matrix = zeros(1,18);
    for session = 4:16
        
        tuning_matrix = cat(1,tuning_matrix,tuning_curve{session-3}(coil,:));
    end 
    coil_cor= corr(tuning_matrix(2:end,:));
    correlationMatrixNoDiag = coil_cor;
    correlationMatrixNoDiag(logical(eye(size(coil_cor)))) = NaN;
    ccc(coil) = nanmean(correlationMatrixNoDiag(:));
end
%%
for coil = 1:96
    load('/home/dclab2/Ensemble coding/data/chanmap.mat')
    n = find(ChanMap == coil);
    subplot(10,10,n)
    for location = 1:17
        data2(location,:) =normalize(tuning_curve{1,location}(coil,:));
    end
    imagesc(data2);
    subtitle(coil)
end
%%
hold on 
for i = 4:16
plot(smooth(data1{i,1}(63,:),5))
end
%%
load('/home/dclab2/Ensemble coding/data/chanmap.mat')
figure;
for coil = 1:96
    for session = 1:3
        n = find(ChanMap == coil);
        subplot(10,10,n)
        plot(data1{session,1}(coil,:));
        hold on
    end
    hold off
    subtitle(coil)
    
end
legend('PATCH','EC','SC','EC0');
sgtitle('MUA')
%%
figure;
hold on; % 将 hold on 放在循环外

for session =1:16
    % 获取平滑的数据
    smoothedData = smooth(data1{session, 1}(20, :), 6);
    
    % 设置线宽和颜色
    if session >= 1 && session <= 3
        lineWidth = 2; % 线宽为 2
        color = 'b';   % 颜色为默认的蓝色
    else
        lineWidth = 1; % 线宽为 1
        color = [0.5, 0.5, 0.5]; % 灰色，使用RGB格式
    end
    
    % 绘制图形
    plot(smoothedData, 'LineWidth', lineWidth);
end


plot(smooth(sumdata(18,:)/12,7))
hold off
title('Coil95-LFP')
%%
figure;
for coil = 1:96
    for session = 1:4
        n = find(ChanMap == coil);
        subplot(10,10,n)
        plot(data1{session,2}(coil,:));
        hold on
    end
    hold off
    subtitle(coil)
    
end
legend('PATCH','EC','SC','EC0');
title('LFP')

figure;
for session = 1:4
    plot(data1{session,2}(95,:));
    hold on 
end
hold off
legend('PATCH','EC','SC','EC0');
title('Coil95-LFP')
%%

%% 参数设置
coil_select = 1:96;
numNeurons = length(coil_select);%channels
numOrientations = 18;
trials = 28;
epsilon = 1 / trials;

for session = 1:16
    for type = 1:2
        
        for time = 1:260
            %% 生成模拟数据
            tuningCurves = zeros(length(coil_select),18);
            for coil = coil_select
                for ori = 1:numOrientations
                    if time > 1 && time<260
                        window = (time-1):(time+1);
                    elseif time == 1
                        window = time:time+1;
                    else
                        window = time-1:time;
                    end
                    %             tuningCurves(coil,ori) = mean(nobefore{ori}(coil,window),2);
                    tuningCurves(coil,ori) =squeeze(mean(mean(all_data{session}{type,ori}(:,coil,window),1),3));
                end
            end
            
            %% 模拟神经元放电数据
            spikes = zeros(numNeurons, numOrientations, trials);
            for i = 1:numNeurons
                for j = 1:numOrientations
                    spikes(i, j, :) = squeeze(mean(all_data{session}{type,j}(:,i,window),3));
                end
            end
            
            
                %% 将数据重构为矩阵形式
                orientations = deg2rad(([1:18]+0)*10);
                %orientations = 1:18;
                
                % X 是特征矩阵，y 是标签向量
                X = reshape(spikes, numNeurons, [])';
                y = repmat(orientations, 1, trials)';
                
                % 交叉验证设置
                K = 10; % 折数
                indices = crossvalind('Kfold', length(y), K);
                errors = zeros(K, 1);
                
                % 交叉验证
                for k = 1:K
                    % 创建训练集和测试集
                    testIdx = (indices == k);
                    trainIdx = ~testIdx;
                    
                    X_train = X(trainIdx, :);
                    y_train = y(trainIdx);
                    X_test = X(testIdx, :);
                    y_test = y(testIdx);
                    
                    % 训练线性回归模型
                    B = X_train \ y_train; % 简单线性回归
                    
                    % 进行预测
                    y_pred = X_test * B;
                    
                    % 计算误差
                    errors(k) = mean(abs(mod(y_pred - y_test + pi, 2*pi) - pi) < pi / 36);
                    model(k,:) = B;
                end
                
                % 计算平均精度
                averageAccuracy{session,type}(time) = mean(errors);
            
            %fprintf('平均解码精度: %.2f%%\n', averageAccuracy * 100);
            
        end
        
    end
    disp(session)
end


%%

    for session = 14:16
    
    plot(smooth(averageAccuracy{session,1},8));
    hold on
    end
    hold off

    
%% 计算前后是否存在影响

%% linshi
session_idxall{1} = [14:16,1:13];
session_idxall{2} = [1:13,16,15,NaN];
session_idxall{3} = [1:14,NaN,16];
session_idxall{4} = [1:14,16,15];
session_idxall{5} = [1:16];
all_ori_ori = cell(1,16);
fs = 500;
cutoff_frequency = 49;  % 截止频率为49 Hz
order = 4;              % 滤波器的阶数

% 设计巴特沃斯低通滤波器
[b, a] = butter(order, cutoff_frequency/(fs/2), 'low');
for condition = 1:16
    all_ori_ori{condition} = cell(19,19);
end

for dayday = 1:5
    session_idx = session_idxall{dayday};
    ori_idx = cell(length(session_idx),1);
    for session =1:length(session_idx)
        if ~isnan(session_idx(session))
            load(sprintf('/home/dclab2/Ensemble coding/data/12%02ddata/DG2-u78%d-%03d-500Hz.mat',dayday+8,dayday+1,session-1));
            trailnum = 6916;
            TrialStimID=reshape(Datainfo.Seq.StimID,[52 trailnum/52])';
            RealOrdid = [];
            RealOrdbuffid = TrialStimID;
            RealOrdbufferrorid = [];
            for kk = 1:length(Datainfo.VSinfo.sMbmInfo.respCode)
                RealOrdid = [RealOrdid;RealOrdbuffid(kk,:)];
                if Datainfo.VSinfo.sMbmInfo.respCode(kk)==1
                else
                    RealOrdbuffid = cat(1,RealOrdbuffid,RealOrdbuffid(kk,:));
                end
            end
            RealTrialID=find(Datainfo.VSinfo.sMbmInfo.respCode==1);
            StimID=RealOrdid(RealTrialID,:);
            
            StimID = StimID';
            %%patch
            if session_idx(session) < 14
                ori = [];
                for x = 1:52
                    for y = 1:133
                        if StimID(x,y) ~=1405
                            ori(x,y) =mod(StimID(x,y)-(session_idx(session)-1)*108,18);
                            if ori(x,y)==0
                                ori(x,y)=18;
                            end
                        else
                            ori(x,y) = 19;
                        end
                    end
                end
                
                %%EC
            elseif session_idx(session) ==14
                ori = [];
                for x = 1:52
                    for y = 1:133
                        if StimID(x,y) ~=325
                            ori(x,y) =floor((StimID(x,y)-1)/18+1);
                        else
                            ori(x,y) = 19;
                        end
                    end
                end
                %%SC
            else
                ori = [];
                for x = 1:52
                    for y = 1:133
                        if StimID(x,y) ~=109
                            ori(x,y) =mod(StimID(x,y),18);
                            if ori(x,y)==0
                                ori(x,y)=18;
                            end
                        else
                            ori(x,y) = 19;
                        end
                    end
                end
            end
            ori_idx{session}=ori;
            orientation_data = cell(2,19);
            for trial = 1:133
                for block = 2:4
                    window = (100+260*(block-1)+1):(100+260*(block-1)+1)+100;
                    baseline = squeeze(mean(Datainfo.trial_MUA{2}(trial,1:96,1:100),3));
                    MUA = squeeze(Datainfo.trial_MUA{2}(trial,1:96,window))-baseline';
                    MUA_filter = filtfilt(b, a, MUA);
                    %LFP = Datainfo.trial_LFP(trial,1:96,window);
                    orientation = ori(1+13*(block-1),trial);
                    orientation_1 = ori(1+13*(block-2),trial);
                    if isempty(all_ori_ori{session_idx(session)}{orientation,orientation_1})
                        all_ori_ori{session_idx(session)}{orientation,orientation_1} = MUA_filter;
                    else
                        all_ori_ori{session_idx(session)}{orientation,orientation_1} = cat(3,all_ori_ori{session_idx(session)}{orientation,orientation_1},MUA_filter);
                        
                    %orientation_data{2,orientation} = cat(1,orientation_data{2,orientation},LFP);
                    end
                end
            end
            clearvars -except b a session session_idx ori_idx session_idxall dayday all_ori_ori
            disp(session)
        end
    end
end
%%
for condition = 1:16
    for x = 1:19
        for y = 1:19
            if ~isempty(all_ori_ori{condition}{x,y})
                
                matrix_ori{condition}(x,y) = max(mean(all_ori_ori{condition}{x,y}(96,:,:),3));
            else
                matrix_ori{condition}(x,y) = 0;
            end
        end
    end
end
for condition = 1:16
    for x = 1:19
        matrix_ori{condition}(x,:) = normalize(matrix_ori{condition}(x,:));
    end
    subplot(4,4,condition)
    imagesc(matrix_ori{condition}(1:18,1:18));
    xticks(1:5:18);
    xticklabels({'10',  '60', '110', '160'});
    yticks(1:5:18);
    yticklabels({'10',  '60', '110', '160'});
    xlabel('Before Ori')
    ylabel('Target Ori')
    if condition<14
        subtitle(sprintf('Patch%d',condition))
    elseif condition == 14
        subtitle('EC')
    elseif condition == 15
        subtitle('SC')
    elseif condition == 16
        subtitle('EC0')
    end
end

%% SNR
