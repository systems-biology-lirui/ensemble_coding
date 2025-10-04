coils_num =96;
num = 1:2:29;
% num = [0,1,2,3,4,5,7,8,9,10,12,14,15,16,18]+1;
allSessions = struct();
timeseries = struct();
stimres = struct();
stimIDs = struct();
MUAs = struct();
for i = num
    isc = i-1;
    m = sprintf('%02d',isc);
    filename = sprintf('DG2-u738-0%s-500Hz.mat', m);
    file_path = fullfile('D:\Desktop\0801data',filename);
    allSessions(i).Datainfo = load(file_path);
    timeseries.(sprintf('session%d', i)) = allSessions(i).Datainfo.Datainfo.trial_LFP;%时间序列
    stimres.(sprintf('session%d', i)) = allSessions(i).Datainfo.Datainfo.VSinfo.sMbmInfo.respCode;
    stimIDs.(sprintf('session%d', i)) = allSessions(i).Datainfo.Datainfo.Seq.StimID;%呈现序列
    MUAs.(sprintf('session%d', i)) = allSessions(i).Datainfo.Datainfo.trial_MUA;%MUA,可以用来比较blank和target

end


% test = [];
% for i =1:17
%     test(i,:) = squeeze(mean(mean(timeseries.(sprintf('session%d', i))(:,:,1:1644),1),2));
% end
% 
% %频谱分析
% timeLimits = seconds([0 3.286]); % 秒
% frequencyLimits = [0 250]; % Hz
% filter_data = [];
% for i = 1:17
%     test_1_ROI = test(i,:)';
%     sampleRate = 500; % Hz
%     startTime = 0; % 秒
%     timeValues = startTime + (0:length(test_1_ROI)-1).'/sampleRate;
%     test_1_ROI = timetable(seconds(timeValues(:)),test_1_ROI,'VariableNames',{'Data'});
%     test_1_ROI = test_1_ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
% 
%     % 计算频谱估计值
%     % 不带输出参数运行该函数调用以绘制结果
%     [Ptest_1_ROI, Ftest_1_ROI] = pspectrum(test_1_ROI, ...
%         'FrequencyLimits',frequencyLimits);
%     filter_data(:,i) = Ptest_1_ROI;
%     subplot(5,4,i);
%     yyaxis right;
%     plot(Ftest_1_ROI(50:450),Ptest_1_ROI(50:450));
%     yyaxis left;
%     ylabel('log');
%     plot(Ftest_1_ROI(50:450),log(Ptest_1_ROI(50:450)));
%     xline([Ftest_1_ROI(103) Ftest_1_ROI(206) Ftest_1_ROI(309)],'-.',{'6.25hz','12.5hz','18.75hz'})
%     title(['session', num2str(num(i))]);
% end

% heat_coil = [];
% timeLimits = seconds([0 3.286]); % 秒
% frequencyLimits = [0 250]; % Hz
% filter_data = [];
% for i = 1:17
%     x= num(i);
%     for coil = 1:96
%         heat_coil(i,coil,:) = mean(timeseries.(sprintf('session%d',x))(:,coil,1:1644),1);
%         test_1_ROI = squeeze(heat_coil(i,coil,:));
%         sampleRate = 500; % Hz
%         startTime = 0; % 秒
%         timeValues = startTime + (0:length(test_1_ROI)-1).'/sampleRate;
%         test_1_ROI = timetable(seconds(timeValues(:)),test_1_ROI,'VariableNames',{'Data'});
%         test_1_ROI = test_1_ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
% 
%         % 计算频谱估计值
%         % 不带输出参数运行该函数调用以绘制结果
%         [Ptest_1_ROI, Ftest_1_ROI] = pspectrum(test_1_ROI, ...
%             'FrequencyLimits',frequencyLimits);
%         filter_data(:,coil,i) = Ptest_1_ROI;
%     end
% end
% %先trail平均，再coil做频谱，session平均
% for i = 1:17
%     heat_coildata_log = log(squeeze(filter_data(:,:,i))');
%     ll = mean(heat_coildata_log,1);
%     subplot(5,4,i);
%     h=imagesc(heat_coildata_log(:,50:450));
%     grid off;
%     colorbar;
%     yyaxis left;
%     colormap('Parula');
%     yyaxis right;
%     y=plot(ll(:,50:450),'r');
%     set(gca, 'XTick', 100:100:400);
%     set(gca, 'XTickLabel', {'9', '15', '21', '27'});
%     xline([53 156 259],'-.',{'6.25hz','12.5hz','18.75hz'})
%     title(['session', num2str(num(i))]);
% end

% 非target的角度平均值
% stim11 =struct();
% for i = 1:17
%     x= num(i);
%     stim11.(sprintf('session%d',x)) = reshape(stimIDs.(sprintf('session%d',x)),[72,90]);
%     a = 1:72;
%     b = a(mod(a,4)~=0);
%     m = stim11.(sprintf('session%d',x))(b,:)-36;
%     m = (m - mod(m,6))/6;
%     subplot(5,4,i);
%     plot(mean(m,1));
%     title(['session', num2str(num(i))]);
% end
% test = [];
% for i =1:17
%     x= num(i);
%     test(i,:) = squeeze(mean(mean(timeseries.(sprintf('session%d', x)),1),2));
% end
% 


%前后段比较频谱分析

test = zeros(length(num)*2,1644);
for i =1:length(num)*2
    m = round(i/2);
    x= num(m);
    if mod(i,2)~=0
        test(i,:) = squeeze(mean(mean(timeseries.(sprintf('session%d', x))(1:45,:,1:1644),1),2));
    else
        test(i,:) = squeeze(mean(mean(timeseries.(sprintf('session%d', x))(45:90,:,1:1644),1),2));
    end
end

timeLimits = seconds([0 3.286]); % 秒
frequencyLimits = [0 250]; % Hz
filter_data = [];
for i = 1:length(num)*2
    test_1_ROI = test(i,:)';
    sampleRate = 500; % Hz
    startTime = 0; % 秒
    timeValues = startTime + (0:length(test_1_ROI)-1).'/sampleRate;
    test_1_ROI = timetable(seconds(timeValues(:)),test_1_ROI,'VariableNames',{'Data'});
    test_1_ROI = test_1_ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);

    % 计算频谱估计值
    % 不带输出参数运行该函数调用以绘制结果
    [Ptest_1_ROI, Ftest_1_ROI] = pspectrum(test_1_ROI, ...
        'FrequencyLimits',frequencyLimits);
    filter_data(:,i) = Ptest_1_ROI;
    subplot(6,6,i);
    yyaxis right;
    plot(Ftest_1_ROI(50:450),Ptest_1_ROI(50:450));
    yyaxis left;
    ylabel('log');
    plot(Ftest_1_ROI(50:450),log(Ptest_1_ROI(50:450)));
    xline([Ftest_1_ROI(103) Ftest_1_ROI(206) Ftest_1_ROI(309)],'-.',{'6.25hz','12.5hz','18.75hz'})
    m = round(i/2);
    x= num(m);
    title(['session', num2str(num(m))]);
