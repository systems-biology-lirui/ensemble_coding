function SSVEPB_fitting(MUA_LFP)
% SSVEPB_fitting用序列一致的SSGv来对MGv进行拟合
% ！------   d-prime只比较90和random   --------！
% 1.sum信号的频谱结果
% 2.Exp1B的MGv信号的频谱结果
% 3.d-prime结果与柱状图
%
% 输入： 'MUA'/'LFP'
Labels = {'Sum','MGv','fitting'};
load(sprintf('SSVEPB_Days9_14_%s_SSGv.mat',MUA_LFP));
condition = [-1,1,9];
load('D:\\Ensemble coding\\QQdata\\QQchannelselect.mat','selected_coil_final');
Colors = [142,50,40;62,181,95;104,36,135]/255;

%% SUM
fprintf('start Sum')
Sum_MGv = cell(1,3);
for cond = 1:3
    for loc = 1:12
        idx = find([SSGv.Location] == loc & [SSGv.Target_Ori] == condition(cond));
        if isempty(Sum_MGv{1,cond})
            Sum_MGv{1,cond} = SSGv(idx).Data;
        else
            Sum_MGv{1,cond} = Sum_MGv{1,cond} + SSGv(idx).Data;
        end
    end
end

% random
[P1_3d,Phase_3d,~] = SSVEP_fftanalyse(Sum_MGv{1,1});
Sum_filtresult{1,1} = P1_3d;
Sum_filtresult{1,2} = Phase_3d;

% target90
[P1_3d,Phase_3d,f] = SSVEP_fftanalyse(Sum_MGv{1,3});
Sum_filtresult{2,1} = P1_3d;
Sum_filtresult{2,2} = Phase_3d;

fft_phaseplot(Sum_filtresult,Labels{1},Colors(1,:),selected_coil_final,f)

noise_ssvep = Sum_filtresult{1,1}(:,:,[21,81]);
target_ssvep = Sum_filtresult{2,1}(:,:,[21,81]);
dprimeresult.Sum= SSVEP_dprime(noise_ssvep,target_ssvep);

save('D:\SSVEPB_Sum_fftresult.mat',"Sum_filtresult");
save('D:\Sum_MGv.mat','Sum_MGv');
clear Sum_filtresult
%% MGv
fprintf('startMGv')
load(sprintf('SSVEPB_Days9_14_%s_MGv.mat',MUA_LFP));

% random
[P1_3d,Phase_3d,f] = SSVEP_fftanalyse(MGv(1).Data);
MGv_filtresult{1,1} = P1_3d;
MGv_filtresult{1,2} = Phase_3d;
% target90
[P1_3d,Phase_3d,~] = SSVEP_fftanalyse(MGv(6).Data);
MGv_filtresult{2,1} = P1_3d;
MGv_filtresult{2,2} = Phase_3d;

fft_phaseplot(MGv_filtresult,Labels{2},Colors(2,:),selected_coil_final,f)


noise_ssvep = MGv_filtresult{1,1}(:,:,[21,81]);
target_ssvep = MGv_filtresult{2,1}(:,:,[21,81]);
dprimeresult.MGv= SSVEP_dprime(noise_ssvep,target_ssvep);

save('D:\SSVEPB_MGv_fftresult.mat',"MGv_filtresult");
clear MGv_filtresult


%% fitting
% 设置约束条件
lb = [-Inf; zeros(12, 1)]; % 下界 (常数项不限制，其他限制为 0)
ub = [Inf; ones(12, 1)]; % 上界 (常数项不限制，其他限制为 1)
loc_factor = cell(1, 3); % 存储回归系数
condition = [-1, 1, 9]; % 条件
ii = [1, 2, 6]; % 索引
fitting_MGv = cell(1, 3); % 存储拟合结果
R2 = cell(1, 3); % 存储拟合优度

