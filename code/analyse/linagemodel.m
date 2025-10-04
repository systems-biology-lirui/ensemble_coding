


% 加载数据
% lfp_data 是 40x96x1041 的矩阵
% condition_data 是 12x40x96x1041 的矩阵

% 假设数据已经加载为 lfp_data 和 condition_data
% lfp_data = rand(40, 96, 1041); % 示例数据
% condition_data = rand(12, 40, 96, 1041); % 示例数据
%load('d:/desktop/new_norm.mat')
% coil_A = coilcluster.A;
clearvars -except clusterdata_patch clusterdata_EC_norm highlighted_channels B_new
trail = 1;
coil_select = 1:96;
%coil2= setdiff(1:96,highlighted_channels);
lfp_data = [];

for m = 1:40
    aa(m,:,:) = mean(cat(1,clusterdata_EC_norm{trail}(m,coil_select,:),clusterdata_EC_norm{trail}(m+40,coil_select,:)),1);
end

lfp_data = aa;

% 定义滤波器参数
Fs = 500;      % 采样频率，单位Hz
Fc = 100;        % 截止频率，单位Hz
order = 4;      % 滤波器阶数

% 设计低通 Butterworth 滤波器
[b, a] = butter(order, Fc/(Fs/2), 'low');

% 获取矩阵尺寸
[dim1, dim2, dim3] = size(lfp_data);
data_reshaped = reshape(lfp_data, [], dim3);  % 尺寸为 (40*96) x 1041
data_transposed = data_reshaped';  % 尺寸为 1041 x (40*96)

filtered_transposed = filtfilt(b, a, data_transposed);  % 尺寸保持不变
filtered_reshaped = filtered_transposed';  % 尺寸为 (40*96) x 1041
lfp_data = reshape(filtered_reshaped, dim1, dim2, dim3);  % 尺寸为 40x96x1041

condition_data = [];
for i = 1:12
    condition_data(i,:,:,:) = clusterdata_patch{trail,i}(:,coil_select,:);
end
% 假设数据已经加载为 lfp_data 和 condition_data
% lfp_data 是 40x96x1041 的矩阵
% condition_data 是 12x40x96x1041 的矩阵

[num_trials, num_channels, num_data_points] = size(lfp_data);
num_conditions = size(condition_data, 1);

% 平均化每个条件的数据
Y = zeros(num_conditions, num_channels, num_data_points);
for i = 1:num_conditions
    Y(i, :, :) = squeeze(mean(mean(condition_data(i, :, :, :), 2), 1));
end


% 获取矩阵尺寸
[dim1, dim2, dim3] = size(Y);
data_reshaped = reshape(Y, [], dim3);  % 尺寸为 (40*96) x 1041
data_transposed = data_reshaped';  % 尺寸为 1041 x (40*96)

filtered_transposed = filtfilt(b, a, data_transposed);  % 尺寸保持不变
filtered_reshaped = filtered_transposed';  % 尺寸为 (40*96) x 1041
Y = reshape(filtered_reshaped, dim1, dim2, dim3);  % 尺寸为 40x96x1041

time_window = 1:1041;

