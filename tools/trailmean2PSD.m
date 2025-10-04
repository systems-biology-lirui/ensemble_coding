function[F_ROI, filterdatat,filterdatar,filterdatab] = trailmean2PSD(cluster_data,num)
    timeLimits = seconds([0.84 2.88]); % 秒
    frequencyLimits = [0 250];
    sampleRate = 500; % Hz
    startTime = 0; % 秒f
    data = [];
    filterdatat=struct();
    filterdatar=struct();
    filterdatab=struct();
    for m = num
        for i = 1:96
            data(i,:) = mean(cluster_data.(sprintf('session%d',m)).(sprintf('coil%d',i)).random(:,1:1640),1);
            ROI = data(i,:)';
            timeValues = startTime + (0:length(ROI)-1).'/sampleRate;
            ROI = timetable(seconds(timeValues(:)),ROI,'VariableNames',{'Data'});
            ROI = ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
            [P_ROI, F_ROI] = pspectrum(ROI, ...
                'FrequencyLimits',frequencyLimits,'FrequencyResolution',2);
            filterdatar.(sprintf('session%d',m))(i,:) = P_ROI';
        end
        
        for i = 1:96
            data(i,:) = mean(cluster_data.(sprintf('session%d',m)).(sprintf('coil%d',i)).target1(:,1:1640),1);
            ROI = data(i,:)';
            timeValues = startTime + (0:length(ROI)-1).'/sampleRate;
            ROI = timetable(seconds(timeValues(:)),ROI,'VariableNames',{'Data'});
            ROI = ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
            [P_ROI, F_ROI] = pspectrum(ROI, ...
                'FrequencyLimits',frequencyLimits,'FrequencyResolution',2);
            filterdatat.(sprintf('session%d',m))(i,:) = P_ROI';
        end
        for i = 1:96
            data(i,:) = mean(cluster_data.(sprintf('session%d',m)).(sprintf('coil%d',i)).blank(:,1:1640),1);
            ROI = data(i,:)';
            timeValues = startTime + (0:length(ROI)-1).'/sampleRate;
            ROI = timetable(seconds(timeValues(:)),ROI,'VariableNames',{'Data'});
            ROI = ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
            [P_ROI, F_ROI] = pspectrum(ROI, ...
                'FrequencyLimits',frequencyLimits,'FrequencyResolution',2);
            filterdatab.(sprintf('session%d',m))(i,:) = P_ROI';
        end
    end
end