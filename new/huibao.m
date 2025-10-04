%% --------------------------------汇报展示绘图------------------------------%%
%
% 
% LFP信号图

clear;

selected_blocks= {'SG', 'MGnv', 'MGv', 'SSGnv'};
ConditionColor = [107,147,166; 214,127,31; 47,141,74; 139,45,35]/255;
MUA_LFP = 'LFP';


%% 频谱分析

Fs = 500;
N = 1600;
f = Fs * (0:N/2) / N;
fftplot = cell(1, 11);
% 汉宁窗
hanwindow = hann(N)';

% for i = 1:3
% filename = sprintf('SSVEPA_Days1_7_LFP_%s.mat',selected_blocks{i});
% data = load(filename);
% currentBlock = selected_blocks{i};
% DatafftAmplitude = cell(1,10);
% DatafftPhase = cell(1,10);
% load('D://Ensemble coding//QQdata//QQChannelMap.mat','QQchannelMap');
% 
% %------------------------------LFP信号------------------------------------%
% figure('Position',[0 0 400 200]);
% plot(squmean(data.(currentBlock)(5).Data(:,62,1:1560),1),'Color',[0.7,0.7,0.7]);
% hold on;
% 
% plot(squmean(data.(currentBlock)(1).Data(:,62,1:1560),1),'Color',ConditionColor(i,:),'LineWidth',2);
% ax = gca;
% ax.LineWidth = 2;
% ax.FontSize = 12;
% ax.FontWeight = 'bold';
% ax.XAxis.FontSize = 12;
% ax.YAxis.FontSize = 12;
% % ax.XAxis.FontWeight = 'bold';
% title(sprintf('%s LFP',selected_blocks{i}))
% xline(100,'--');
% xline(1540,'--');
% legend('Random','Target', 'Box','off','Location','southeast');
% xticks([0,100,200:200:1600])
% xticklabels(num2cell([0,0.2,0.4:0.4:3.2]))
% box off;
% h = gcf;
% print(h, sprintf('LFPsignal%s.png',selected_blocks{i}), '-dpng');
% %------------------------------fft------------------------------------------%
% for cond = 1:10
%     % fprintf(sprintf('Start %s fft%d\n',block{i},cond));
%     datafftpre = data.(currentBlock)(cond).Data;
% 
%     Meandatafftpre = squmean(datafftpre,1);
% 
%     % num_trials = size(datafftpre, 1);
%     num_trials = size(datafftpre, 1);
%     num_coils = size(datafftpre, 2);
% 
%     % 时间点
%     signals = datafftpre(:, :, 41:40+N); % 维度：trials × coils × N
% 
%     % 重组+fft
%     signals_reshaped = reshape(permute(signals, [2 1 3]), [], N);
%     [P1_3d,Phase_3d] = fftanalyse(signals_reshaped,N,hanwindow,num_trials,num_coils);
%     DatafftAmplitude{cond} = P1_3d;
%     DatafftPhase{cond} = Phase_3d;
% 
% end
% save(sprintf('SSVEPA_Days1_7_LFP_%s_fftresult.mat',selected_blocks{i}),'DatafftAmplitude','DatafftPhase')
% end
% ---------------------------------SSGnv--------------------------------%
filename = sprintf('SSVEPA_Days1_7_LFP_%s.mat',selected_blocks{4});
data = load(filename);
currentBlock = selected_blocks{4};
DatafftAmplitude = cell(13,10);
DatafftPhase = cell(13,10);


figure('Position',[0 0 400 200]);
hold on;
plot(squmean(data.(currentBlock)(121).Data(:,62,1:1560),1),'Color',[0.7,0.7,0.7]);
plot(squmean(data.(currentBlock)(126).Data(:,62,1:1560),1),'Color',ConditionColor(4,:),'LineWidth',2);


ax = gca;
ax.LineWidth = 2;
ax.FontSize = 12;
ax.FontWeight = 'bold';
ax.XAxis.FontSize = 12;
ax.YAxis.FontSize = 12;
% ax.XAxis.FontWeight = 'bold';
title(sprintf('%s LFP',selected_blocks{4}))
xline(100,'--');
xline(1540,'--');
legend('Random', 'Target', 'Box','off','Location','southeast');
xticks([0,100,200:200:1600])
xticklabels(num2cell([0,0.2,0.4:0.4:3.2]))
box off;
h = gcf;
print(h, sprintf('LFPsignal%s.png',selected_blocks{4}), '-dpng');


for loc = 1:13
    for cond = 1:10
        % fprintf(sprintf('Start %s fft%d\n',block{i},cond));
        condition = -1:2:17;
        idx = find([data.SSGnv.Location] == loc & [data.SSGnv.Target_Ori] == condition(cond));
        datafftpre = data.(currentBlock)(idx).Data;

       
        [P1_3d,Phase_3d] = fftanalyse(datafftpre);
        DatafftAmplitude{loc,cond}= P1_3d;
        DatafftPhase{loc,cond} = Phase_3d;

    end
