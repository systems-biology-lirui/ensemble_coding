%汇总分角度
block = 'patch';
type = 2;
all_num = 5:9;
all_orient_dataEC = all_orient(all_num,block);


%%
%clear;
load('/home/dclab2/Ensemble coding/data/datanum.mat')

day = 2;
%这两个是选数据日期的，只要改第二位就行，一共四个
name = a{1,day};
time = a{2,day};
path = sprintf('/home/dclab2/Ensemble coding/data/%sdata',time);%数据存储路径


%这个是用来数据种类的
block = 'EC';
type = 0; % EC=0,SC=1,patch=2(0815的patch用1)


%下面的应该不需要改
num = datanum.(sprintf('data%s',time)).(block);


% 导入数据
[~, stimres, stimIDs, MUAs] = load_matrix(num, name, path);

% 进行id回溯
% 这里没删除对于target1和target2的分别，是作为一个检查存在。
[stimIDs_new] = real_sequence(num, stimres, stimIDs);


timeseries = MUAs;
clear MUAs
%%

% 分组为trb
[cluster,cluster_data] = clusterdata(num, stimIDs_new, timeseries, type, name);

for session = num
    fieldnn = sprintf('session%d',n);
    for coil = 1:96
        randomdata.(fieldnn)(coil,:,:) = cluster_data.(fieldnn).(sprintf('coil%d',coil)).random;
    end
end

%先trail平均再频谱分析

[F_ROI,filterdatat,filterdatar,filterdatab] = trailmean2PSD(cluster_data,num);

%先频谱分析再trail平均
[F_ROI, mean2psddatat,mean2psddatar,mean2psddatab]= psd2trailmean(cluster_data, num);

%3dplot
datasets = struct('filterdatat', filterdatat, ...
                  'filterdatar', filterdatar, ...
                  'filterdatab', filterdatab, ...
                  'mean2psddatat', mean2psddatat, ...
                  'mean2psddatar', mean2psddatar, ...
                  'mean2psddatab', mean2psddatab);

numFigures = 6;
field = fieldnames(datasets);
[x,y] = meshgrid(1:96,F_ROI(50:450,:));

for ii =1:length(num)
    i = num(ii);
    for m = 1
        figure(ii)
        z = datasets.(field{m}).(sprintf('session%d',i))(:, 50:450)';
        meshc(x, y, z);
        titlename = sprintf('session%d_%s',i,field{m});
        title(titlename);
        plotname = sprintf('session%d_%s.fig',i,field{m});
        plotpath = fullfile('D:\Desktop\Ensemble coding\plot\allplot',time,plotname);
        hold on; % 保持当前图形，以便添加新的线条
        line(xlim, [6.25 6.25], 'Color', 'r', 'LineWidth', 1); % 在y=6.25的位置添加一条红色线
        hold off;

        %hold off;
        %saveas(gcf, plotpath); 
        %close(gcf);
    end
end

for ii = 1:length(num)
    i = num(ii);
    figure(ii);
    plot(mean(cluster_data.(sprintf('session%d',i)).coil93.target1,1));
end
%%
meshc(x, y, (datasets.(field{1}).(sprintf('session%d',i))(:, 50:450)-datasets.(field{2}).(sprintf('session%d',i))(:, 50:450))');
hold on;
line(xlim, [6.25 6.25], 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
hold off;

save(sprintf('%sfilter%s.mat',time,block),"filterdatat","filterdatar","filterdatab","mean2psddatat" ... 
    ,"mean2psddatar","mean2psddatab")

% 分角度
[orient_matrix, orient_data]=orient_cluster(num, cluster, cluster_data, type,stimIDs_new);
%汇总分角度


timeLimits = seconds([0.84 2.92]); % 秒
frequencyLimits = [0 250];
sampleRate = 500; % Hz
startTime = 0; % 秒f
data = [];
for i =1:9
    ori = 1:2:17;
    orii = ori(i);
    for coil = 1:96
            ROI = mean(orient_data.(sprintf('ori%d',orii)).(sprintf('coil%d',coil)),1)';
            timeValues = startTime + (0:length(ROI)-1).'/sampleRate;
            ROI = timetable(seconds(timeValues(:)),ROI,'VariableNames',{'Data'});
            ROI = ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
            [P_ROI, F_ROI] = pspectrum(ROI, ...
                'FrequencyLimits',frequencyLimits);            
            data(i,coil,:) = P_ROI';
    end
    figure(i)
    [x,y] = meshgrid(1:96,F_ROI(50:350,:));
    meshc(x,y,squeeze(data(i,:,50:350))')
    title(sprintf('ori%d',orii));
    line(xlim, [6.25 6.25], 'Color', 'r', 'LineWidth', 1)
    %plotname = sprintf('session0_ori%d',orii);
    %saveas(gcf, fullfile('D:\Desktop\Ensemble coding\plot\ori',time,plotname))
end
%trail
for i  =1:6
    for coil = 1:96
        ROI = orient_data.(sprintf('ori%d',9)).(sprintf('coil%d',coil))(i,100:1540)';
        timeValues = startTime + (0:length(ROI)-1).'/sampleRate;
        ROI = timetable(seconds(timeValues(:)),ROI,'VariableNames',{'Data'});
        ROI = ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
        [P_ROI, F_ROI] = pspectrum(ROI, ...
            'FrequencyLimits',frequencyLimits);
        
        data(i,coil,:) = P_ROI';
    end
    figure(i)
    meshc(x,y,squeeze(data(i,:,50:350))')
end





%%接下来的可以先不做，可能会直接把内存占满
% 单个trail频谱之后减去random
tar_ran = target_random(cluster_data,num,block);

%按照朝向分组
[tar_ran_orient_data, tar_orient_data] = PSD_orientcluster(num,orient_matrix);

%别的一些分析见another_analyse