end

before = [];
after = [];
for i = 1:17
    before(:,i) = filter_data(:,i*2-1);
    after(:,i) = filter_data(:,i*2);
end
before1 = [before(:,1:15),zeros(4096,1),before(:,16:end)];
after1 = [after(:,1:15),zeros(4096,1),after(:,16:end)];
a = plot(before1(103,1:9)-mean(before1(50:150,1:9),1));
a.Color=[1,0.19,0.19];
hold on
b=plot(after1(103,1:9)-mean(after1(50:150,1:9),1));
b.Color=[0.8,0.15,0.15];
c=plot(before1(103,10:18)-mean(before1(50:150,10:18),1));
c.Color = [0,0.75,1];
d=plot(after1(103,10:18)-mean(after1(50:150,10:18),1));
d.Color = [0.12,0.56,1];
ee = [before1(103,1:9);after1(103,1:9);before1(103,10:18);after1(103,10:18)];
ee = mean(ee,1);
ee_base = mean([mean(before1(50:150,1:9),1);mean(after1(50:150,1:9),1);mean(before1(50:150,10:18),1);mean(after1(50:150,10:18),1)],1);
e = plot(ee-ee_base);
e.Color = 'k';
e.LineWidth = 2;
legend('before1','after1','before2','after2','mean');
xticklabels({'10','30','50','70','90','110','130','150','170'})



%%朝向选择性
% 
% plot(filter_data(103,1:2:27))

% %% 同trail数
% % 
% new=struct();
% for i = 1:17
%     a= randperm(50);
%     a = a(1:30);
%     new.(sprintf('session%d',i)) = zeros(30,96,1644);
%     for coil = 1:96
%         for m = 1:30
%             trail = a(m);
%             new.(sprintf('session%d',i))(m,coil,:) = timeseries.(sprintf('session%d', i))(trail,coil,1:1644);
%         end
%     end
% end
% test = [];
% for i =1:17
%     test(i,:) = squeeze(mean(mean(timeseries.(sprintf('session%d', i))(:,:,1:1644),1),2));
% end
% test_new = [];
% for i =1:17
%     x= num(i);
%     test_new(i,:) = squeeze(mean(mean(new.(sprintf('session%d', x)),1),2));
% end
% 
% %频谱分析
% timeLimits = seconds([0 3.286]); % 秒
% frequencyLimits = [0 250]; % Hz
% filter_data = [];
% filter_data_new = [];
% for i = 1:17
%     test_1_ROI = test_new(i,:)';
%     sampleRate = 500; % Hz
%     startTime = 0; % 秒
%     timeValues = startTime + (0:length(test_1_ROI)-1).'/sampleRate;
%     test_1_ROI = timetable(seconds(timeValues(:)),test_1_ROI,'VariableNames',{'Data'});
%     test_1_ROI = test_1_ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
% 
%     % 计算频谱估计值
%     % 不带输出参数运行该函数调用以绘制结果
%     [Ptest_new_ROI, Ftest_new_ROI] = pspectrum(test_1_ROI, ...
%         'FrequencyLimits',frequencyLimits);
%     filter_data_new(:,i) = Ptest_new_ROI;
% 
%     test_1_ROI = test(i,:)';
%     sampleRate = 500; % Hz
%     startTime = 0; % 秒
%     timeValues = startTime + (0:length(test_1_ROI)-1).'/sampleRate;
%     test_1_ROI = timetable(seconds(timeValues(:)),test_1_ROI,'VariableNames',{'Data'});
%     test_1_ROI = test_1_ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
% 
%     % 计算频谱估计值
%     % 不带输出参数运行该函数调用以绘制结果
%     [Ptest_1_ROI, Ftest_1_ROI] = pspectrum(test_1_ROI, ...
%         'FrequencyLimits',frequencyLimits);
%     filter_data(:,i) = Ptest_1_ROI;
%     subplot(5,4,i);
%     plot(Ftest_new_ROI(50:450),log(Ptest_new_ROI(50:450)));
%     hold on
%     plot(Ftest_1_ROI(50:450),log(Ptest_1_ROI(50:450)));
%     xline(Ftest_1_ROI(103),'red');
%     
% end
% legend('30trail','90trail');
% legend('Location', 'west');