end
save(sprintf('SSVEPA_Days1_7_LFP_%s_fftresult.mat',selected_blocks{4}),'DatafftAmplitude','DatafftPhase','-v7.3')
% % 拼接 SSGnv（13x11 cell，按 trials 维度）
% for loc = 1:13
%     fprintf(sprintf('Start SSGnv fftloc%d\n',loc));
%     for cond = 1:10
%         datafftpre = data(day).SSGnv{loc, cond};
%         Meandatafftpre = squmean(datafftpre,1);
%         for channel = 1:96
%             SNR(day).SSGnv{loc, cond} = (max(Meandatafftpre(channel,101:1540))-mean(Meandatafftpre(channel,1:100),2))/std(Meandatafftpre(channel,1:100));
%         end
%         num_trials = size(datafftpre, 1);
%         num_coils = size(datafftpre, 2);
% 
%         % 时间点
%         signals = datafftpre(:, :, 41:40+N); % 维度：trials × coils × N
% 
%         % 重组+fft
%         signals_reshaped = reshape(permute(signals, [2 1 3]), [], N);
%         [P1_3d,Phase_3d] = fftanalyse(signals_reshaped,N,hanwindow,num_trials,num_coils);
%         DatafftAmplitude(day).SSGnv{loc, cond} = P1_3d;
%         DatafftPhase(day).SSGnv{loc, cond} = Phase_3d;
%     end
% end

% 处理 blank 数据（如果需要）
% if ~isempty(ClusterData.blank)
%     % 假设 blank 是 trials×channels×time 的三维矩阵
%     data(day).blank = cat(1, data(day).blank, ClusterData.blank);
% end


% d-prime

%% -------------------------------------绘图---------------------------%
% figure;
% SG;MGnv;MGv;SSGnv


