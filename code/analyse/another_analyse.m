tar_blank_data = struct();
for ori = 1:18
    tar_blank_data.(sprintf('ori%d',ori)) = struct();
    oo = ori;
    for i = num
        for trail = 1:length(orient_matrix.(sprintf('session%d',i)))
            if orient_matrix.(sprintf('session%d',i))(:,trail) == oo
                for coil = 1:96
                    if ~isfield(tar_blank_data.(sprintf('ori%d',ori)), (sprintf('coil%d',coil)))  % 检查字段是否已存在
                        tar_blank_data.(sprintf('ori%d',ori)).(sprintf('coil%d',coil)) = [];
                    end
                    tar_blank_data.(sprintf('ori%d',ori)).(sprintf('coil%d',coil)) = cat(1,tar_blank_data.(sprintf('ori%d',ori)).(sprintf('coil%d',coil)),tar_ran.(sprintf('session%d',i)).(sprintf('coil%d',coil)).target_bl(trail,:));
                    
                end
            end
        end
    end
end



tar_ran_mean =[];
tarori = [1,3,5,7,9,11,13,15,17];
for i = 1:9
    idx = tarori(i);
    for mmm = 1:6
        coils=[26 29 94 63 95 93 96];
        coil =coils(mmm);
        tar_ran_mean(:,:,mmm,i) = mean(tar_ran_orient_data.(sprintf('ori%d',idx)).(sprintf('coil%d',coil)),1);
    end
%     for coil= 1:96
%         tar_ran_mean(:,:,coil,i) = mean(tar_ran_orient_data.(sprintf('ori%d',idx)).(sprintf('coil%d',coil)),1);
%     end
end


tar_ran_mean_mean = [];
for i = 1:9
    idx = tarori(i);
    tar_ran_mean_mean(:,i) = mean(tar_ran_mean(:,:,:,i),3);
end

figure(1);
for i = 1:9
    subplot(3,3,i);
    plot(F_ROI(50:450),tar_ran_mean_mean(50:450,i));
    name = sprintf('ORI%d',((i*2)-1)*10);
    subtitle(name);
    xline([6.25,12.5,18.75],'red')
   
end
figure(2);
for i = 1:9
    subplot(3,3,i);
    plot(F_ROI(50:150),tar_ran_mean_mean(50:150,i));
    name = sprintf('ORI%d',((i*2)-1)*10);
    subtitle(name);
    xline(6.25,'red')
end

% 对每个朝向进行通道筛选
for i = 1:9
    figure(i);
    for l =1:96
        subplot(10,10,l);
    
        mm = 1:2:17;
        ori = mm(i);
        data1(1,:) = mean(tar_ran_orient_data.(sprintf('ori%d',ori)).(sprintf('coil%d',l)),1);
        plot(F_ROI(50:450),data1(1,50:450));
        xline([6.25,12.5,18.75],'red','-.');
    end
end


%% 更小的基本单元
%先将trail进行拆分，然后再平均或者
%平均后频谱
session15_target_2 = zeros(length(cluster_data.session15.coil1.target1(:,1)),length(cluster_data.session15.coil1.target1(1,:))/2);
session15_target_2_mean = zeros(96,820);
for coil = 1:96
    for i = 1:length(cluster_data.session15.coil1.target1(:,1))
        point = length(cluster_data.session15.coil1.target1(1,:));
        session15_target_2(i*2-1,:) = cluster_data.session15.(sprintf('coil%d',coil)).target1(i,1:point/2);
        session15_target_2(i*2,:) = cluster_data.session15.(sprintf('coil%d',coil)).target1(i,point/2+1:point);
    end
    session15_target_2_mean = mean(session15_target_2,1);
end
session15_coilmean = mean(session15_target_2_mean,1);

%频谱后平均
timeLimits = seconds([0 1.638]); % 秒
frequencyLimits = [0 100]; % Hz
sampleRate = 500; % Hz
startTime = 0; % 秒

for coil = 1:96
    for i = 1:length(cluster_data.session15.(sprintf('coil%d',coil)).target1(:,1))
        ROI = session15_target_2_mean(i,:)';
        timeValues = startTime + (0:length(ROI)-1).'/sampleRate;
        ROI = timetable(seconds(timeValues(:)),ROI,'VariableNames',{'Data'});
        ROI = ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
        [P_ROI, F_ROI] = pspectrum(ROI, ...
        'FrequencyLimits',frequencyLimits);
    end
end



%%一些小测试
% coil_all = zeros(96,1644);
% for coil = 1:96
%    for tar = 1:length(uniqueColumns2)
%        tar1 = uniqueColumns2(tar);
%        coil_target_time(tar,:)=session1.(sprintf('coil%d',coil)).(sprintf('trail%d',tar1));
%    end
%    coil_all(coil,:) = mean(coil_target_time,1);
% end
% coil_average_target = mean(coil_all,1);
% coil_all = zeros(96,1644);
% for coil = 1:96
%    for tar = 1:length(blank)
%        tar1 = blank(tar);
%        coil_blank_time(tar,:)=session1.(sprintf('coil%d',coil)).(sprintf('trail%d',tar1));
%    end
%    coil_all(coil,:) = mean(coil_blank_time,1);
% end
% coil_average_blank = mean(coil_all,1);

session15 = zeros(96,1640,19);
for coil = 1:96
    for trail = 1:19
        session15(coil,:,trail) = cluster_data.session15.(sprintf('coil%d',coil)).target1(trail,:);
    end
end

mean = zeros(15,1644);
for i = num
    mean(i,:)=coil_mean_average.(sprintf('session%d',i));
end

subplot(3,3)
h=imagesc(aa(50:150,:,1)');
colormap('parula'); 
aa = squeeze(tar_ran_mean);


