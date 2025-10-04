function tar_ran = target_random(cluster_data,num,block)
    timeLimits = seconds([0 3.278]); % 秒
    frequencyLimits = [0 250];
    sampleRate = 500; % Hz
    startTime = 0; % 秒
    
    for i = 1:length(num)
        tar_ran = struct();
        mm = num(i);
        for coil = 1:96
            for ra_trail = 1:6
                ra = cluster_data.(sprintf('session%d',mm)).(sprintf('coil%d',coil)).random(ra_trail,1:1640);
                ROI = ra';
                timeValues = startTime + (0:length(ROI)-1).'/sampleRate;
                ROI = timetable(seconds(timeValues(:)),ROI,'VariableNames',{'Data'});
                ROI = ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
                [P_ROI, F_ROI] = pspectrum(ROI, ...
                    'FrequencyLimits',frequencyLimits);
                tar_ran.(sprintf('session%d',mm)).(sprintf('coil%d',coil)).random(ra_trail,:)=P_ROI';
            end
            ra_mean = mean(tar_ran.(sprintf('session%d',mm)).(sprintf('coil%d',coil)).random,1);
            for bl_trail = 1:6
                ba = cluster_data.(sprintf('session%d',mm)).(sprintf('coil%d',coil)).blank(bl_trail,1:1640);
                ROI = ba';
                timeValues = startTime + (0:length(ROI)-1).'/sampleRate;
                ROI = timetable(seconds(timeValues(:)),ROI,'VariableNames',{'Data'});
                ROI = ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
                [P_ROI, F_ROI] = pspectrum(ROI, ...
                    'FrequencyLimits',frequencyLimits);
                tar_ran.(sprintf('session%d',mm)).(sprintf('coil%d',coil)).blank(ra_trail,:)=P_ROI';
            end
            bl_mean = mean(tar_ran.(sprintf('session%d',mm)).(sprintf('coil%d',coil)).blank,1);
            for trail = 1:54
                a = cluster_data.(sprintf('session%d',mm)).(sprintf('coil%d',coil)).target1(trail,1:1640);
                ROI = a';
                timeValues = startTime + (0:length(ROI)-1).'/sampleRate;
                ROI = timetable(seconds(timeValues(:)),ROI,'VariableNames',{'Data'});
                ROI = ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
                [P_ROI, F_ROI] = pspectrum(ROI, ...
                    'FrequencyLimits',frequencyLimits);
                tar_ran.(sprintf('session%d',mm)).(sprintf('coil%d',coil)).target(trail,:)=P_ROI';
                tar_ran.(sprintf('session%d',mm)).(sprintf('coil%d',coil)).target_ra(trail,:)=P_ROI'-ra_mean;
                tar_ran.(sprintf('session%d',mm)).(sprintf('coil%d',coil)).target_bl(trail,:)=P_ROI'-bl_mean;
            end
            tar_ran.(sprintf('session%d',mm)).(sprintf('coil%d',coil)).ra_bl = ra_mean-bl_mean;
        end
        filepath = fullfile('D:\Desktop',sprintf("%star_ransession%d.mat",block,mm));
        save(filepath,"tar_ran");
        clear tar_ran

    end
end