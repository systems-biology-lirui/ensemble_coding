
new.timeseries = [];
    for coil = 1:96
        TrialStimID=squeeze(timeseries.session19(:,coil,:));
        RealOrdid = [];
        RealOrdbuffid = TrialStimID;
        RealOrdbufferrorid = [];
        for kk = 1:length(stimres.(sprintf('session%d',i)))
            RealOrdid = [RealOrdid;RealOrdbuffid(kk,:)];
            if stimres.(sprintf('session%d',i))(kk)==1
            else
                RealOrdbuffid = cat(1,RealOrdbuffid,RealOrdbuffid(kk,:));
            end
        end
        RealTrialID=find(stimres.(sprintf('session%d',i))==1);
        StimID=RealOrdid(RealTrialID,:);
        new.timeseries(:,:,coil) = StimID';
    end

m = {};
for i = 1:11
    m{i} = squeeze(mean(new.timeseries(1:1640,((i-1)*30+1):i*30,:),2));
end


a = squeeze(mean(mean(new.timeseries(:,1:300,:),2),3));

timeLimits = seconds([0 3.278]); % 秒
frequencyLimits = [0 250];
sampleRate = 500; % Hz
startTime = 0; % 秒f
        ROI = squeeze(a);
        timeValues = startTime + (0:length(ROI)-1).'/sampleRate;
        ROI = timetable(seconds(timeValues(:)),ROI,'VariableNames',{'Data'});
        ROI = ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
        [P_ROI, F_ROI] = pspectrum(ROI, ...
            'FrequencyLimits',frequencyLimits,'FrequencyResolution',2);
plot(F_ROI(5:120),P_ROI(5:120))
xline(6.25,'Color','red')


data = [];
for i =1:11
    for coil = 1:96
        ROI = squeeze(c(i,coil,1:1640));
        timeValues = startTime + (0:length(ROI)-1).'/sampleRate;
        ROI = timetable(seconds(timeValues(:)),ROI,'VariableNames',{'Data'});
        ROI = ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
        [P_ROI, F_ROI] = pspectrum(ROI, ...
            'FrequencyLimits',frequencyLimits,'FrequencyResolution',2);
        data(i,coil,:) = P_ROI';
    end
    figure(i);
    [x,y] = meshgrid(1:96,F_ROI(50:350,:));
    meshc(x,y,squeeze(data(i,:,50:350))')
end

    stimIDs_new = struct();
    for i = num
    
        if type == 2
            TrialStimID=reshape(stimIDs.(sprintf('session%d',i)),[72 143])';
        else
            TrialStimID=reshape(stimIDs.(sprintf('session%d',i)),[72 330])';
        end
        RealOrdid = [];
        RealOrdbuffid = TrialStimID;
        RealOrdbufferrorid = [];
        for kk = 1:length(stimres.(sprintf('session%d',i)))
            RealOrdid = [RealOrdid;RealOrdbuffid(kk,:)];
            if stimres.(sprintf('session%d',i))(kk)==1
            else
                RealOrdbuffid = cat(1,RealOrdbuffid,RealOrdbuffid(kk,:));
            end
        end
        RealTrialID=find(stimres.(sprintf('session%d',i))==1);
        StimID=RealOrdid(RealTrialID,:);
    
        StimID = StimID';
        stimIDs_new.(sprintf('session%d',i)) = StimID;
    end

a = stimIDs_new.session19(find(mod(1:72,4)==0),:);
for i = 1:330
    if a1(:,i)<=36
        m(i) = floor((a(1,i)-1)/144)+1;
    else
        m(i) = 11;
    end
end

for i = 1:11
    disp(length(find(m==i)))
end
for i =1:11
    c(i,:,:) = squeeze(mean(timeseries.session19(find(m==i),:,:),1));
    
end
for i =1:11
    figure(i);
    plot(squeeze(mean(c(i,:,:),2)));
end
for i =1:11
    subplot(3,4,i);
    plot(F_ROI(50:450),squeeze(mean(data(i,:,50:450),2)));
    xline(6.25,'Color','red')
    if i <=9
        title(sprintf('ori%d',(i*2-1)*10));
    elseif i == 10
        title('ori10')
    elseif i ==11
        title('random')
        end
end
for i =1:11    
        ROI = squeeze(mean(c(i,8:16,1:1640),2));
        timeValues = startTime + (0:length(ROI)-1).'/sampleRate;
        ROI = timetable(seconds(timeValues(:)),ROI,'VariableNames',{'Data'});
        ROI = ROI(timerange(timeLimits(1),timeLimits(2),'closed'),1);
        [P_ROI, F_ROI] = pspectrum(ROI, ...
            'FrequencyLimits',frequencyLimits);
        data(i,:) = P_ROI';
    figure(i);
    plot(F_ROI(50:450),P_ROI(50:450)')
    xline(6.25)
end