% 主循环
for cond = 1:3
    % 提取数据
    MGv_pre = squmean(MGv(ii(cond)).Data, 1);
    SSGv_pre = zeros(12, size(MGv_pre, 1), size(MGv_pre, 2)); % 预分配内存
    for loc = 1:12
        idx = find([SSGv.Location] == loc & [SSGv.Target_Ori] == condition(cond));
        SSGv_pre(loc, :, :) = squmean(SSGv(idx).Data, 1);
    end
    
    % 拟合每个通道
    loc_factor{cond} = zeros(96, 13); % 预分配内存
    R2{cond} = zeros(96, 1); % 预分配内存
    for channel = 1:96
        x = double(MGv_pre(channel, :))'; % 实际值
        y = [ones(size(x, 1), 1), double(squeeze(SSGv_pre(:, channel, :)))']; % 设计矩阵
        loc_factor{cond}(channel, :) = lsqlin(y, x, [], [], [], [], lb, ub); % 拟合
        
        % 计算拟合优度 R^2
        y_pred = y * loc_factor{cond}(channel, :)'; % 预测值
        SS_res = sum((x - y_pred).^2); % 残差平方和
        SS_tot = sum((x - mean(x)).^2); % 总平方和
        R2{cond}(channel) = 1 - (SS_res / SS_tot); % R^2
    end
    
    % 拟合 MGv
    fitting_MGv{cond} = zeros(size(SSGv(idx).Data, 1), 96, size(SSGv(idx).Data, 3)); % 预分配内存
    for loc = 1:12
        idx = find([SSGv.Location] == loc & [SSGv.Target_Ori] == condition(cond));
        for channel = 1:96
            fitting_MGv{cond}(:, channel, :) = fitting_MGv{cond}(:, channel, :) + ...
                SSGv(idx).Data(:, channel, :) * loc_factor{cond}(channel, loc+1)';
        end
        if loc == 12
            for channel = 1:96
            fitting_MGv{cond}(:, channel, :) = fitting_MGv{cond}(:, channel, :) + loc_factor{cond}(channel, 1)';
            end
        end
    end
end


% random
[P1_3d,Phase_3d,~] = SSVEP_fftanalyse(fitting_MGv{1,1});
fitting_filtresult{1,1} = P1_3d;
fitting_filtresult{1,2} = Phase_3d;

% target90
[P1_3d,Phase_3d,f] = SSVEP_fftanalyse(fitting_MGv{1,3});
fitting_filtresult{2,1} = P1_3d;
fitting_filtresult{2,2} = Phase_3d;

fft_phaseplot(fitting_filtresult,Labels{3},Colors(3,:),selected_coil_final,f)

noise_ssvep = fitting_filtresult{1,1}(:,:,[21,81]);
target_ssvep = fitting_filtresult{2,1}(:,:,[21,81]);
dprimeresult.fitting= SSVEP_dprime(noise_ssvep,target_ssvep);
save('D:\fitting_MGv.mat','fitting_MGv');
save('D:\SSVEPB_fitting_fftresult.mat',"fitting_filtresult",'loc_factor','R2');
clear fitting_filtresult SSGv MGv
%% 绘制不同条件dprime柱状图
figure;
dprimeplot = [];

for n = 1:3
    dprimeplot = cat(3,dprimeplot,dprimeresult.(Labels{n}));
end
dprimeplot = dprimeplot(:,selected_coil_final,:);

% 创建图形窗口
figure;
subplot(1,2,1)
bar(squmean(dprimeplot(1,:,:),2))
subplot(1,2,2)
bar(squmean(dprimeplot(2,:,:),2))

%legend('Orientation 1', 'Orientation 2', 'Orientation 3'); % 图例

function fft_phaseplot(filtresult,label,color,selected_coil_final,f)
% 绘制不同条件的频谱结果与相位结果
% 频谱
figure;
subplot(1,2,1);
% random
plot(f(1:100),mean(squmean(filtresult{1,1}(:,selected_coil_final,1:100),1),1),'LineWidth',1.3,'Color',[0.7,0.7,0.7]);
hold on
% target90
plot(f(1:100),mean(squmean(filtresult{2,1}(:,selected_coil_final,1:100),1),1),'LineWidth', 2 ,'Color',color);
xline(6.25,'--','Color','r');
xline(25,'--');
hold off
subtitle(sprintf('%s fft',label));

% 相位
subplot(1,2,2);
plot(f(1:100),mean(squmean(filtresult{1,2}(:,selected_coil_final,1:100),1),1),'LineWidth',1.3,'Color',[0.7,0.7,0.7]);
hold on
plot(f(1:100),mean(squmean(filtresult{2,2}(:,selected_coil_final,1:100),1),1),'LineWidth', 2 ,'Color',color);
xline(6.25,'--','Color','r');
xline(25,'--');
hold off
subtitle(sprintf('%s phase',label));