for i = 1:3

    load(sprintf('SSVEPA_Days1_7_LFP_%s_fftresult.mat',selected_blocks{i}),'DatafftAmplitude','DatafftPhase')；
    plotfft(DatafftAmplitude,i)
    % for channel = 1:96
    %     subplot(10,10,find(QQchannelMap' ==channel));
    %     plot(f(1:100),squmean(a(:,channel,1:100),1),"Color",ConditionColor(c,:),"LineWidth", 1.5);
    %     hold on
    %     plot(f(1:100),squmean(b(:,channel,1:100),1),"Color",'k');
    %     xline(6.25,'--');
    %     subtitleHandle = subtitle(channel);
    %     hold off
    %     % if SNR.(Condition{c}){1,1}(channel)>=3.5
    %     %     ax = gca;
    %     %     ax.XColor = 'r';
    %     %     ax.YColor = 'r';
    %     %     set(subtitleHandle, 'Color', 'r');
    %     % end
    %     box off
    % end


    
end



%% ----------------------------------SSGnv-------------------------------------%
Fs = 500;
N = 1600;
f = Fs * (0:N/2) / N;
load(sprintf('SSVEPA_Days1_7_%s_%s_fftresult.mat',MUA_LFP,selected_blocks{4}),'DatafftAmplitude','DatafftPhase')
figure('Position',[0 0 400 200]);

a = cat(1,DatafftAmplitude{1,2:10});
b = cat(1,DatafftAmplitude{1,1});

channelSelect = [0, 5, 9, 11, 15, 17, 18, 19, 22, 23, 24, 26, 33, 34, 38, 40, 41, 42, 48, 51, 52, 53, 66, 72, 73, 78, 79, 82, 84, 87, 89]+1;

ChannelMeanTarget = squeeze(mean(a(:,channelSelect,1:100), 1)); % 假设 squmean 应为 mean
ChannelMeanRandom = squeeze(mean(b(:,channelSelect,1:100), 1));
x = f(1:100);

% 绘制均值曲线
plot(x, mean(ChannelMeanRandom, 1), 'Color', 'k');
hold on;

plot(x, mean(ChannelMeanTarget, 1), "Color", ConditionColor(4,:), "LineWidth", 2);


% 计算 Random 的误差带（行向量操作）
mean_data_random = mean(ChannelMeanRandom, 1);
std_data_random = std(ChannelMeanRandom, 0, 1);
fill([x, fliplr(x)], [mean_data_random + std_data_random, fliplr(mean_data_random - std_data_random)], ...
    'k', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

% 计算 Target 的误差带（行向量操作）
mean_data_target = mean(ChannelMeanTarget, 1);
std_data_target = std(ChannelMeanTarget, 0, 1);
fill([x, fliplr(x)], [mean_data_target + std_data_target, fliplr(mean_data_target - std_data_target)], ...
    ConditionColor(4,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');

xline(6.25, '--');
xline(25, '--');
xlabel('Frequency (Hz)');
ylabel('Amplitude');
legend('Random', 'Target', 'Box','off');
% title(sprintf('Location%d',location));
title(sprintf('%s',selected_blocks{4}));

xlim([0,32]);
box off;
ax = gca;
ax.LineWidth = 2;
ax.FontSize = 12;
ax.FontWeight = 'bold';
ax.XAxis.FontSize = 12;
ax.YAxis.FontSize = 12;
% ax.XAxis.FontWeight = 'bold';
box off;
h = gcf;
print(h, sprintf('fftresult%s.png',selected_blocks{4}), '-dpng');
%---------------------------频谱计算--------------------------------------%
function  [P1_3d,Phase_3d,f] = fftanalyse(data)
    Fs = 500;
    N = 1600;
    f = Fs * (0:N/2) / N;
    
    % 汉宁窗
    hanwindow = hann(N)';
    % num_trials = size(datafftpre, 1);
    num_trials = size(data, 1);
    num_coils = size(data, 2);
    
    % 时间点
    data = data(:, :, 41:40+N); % 维度：trials × coils × N
    
    % 重组+fft
    data = reshape(permute(data, [2 1 3]), [], N);
    signals_detrended = detrend(data')'; % 按列去趋势
    % signals_detrended =data; 不去趋势会让低频飞起来
    signals_windowed = signals_detrended .* hanwindow;  % 广播乘窗
    
    % 向量化FFT计算
    Y = fft(signals_windowed, [], 2);     % 按行计算FFT
    P2 = abs(Y) / N;                      % 双侧频谱幅值
    P1 = P2(:, 1:N/2+1);                  % 单侧频谱
    P1(:, 2:end-1) = 2 * P1(:, 2:end-1);  % 调整幅值
    
    % 计算相位谱
    Phase = angle(Y);                      % 获取复数相位（弧度制）
    Phase = Phase(:, 1:N/2+1);             % 单侧相位
    
    % 将结果重塑为三维数组 (trials × coils × frequency)
    P1_3d = permute(reshape(P1, num_coils, num_trials, []), [2 1 3]);
    Phase_3d = permute(reshape(Phase, num_coils, num_trials, []), [2 1 3]);


end


% --------------------频谱图绘制------------------------------------------%
% 频谱结果
% d-prime
function plotfft(DatafftAmplitude,i,MUA_LFP)
selected_blocks= {'SG', 'MGnv', 'MGv', 'SSGnv'};
ConditionColor = [107,147,166; 214,127,31; 47,141,74; 139,45,35]/255;


% figure('Position',[0 0 800 400]);

figure('Position',[0 0 400 200]);

a = cat(1,[DatafftAmplitude{2:10}]);
b = cat(1,DatafftAmplitude{1});

channelSelect = [0, 5, 9, 11, 15, 17, 18, 19, 22, 23, 24, 26, 33, 34, 38, 40, 41, 42, 48, 51, 52, 53, 66, 72, 73, 78, 79, 82, 84, 87, 89]+1;

ChannelMeanTarget = squeeze(mean(a(:,channelSelect,1:100), 1)); % 假设 squmean 应为 mean
ChannelMeanRandom = squeeze(mean(b(:,channelSelect,1:100), 1));
x = f(1:100);

% 绘制均值曲线
plot(x, mean(ChannelMeanRandom, 1), 'Color', 'k');
hold on;

plot(x, mean(ChannelMeanTarget, 1), "Color", ConditionColor(i,:), "LineWidth", 2);


% 计算 Random 的误差带（行向量操作）
mean_data_random = mean(ChannelMeanRandom, 1);
std_data_random = std(ChannelMeanRandom, 0, 1);
fill([x, fliplr(x)], [mean_data_random + std_data_random, fliplr(mean_data_random - std_data_random)], ...
    'k', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

% 计算 Target 的误差带（行向量操作）
mean_data_target = mean(ChannelMeanTarget, 1);
std_data_target = std(ChannelMeanTarget, 0, 1);
fill([x, fliplr(x)], [mean_data_target + std_data_target, fliplr(mean_data_target - std_data_target)], ...
    ConditionColor(i,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');

xline(6.25, '--');
xline(25, '--');
xlabel('Frequency (Hz)');
ylabel('Amplitude');
legend('Random', 'Target', 'Box','off');
% title(sprintf('Location%d',location));
title(sprintf('%s',selected_blocks{i}));

xlim([0,32]);
box off;
ax = gca;
ax.LineWidth = 2;
ax.FontSize = 12;
ax.FontWeight = 'bold';
ax.XAxis.FontSize = 12;
ax.YAxis.FontSize = 12;
% ax.XAxis.FontWeight = 'bold';
box off;
h = gcf;
print(h, sprintf('fftresult%s_%s.png',MUA_LFP,selected_blocks{i}), '-dpng');


d_primedatatarget = squeeze(DatafftAmplitude{6}(:,channelSelect,:));
d_primedatarandom = squeeze(DatafftAmplitude{1}(:,channelSelect,:));

d_primeresult = zeros(1,length(channelSelect));
for coil = 1:length(channelSelect)

    d_primesignal = squeeze(d_primedatatarget(:,coil,f==6.25));
    d_primenoise = squeeze(d_primedatarandom(:,coil,f==6.25));
    d_primeresult{i}(coil,1) = compute_dprime(d_primesignal, d_primenoise);
    d_primesignal = squeeze(d_primedatatarget(:,coil,f==25));
    d_primenoise = squeeze(d_primedatarandom(:,coil,f==25));
    d_primeresult{i}(coil,2) = compute_dprime(d_primesignal, d_primenoise);
end
end