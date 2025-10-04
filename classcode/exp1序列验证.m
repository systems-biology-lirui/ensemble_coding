%%
load('sequence_1b.mat');
for i = 307:324
    a = fakesaber_1(:,i);
    a(a<10) = a(a<10)+180;
    fakesaber_1(:,i) = a;
end
random_4p = mean(fakesaber_1(1:4,random),1);
target10_4p = mean(fakesaber_1(1:4,target10),1);
target90_4p = mean(fakesaber_1(1:4,target90),1);
random_4p(random_4p>180) = random_4p(random_4p>180)-180;
target10_4p(target10_4p>180) = target10_4p(target10_4p>180)-180;
target90_4p(target90_4p>180) = target90_4p(target90_4p>180)-180;
random_4p_1 = repmat(random_4p,[1,5]);
target10_4p_1 = repmat(target10_4p,[1,5]);
target90_4p_1 = repmat(target90_4p,[1,5]);
%%
timeLimits = seconds([0 14.36]); % 秒
frequencyLimits = [0 12.5]; % Hz
figure('Position',[100,100,1000,600]);

for i = 1:18
    

random_4p_signal = firing_rate{i}(random_4p_1*4);
target10_4p_signal = firing_rate{i}(target10_4p_1*4);
target90_4p_signal = firing_rate{i}(target90_4p_1*4);

% random
random_4p_signal_ROI = random_4p_signal(:);
sampleRate = 25; % Hz
startTime = 0; % 秒
timeValues = startTime + (0:length(random_4p_signal_ROI)-1).'/sampleRate;
random_4p_signal_ROI = timetable(seconds(timeValues(:)),random_4p_signal_ROI,'VariableNames',{'Data'});
random_4p_signal_ROI = random_4p_signal_ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);

[Prandom_4p_signal_ROI, Frandom_4p_signal_ROI] = pspectrum(random_4p_signal_ROI, ...
    'FrequencyLimits',frequencyLimits);

% target 10
target10_4p_signal_ROI = target10_4p_signal(:);
sampleRate = 25; % Hz
startTime = 0; % 秒
timeValues = startTime + (0:length(target10_4p_signal_ROI)-1).'/sampleRate;
target10_4p_signal_ROI = timetable(seconds(timeValues(:)),target10_4p_signal_ROI,'VariableNames',{'Data'});
target10_4p_signal_ROI = target10_4p_signal_ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
[Ptarget10_4p_signal_ROI, Ftarget10_4p_signal_ROI] = pspectrum(target10_4p_signal_ROI, ...
    'FrequencyLimits',frequencyLimits);

% target 90
target90_4p_signal_ROI = target90_4p_signal(:);
sampleRate = 25; % Hz
startTime = 0; % 秒
timeValues = startTime + (0:length(target90_4p_signal_ROI)-1).'/sampleRate;
target90_4p_signal_ROI = timetable(seconds(timeValues(:)),target90_4p_signal_ROI,'VariableNames',{'Data'});
target90_4p_signal_ROI = target90_4p_signal_ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);

% 计算频谱估计值
% 不带输出参数运行该函数调用以绘制结果
[Ptarget90_4p_signal_ROI, Ftarget90_4p_signal_ROI] = pspectrum(target90_4p_signal_ROI, ...
    'FrequencyLimits',frequencyLimits);
subplot(3,6,i)
hold on

plot(Ftarget10_4p_signal_ROI(350:end),log10(Ptarget10_4p_signal_ROI(350:end)),'Color',[0.2,0.2,0.2],'LineWidth',1);
plot(Ftarget90_4p_signal_ROI(350:end),log10(Ptarget90_4p_signal_ROI(350:end)),'Color',[0.5,0.5,0.5],'LineWidth',1);
plot(Frandom_4p_signal_ROI(350:end),log10(Prandom_4p_signal_ROI(350:end)),'Color',[0.7,0.2,0.2],'LineWidth',2);
subtitle(sprintf('perfect ori%d',i*10));
xline(6.25)
xlim([1,12])

end