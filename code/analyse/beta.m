% 假设A是100×96×1040的矩阵，B1到B12是40×96×1040的矩阵
A = reshape(mean(clusterdata{1},1), 96, 1041); % 重塑A为二维矩阵
B = [];
for i = 1:12
    B =cat(1,mean(clusterdata_patch{1,i},1),B);
end
B = reshape(B, 12*96, 1041); % 重塑B为二维矩阵

% 准备自变量矩阵X和因变量向量Y
X = B'; % 转置B以匹配A的行数
Y = A'; % 转置A以匹配X的列数

% 构建多元线性回归模型
mdl = fitlm(X, Y);


Xs = clusterdata_patch(1,:);
for coil = 1:96
    for time = 1:1041
        % 将 Y 的 trail 数据取出来，并转换为列向量
        Yt = squeeze(clusterdata{1}(:, coil, time)); % [100, 1]
        
        % 将每个条件的信号取出来，并在 trail 维度上做平均或其他处理，转换为列向量
        Xt = zeros(100, 12); % [100, 12]，为每个条件构建一个回归矩阵
        for cond = 1:12
            % 处理每个条件对应的信号，确保 X 的维度与 Y 一致
            X_cond = squeeze(Xs{cond}(:, coil, time)); % [40, 1]
            Xt(:, cond) = interp1(1:40, X_cond, linspace(1, 40, 100)); % 插值到 100 trails
        end
        
        % 进行回归计算
        beta(coil, time, :) = regress(Yt, Xt); % 回归权重
    end
end
imagesc(squeeze(beta(:,:,1)))
figure(2)
imagesc(squeeze(beta(:,:,2)))


% 假设 beta 已经通过回归计算得到，大小为 [96, 1041, 12]
% Y 是实际总信号矩阵，大小为 [100, 96, 1041]
% Xs 是单条件信号的cell数组，包含12个 [40, 96, 1041] 的矩阵
Y = clusterdata{1};

% 初始化重构信号矩阵
Y_pred = zeros(100, 96, 1041);

% 使用beta重构预测信号
for coil = 1:96
    for time = 1:1041
        Xt = zeros(100, 12);  % 为每个时间点构建单条件的X矩阵
        for cond = 1:12
            X_cond = squeeze(Xs{cond}(:, coil, time));  % 获取每个条件的信号
            Xt(:, cond) = interp1(1:40, X_cond, linspace(1, 40, 100));  % 插值到100 trails
        end
        % 根据 beta 计算预测信号
        Y_pred(:, coil, time) = Xt * squeeze(beta(coil, time, :));
    end
end

% 计算 R^2
R_squared = zeros(96, 1041);  % 用来存储每个coil和时间点的R^2值
for coil = 1:96
    for time = 1:1041
        Y_true = squeeze(Y(:, coil, time));  % 实际总信号
        Y_fit = squeeze(Y_pred(:, coil, time));  % 预测总信号
        
        % 计算 R^2
        SS_res = sum((Y_true - Y_fit).^2);  % 残差平方和
        SS_tot = sum((Y_true - mean(Y_true)).^2);  % 总平方和
        R_squared(coil, time) = 1 - SS_res / SS_tot;  % R^2
    end
end

% 计算均方误差 MSE
MSE = mean((Y - Y_pred).^2, [1 2 3]);  % 平均所有维度的误差

% 残差分析
Residuals = Y - Y_pred;  % 计算残差


% 针对某个coil绘制残差随时间的变化
coil = 1;  % 选择第一个coil

% 计算在所有时间点上的残差均值
Residuals_mean = mean(squeeze(Y(:, coil, :) - Y_pred(:, coil, :)), 1);

% 绘制残差随时间的变化
figure;
plot(1:1041, Residuals_mean);
xlabel('时间点');
ylabel('平均残差');
title(['coil ', num2str(coil), ' 残差随时间的变化']);
grid on;
% 假设 Y 是实际的总信号矩阵，Y_pred 是预测的总信号矩阵，大小都是 [100, 96, 1041]

% 选择一个coil和时间点绘制残差
coil = 1;  % 假设选择第一个coil
time = 500;  % 假设选择第500个时间点

% 计算残差
Y_true = squeeze(Y(:, coil, time));  % 实际总信号
Y_fit = squeeze(Y_pred(:, coil, time));  % 预测总信号
Residuals = Y_true - Y_fit;  % 计算残差

% 绘制残差图
figure;
scatter(Y_fit, Residuals, 'filled');  % 残差 vs 预测值
xlabel('预测值');
ylabel('残差');
title(['coil ', num2str(coil), ', time ', num2str(time), ' 残差图']);
grid on;

% 可以检查残差是否随机分布，如果残差与预测值之间没有明显的模式，说明模型拟合良好。

for m = 1:40
    aa(m,:,:) = mean(cat(1,clusterdata{1}(m,:,:),clusterdata{1}(m+40,:,:)),1);
end

res = permute(aa,[3,1,2]);

res1 = reshape(res,[40*1041,96]);

sti1 = [];
for i = 1:12
    sti = permute(clusterdata_patch{1,i},[3,1,2]);
    sti2 = reshape(sti,[40*1041,96]);
    sti1(:,:,i) = sti2;
end
sti1 = permute(sti1,[1,3,2]);
