function all_orient_data = all_orient(all_num, block,type)
    load('/home/dclab2/Ensemble coding/data/datanum.mat');
    all_orientdata = {};
    for i = 1:length(all_num)
        name = a{1,all_num(i)};
        time = a{2,all_num(i)};
        path = sprintf('/home/dclab2/Ensemble coding/data/%sdata',time);%数据存储路径
        %这个是用来数据种类的
        num = datanum.(sprintf('data%s',time)).(block);
        [timeseries, stimres, stimIDs,~] = load_matrix(num, name, path);
        [stimIDs_new] = real_sequence(num, stimres, stimIDs);
        % 分组为trb
        [cluster,cluster_data] = clusterdata(num, stimIDs_new, timeseries, name);
        [~, orient_data]=orient_cluster(num, cluster, cluster_data, type,stimIDs_new);
        disp(size(orient_data.ori1.coil1))
        for ori = 1:9
            for coil = 1:96
                all_orientdata{i}(:,:,coil,ori) = orient_data.(sprintf('ori%d',ori*2-1)).(sprintf('coil%d',coil));
            end
        end
        clear orient_data     
    end
    
    all_orient_data = cat(1,all_orientdata{:});
    
end


% 
% timeLimits = seconds([0.84 2.92]); % 秒
% frequencyLimits = [0 250];
% sampleRate = 500; % Hz
% startTime = 0; % 秒f
% data = [];
% for i =1:9
%     ori = 1:2:17;
%     orii = ori(i);
%     for coil = [1:20,30:50,70:90]
%             ROI = squeeze(mean(all_orient_data(:,:,coil,i),1))';
%             timeValues = startTime + (0:length(ROI)-1).'/sampleRate;
%             ROI = timetable(seconds(timeValues(:)),ROI,'VariableNames',{'Data'});
%             ROI = ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
%             [P_ROI, F_ROI] = pspectrum(ROI, ...
%                 'FrequencyLimits',frequencyLimits);            
%             data(i,coil,:) = P_ROI';
%     end
% %     figure(1);
% %     subplot(3,3,i);
% %     plot(mean(mean(all_orient_data(:,:,:,i),1),3));
% %     title(sprintf('ori%d',orii));
%     figure(2);
%     yyaxis left;
%     subplot(3,3,i);
%     imagesc(F_ROI(50:450),1:96,squeeze(data(i,:,50:450)));
%     xline(6.25,'Color','red');
%     xline(12.5,'Color','red');
%     colorbar;
%     colormap('Parula');
% 
%     yyaxis right;
%     plot(F_ROI(50:450),squeeze(mean(data(i,:,50:450),2)));
%     title(sprintf('ori%d',orii));
%     figure(3)
%     yyaxis left;
%     subplot(3,3,i);
%     imagesc(F_ROI(50:350),1:96,squeeze(data(i,:,50:350)));
%     xline(6.28,'Color','red');
%     colorbar;
%     colormap('Parula');
%     yyaxis right;
%     plot(F_ROI(50:350),squeeze(mean(data(i,:,50:350),2)));
%     title(sprintf('ori%d',orii));
%     %line(xlim, [6.25 6.25], 'Color', 'r', 'LineWidth', 1)
%     %plotname = sprintf('session0_ori%d',orii);
%     %saveas(gcf, fullfile('D:\Desktop\Ensemble coding\plot\ori',time,plotname))
% end
% % % ,'FrequencyResolution',2
% % % 
