function[F_ROI,mean2psddatat,mean2psddatar,mean2psddatab]=psd2trailmean(cluster_data, num)
    timeLimits = seconds([0 3.278]); % 秒
    frequencyLimits = [0 250];
    sampleRate = 500; % Hz
    startTime = 0; % 秒
    filterdata = [];
    mean2psddatat = struct();
    mean2psddatar = struct();
    mean2psddatab = struct();
    for m =num
        for coil = 1:96
            filterdata = [];
            for i = 1:length(cluster_data.(sprintf('session%d',m)).(sprintf('coil%d',coil)).target1(:,1))
                ROI = cluster_data.(sprintf('session%d',m)).(sprintf('coil%d',coil)).target1(i,:)';
                timeValues = startTime + (0:length(ROI)-1).'/sampleRate;
                ROI = timetable(seconds(timeValues(:)),ROI,'VariableNames',{'Data'});
                ROI = ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
                [P_ROI, F_ROI] = pspectrum(ROI, ...
                    'FrequencyLimits',frequencyLimits);
                filterdata(i,:) = P_ROI';
            end
            mean2psddatat.(sprintf('session%d',m))(coil,:) = mean(filterdata,1);
        end
        for coil = 1:96
            filterdata = [];
            for i = 1:length(cluster_data.(sprintf('session%d',m)).(sprintf('coil%d',coil)).random(:,1))
                ROI = cluster_data.(sprintf('session%d',m)).(sprintf('coil%d',coil)).random(i,:)';
                timeValues = startTime + (0:length(ROI)-1).'/sampleRate;
                ROI = timetable(seconds(timeValues(:)),ROI,'VariableNames',{'Data'});
                ROI = ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
                [P_ROI, F_ROI] = pspectrum(ROI, ...
                    'FrequencyLimits',frequencyLimits);
                filterdata(i,:) = P_ROI';
            end
            mean2psddatar.(sprintf('session%d',m))(coil,:) = mean(filterdata,1);
        end
        for coil = 1:96
            filterdata = [];
            for i = 1:length(cluster_data.(sprintf('session%d',m)).(sprintf('coil%d',coil)).blank(:,1))
                ROI = cluster_data.(sprintf('session%d',m)).(sprintf('coil%d',coil)).blank(i,:)';
                timeValues = startTime + (0:length(ROI)-1).'/sampleRate;
                ROI = timetable(seconds(timeValues(:)),ROI,'VariableNames',{'Data'});
                ROI = ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
                [P_ROI, F_ROI] = pspectrum(ROI, ...
                    'FrequencyLimits',frequencyLimits);
                filterdata(i,:) = P_ROI';
            end
            mean2psddatab.(sprintf('session%d',m))(coil,:) = mean(filterdata,1);
        end
    end
end