X = mean(lfp_data,1);
%% pca
maxs = 3;
X_n = [];
Y_n = [];
for fa = 1:13
    if fa == 1
        [coeff, score, latent, tsquared, explained,mu] = pca(squeeze(X)');
        X_std = std(squeeze(X));
        X_mean = mean(squeeze(X));
        coeff_se = coeff(:,1:maxs);
        X_n(1,:,:) = ((score(:,1:maxs)*coeff_se')+mu)';
    else
        [coeff, score, latent, tsquared, explained,mu] = pca(squeeze(Y(fa-1,:,:))');
        Y_std = std(squeeze(Y(fa-1,:,:)));
        Y_mean = mean(squeeze(Y(fa-1,:,:)));
        coeff_se = coeff(:,1:maxs);
        Y_n(fa-1,:,:) = ((score(:,1:maxs)*coeff_se')+mu)';
    end
end

%%
X_flat = reshape(X_n(:, :, time_window), 1, []);
X_flat = X_flat';


% 选择一段时间区间进行分析（例如，前500个数据点）


% 扁平化数据以适应线性回归模型

Y_flat = reshape(Y_n(:, :, time_window), num_conditions, []);  % 将Y展平成2D矩阵


% 转置Y_flat使其维度匹配
Y_flat = Y_flat';

% 添加常数列（偏置项）
design_matrix = [ones(size(Y_flat, 1), 1), Y_flat];


%%


% 训练线性回归模型
B = design_matrix \ X_flat;

% 提取每个条件的影响，B 的第二列开始是条件影响
condition_influence = B(2:end);

% 可视化每个条件的影响
figure;

bar(mean(reshape(B(2:end), [], num_conditions), 1));

title('Condition Influence');
xlabel('Condition');
ylabel('Influence');




%% 测试
Y_pre = reshape(permute(Y_n(:, :, time_window),[1,3,2]), num_conditions, []);
Y_pre = Y_pre';
pre = Y_pre*B(2:end)+B(1);
X_test = reshape(permute(X_n(:, :, time_window),[1,3,2]), 1, []);
X_test = X_test';


%% 

% 假设实际信号和预测信号已经加载为 actual_signal 和 predicted_signal
actual_signal = X_test;
predicted_signal = pre;
% 1. 视觉比较
figure;
plot(actual_signal, 'b', 'DisplayName', 'Actual Signal');
hold on;
plot(predicted_signal, 'r--', 'DisplayName', 'Predicted Signal');
legend;
xlabel('Sample');
ylabel('Amplitude');
title('Actual vs Predicted Signal');
hold off;

% 2. 误差指标
MAE = mean(abs(actual_signal - predicted_signal));
MSE = mean((actual_signal - predicted_signal).^2);
RMSE = sqrt(MSE);
SS_res = sum((actual_signal - predicted_signal).^2);
SS_tot = sum((actual_signal - mean(actual_signal)).^2);
R_squared = 1 - (SS_res / SS_tot);
corr_coeff = corrcoef(actual_signal, predicted_signal);
Pearson_r = corr_coeff(1,2);

% 计算 MAPE，确保没有零值
if any(actual_signal == 0)
    warning('Actual signal contains zero(s), MAPE is not defined for these points.');
    MAPE = NaN;
else
    MAPE = mean(abs((actual_signal - predicted_signal) ./ actual_signal)) * 100;
end

peak = max(actual_signal);
PSNR = 10 * log10((peak^2) / MSE);

% 输出误差指标
fprintf('Mean Absolute Error (MAE): %.4f\n', MAE);
fprintf('Mean Squared Error (MSE): %.4f\n', MSE);
fprintf('Root Mean Squared Error (RMSE): %.4f\n', RMSE);
fprintf('R-squared: %.4f\n', R_squared);
fprintf('Pearson Correlation Coefficient: %.4f\n', Pearson_r);
if ~isnan(MAPE)
    fprintf('Mean Absolute Percentage Error (MAPE): %.2f%%\n', MAPE);
else
    fprintf('Mean Absolute Percentage Error (MAPE): Undefined (contains zeros in actual signal)\n');
end
fprintf('Peak Signal-to-Noise Ratio (PSNR): %.2f dB\n', PSNR);

% 3. 频域分析
fs = 1000; % 根据实际情况调整
N = length(actual_signal);
f = (0:N-1)*(fs/N);
actual_fft = abs(fft(actual_signal));
predicted_fft = abs(fft(predicted_signal));

figure;
plot(f, actual_fft, 'b', 'DisplayName', 'Actual Signal');
hold on;
plot(f, predicted_fft, 'r--', 'DisplayName', 'Predicted Signal');
xlim([0 fs/2]);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Frequency Domain Comparison');
legend;
hold off;

% 4. 交叉相关
[c, lags] = xcorr(actual_signal, predicted_signal, 'coeff');
[max_corr, idx] = max(c);
time_lag = lags(idx);
fprintf('Maximum Cross-Correlation: %.4f at lag %d samples\n', max_corr, time_lag);

figure;
plot(lags, c);
xlabel('Lag');
ylabel('Cross-correlation');
title('Cross-Correlation between Actual and Predicted Signals');

% 5. Bland-Altman Plot
differences = actual_signal - predicted_signal;
means = (actual_signal + predicted_signal) / 2;
mean_diff = mean(differences);
std_diff = std(differences);

figure;
scatter(means, differences, 10, 'filled');
hold on;
plot([min(means) max(means)], [mean_diff mean_diff], 'r');
plot([min(means) max(means)], [mean_diff + 1.96*std_diff mean_diff + 1.96*std_diff], 'k--');
plot([min(means) max(means)], [mean_diff - 1.96*std_diff mean_diff - 1.96*std_diff], 'k--');
xlabel('Mean of Actual and Predicted');
ylabel('Difference (Actual - Predicted)');
title('Bland-Altman Plot');
hold off;

% 6. 散点图
figure;
scatter(actual_signal, predicted_signal, 10, 'filled');
hold on;
refline(1,0);
xlabel('Actual Signal');
ylabel('Predicted Signal');
title('Scatter Plot of Actual vs Predicted Signals');
hold off;

%% 分通道
X1 = X;
Y1 = Y;
C = [];
newpre = [];
for coil = 1:96
    dataX = squeeze(X1(:,coil,1:500));
    dataY = permute(squeeze(Y1(:,coil,1:500)),[2,1]);
    design_matrix = [ones(size(dataY, 1), 1), dataY];
    C(coil,:) = design_matrix \ dataX;
    newpre(coil,:) = permute(squeeze(Y1(:,coil,501:1000)),[2,1])*C(coil,2:end)'+C(coil,1); 
end
c1 = mean(C(:,2:end),2);
c1 = reshape(c1,[1,96,1]);
%Y2 =Y.*c1;
%%
newactual = permute(squeeze(X1(1,:,501:1000)),[2,1]);
factor1 = [];
for coil = 1:96
    actual_signal = newactual(:,coil);
    predicted_signal = newpre(coil,:)';
    MAE = mean(abs(actual_signal - predicted_signal));
    MSE = mean((actual_signal - predicted_signal).^2);
    RMSE = sqrt(MSE);
    SS_res = sum((actual_signal - predicted_signal).^2);
    SS_tot = sum((actual_signal - mean(actual_signal)).^2);
    R_squared = 1 - (SS_res / SS_tot);
    corr_coeff = corrcoef(actual_signal, predicted_signal);
    Pearson_r = corr_coeff(1,2);

    % 计算 MAPE，确保没有零值
    if any(actual_signal == 0)
        warning('Actual signal contains zero(s), MAPE is not defined for these points.');
        MAPE = NaN;
    else
        MAPE = mean(abs((actual_signal - predicted_signal) ./ actual_signal)) * 100;
    end

    peak = max(actual_signal);
    PSNR = 10 * log10((peak^2) / MSE);
    factor1(coil,:) = [MAE,MSE,RMSE,SS_res,SS_tot,R_squared,Pearson_r,PSNR];

end

%%
% 创建一个10x10的网格
[X, Y] = meshgrid(1:10, 1:10);

% 计算每个方格的中心坐标
Xcenter = X ;
Ycenter = Y ;

% 创建一个10x10的方格图
figure;
hold on;
for i = 1:10
    for j = 1:10
        % 绘制方格
        m = rectangle('Position', [j-0.5, i-0.5, 1, 1], 'EdgeColor', 'k');
        if chanmap(11-i,j) <= 96
            id = find(idx(:,2)==chanmap(11-i,j));
            m.FaceColor = clusterColor{idx(id,3)};
        else
            m.FaceColor = 'none';
        end

        % 在方格中心添加文字标签
        text(Xcenter(i,j), Ycenter(i,j), num2str(chanmap(11-i,j)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    end
end
axis off
hold off;

%%
imagesc(C)
plot(squeeze(X(1,1,501:1000)));
hold on 
plot(squeeze(pre(1,1:500)));
hold off
%%

B = [];
B1 = [];
for trailnum = 1:40
    X = lfp_data(trailnum,:,:);
    X_flat = reshape(X(:, :, time_window), 1, []);
    X_flat = X_flat';
    for num2 = 1:40
        Y = squeeze(condition_data(:,num2,:,:));
        Y_flat = reshape(Y(:, :, time_window), num_conditions, []);  % 将Y展平成2D矩阵
        Y_flat = Y_flat';
        design_matrix = [ones(size(Y_flat, 1), 1), Y_flat];
        B1(trailnum,num2,:) = design_matrix \ X_flat;
    end
    B(trailnum,:) = squeeze(mean(B1(trailnum,:,:),2));
end
figure;
imagesc(B(:,2:end))

%%
for coil =1:52
    cc = highlighted_channels(coil);
end
for coil = 1:96
    n = find(ChanMap==coil);
    a = sprintf('coil%d',coil);
    subtitle(a)
    subplot(10,10,n);
    plot(newactual(:,coil))
    hold on
    plot(newpre(coil,:)')
    hold off
end
plot(mean(newactual(:,highlighted_channels),2));
hold on 
plot(mean(newpre(highlighted_channels,:)',2));
hold off

%%

timeLimits = seconds([0 2.08]); % 秒
frequencyLimits = [0 250]; % Hz

%%
% 对感兴趣的信号时间区域进行索引
all2fft = [];
for location = 1:14
    b93_ROI = squeeze(mean(clusterdata_patch{3,location},1))';
    sampleRate = 500; % Hz
    startTime = 0; % 秒
    timeValues = startTime + (0:length(b93_ROI)-1).'/sampleRate;
    b93_ROI = timetable(seconds(timeValues(:)),b93_ROI,'VariableNames',{'Data'});
    b93_ROI = b93_ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);

    % 计算频谱估计值
    % 不带输出参数运行该函数调用以绘制结果
    [Pb93_ROI, Fb93_ROI] = pspectrum(b93_ROI, ...
        'FrequencyLimits',frequencyLimits);
    all2fft(location,:,:) = Pb93_ROI;
end

b93_ROI = squeeze(mean(clusterdata_EC_norm{3},1))';
sampleRate = 500; % Hz
startTime = 0; % 秒
timeValues = startTime + (0:length(b93_ROI)-1).'/sampleRate;
b93_ROI = timetable(seconds(timeValues(:)),b93_ROI,'VariableNames',{'Data'});
b93_ROI = b93_ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);

% 计算频谱估计值
% 不带输出参数运行该函数调用以绘制结果
[Pb93_ROI, Fb93_ROI] = pspectrum(b93_ROI, ...
    'FrequencyLimits',frequencyLimits);

for coil = 1:96
    nn = find(ChanMap==coil);
        subplot(10,10,nn);
    for location = 1:15
        if location <15
            plot(Fb93_ROI(50:500),squeeze(all2fft(location,50:500,coil)));
            hold on 
    %     plot(Fb93_ROI(50:500),all2fft(50:500,coil));
    %     hold on
        else
            plot(Fb93_ROI(50:500),squeeze(Pb93_ROI(50:500,coil)));
            hold on       
        end
        
    end
    hold off
    xline([6.25 12.5 25])
    subtitle(sprintf('coil%d',coil));
end




%狠狠计算相关性
all1 = [];
for location = 1:12
    all1 = mean(cat(1,all1,mean(clusterdata_patch{1,location},1)),1);
end

a = mean(clusterdata_EC_norm{1},1);
b = mean(clusterdata_patch{1,13},1);
c = mean(clusterdata_patch{1,14},1);
load('D:\Desktop\Ensemble coding\data\chanmap.mat')
for coil = 1:96
     nn = find(ChanMap==coil);
     subplot(10,10,nn);
     plot(squeeze(a(1,coil,:)));
     hold on 
     plot(squeeze(all1(1,coil,:)));
     plot(squeeze(b(1,coil,:)));
     %plot(squeeze(c(1,coil,:)));
     hold off
end
co = [];
for coil = 1:96
    [co1,p1] = corr(squeeze(a(1,coil,:)),squeeze(all1(1,coil,:)));
    [co2,p2] = corr(squeeze(a(1,coil,:)),squeeze(b(1,coil,:)));
    [co3,p3] = corr(squeeze(a(1,coil,:)),squeeze(c(1,coil,:)));
    co(coil,1) = co1;
    co(coil,2) = co2;
    co(coil,3) = co3;
end
imagesc(co)
co(97,:) = mean(co(1:96,:),1);



% 创建箱型图
figure; % 创建一个新图窗口
boxplot(co(1:96,1:3), 'Labels', {'patch1:12', 'patch13', 'SC'});

% 添加标题和轴标签
title('Box Plot of Three Conditions');
xlabel('Condition');
ylabel('Value');

