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