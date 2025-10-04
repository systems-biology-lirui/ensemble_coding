%% SINGLE TRAIL
patchsingletrail=zeros(96,1640);
ECsingletrail=zeros(96,1640);
for coil=1:96
    patchsingletrail(coil,:)=squeeze(clusterdata_patch{1,1}(1,coil,:))';
    ECsingletrail(coil,:)=squeeze(clusterdata_EC{1}(1,coil,:))';
end
% coil=96;
% figure;
% plot(patchsingletrail(coil,:))
% hold on 
% plot(ECsingletrail(coil,:))
% hold off
% xline(100)
% title(sprintf('Single Trail-coil%d',coil),'FontSize', 14,'FontWeight', 'bold')
% legend('patch','EC')

%% MEAN TRAIL(ec-100,12PATCH-40)
patchmeantrail=zeros(96,1640);
ECmeantrail=zeros(96,1640);
for coil=1:96
    for condition=1:12
        patchmeantrail(coil,:)=patchmeantrail(coil,:)+squeeze(mean(clusterdata_patch{1,condition}(:,coil,:),1))';
        
    end
    ECmeantrail(coil,:)=squeeze(mean(clusterdata_EC{1}(:,coil,:),1))';
end
coil=96;
figure;
plot(patchmeantrail(coil,:))
hold on 
plot(ECmeantrail(coil,:))
hold off
xline(100)
title(sprintf('Mean Trail-coil%d',coil),'FontSize', 14,'FontWeight', 'bold')
legend('patch','EC')

%% MEAN TRAIL(patch-40)
for condition =1:14
    clusterdata_patch{4,condition} = squeeze(mean(clusterdata_patch{1,condition}(:,:,1:1640),1));
end
ECmeantrail40 = zeros(96,1640);
for coil=1:96
    ECmeantrail40(coil,:)=squeeze(mean(clusterdata_EC{1}(1:35,coil,:),1))';
end
%% test
for coil = 1:96
    for i = 1:(floor(1640/5)-1)
        test(coil,i) = mean(ECmeantrail40(coil,((i-1)*5+1):i*5),2);
        for location = 1:14
            patchtest(coil,i,location) = mean(clusterdata_patch{4,location}(coil,((i-1)*5+1):i*5),2);
        end
    end
end
%% plot
coil = 90;
figure;
plot(a,smoothdata(test(coil,:),'gaussian',8),'LineWidth',2)
hold on 
for i = [2,3,7,11,12,14]
    plot(a,smoothdata(squeeze(patchtest(coil,:,i)),'gaussian',8),'LineWidth',2)
end
hold off
xline(100)
legend('EC','patch2','patch3','patch7','patch11','patch12','SC')

%% 信号水平
EC_MUAmeanvalue = mean(test(:,21:25),2);
patch_MUAmeanvalue = squeeze(mean(patchtest(:,21:25,:),2));
figure;
imagesc(cat(2,EC_MUAmeanvalue,patch_MUAmeanvalue));

%%
coil=2;
figure;
plot(clusterdata_patch{4,1}(coil,:))
hold on 
plot(ECmeantrail40(coil,:))
hold off
xline(100)
title(sprintf('Mean Trail40-coil%d',coil),'FontSize', 14,'FontWeight', 'bold')
legend('patch','EC')
%% hanming
% 采样率
sampleRate = 500; % Hz
fftlength = 1000;
% 使用汉明窗计算功率谱密度
window = hamming(256); % 汉明窗大小
noverlap = 128; % 重叠样本数
nfft = 4096; % FFT 点数
ECfft = zeros(2049,96);
patchfft = zeros(2049,96);
SCfft = zeros(2049,96);
Singlepatchfft = zeros(2049,96);
% 计算功率谱密度
for coil = 1:96
    [Pxx, ~] = pwelch(ECmeantrail40(coil,:)', window, noverlap, nfft, sampleRate);
    ECfft(:,coil) = Pxx;
    [Pxx1, ~] = pwelch(patchmeantrail(coil,:)', window, noverlap, nfft, sampleRate);
    patchfft(:,coil) = Pxx1;
    [Pxx3, ~] = pwelch(clusterdata_patch{4,14}(coil,:)', window, noverlap, nfft, sampleRate);
    SCfft(:,coil) = Pxx3;
    [Pxx4, f] = pwelch(clusterdata_patch{4,3}(coil,:)', window, noverlap, nfft, sampleRate);
    Singlepatchfft(:,coil) = Pxx4;
end
%% 52,206
coil = 96;
figure;
plot(f(1:fftlength),10*log10(ECfft(1:fftlength,coil)))
hold on 
plot(f(1:fftlength),10*log10(patchfft(1:fftlength,coil)))
plot(f(1:fftlength),10*log10(SCfft(1:fftlength,coil)))
plot(f(1:fftlength),10*log10(Singlepatchfft(1:fftlength,coil)))
hold off
title(sprintf('PSD-coil%d',coil))
xline([6.25 12.5 18.75 25],'--')
legend('EC','patchALL','SC','patch1')

%% 相干性
sampleRate = 500; % Hz

% 使用汉明窗计算功率谱密度
window = hamming(256); % 汉明窗大小
noverlap = 128; % 重叠样本数
nfft = 1024; % FFT 点数
coherence = zeros(96,513);
for coil = 1:96
    [Cxy, f] = mscohere(ECmeantrail40(coil,:), patchmeantrail(coil,:), window, noverlap, nfft, sampleRate);
    coherence(coil,:) = Cxy;    
end
[hz25_hz6cor,p] = corrcoef(coherence(:,14),coherence(:,53));%p = 0.0019,R = 0.3124,显著相关
figure;
boxplot(coherence(:,[14 27 53]));
title('Coherence between patch and EC')
xticklabels({'6.25hz','12.5hz','25hz'})
fprintf(hz25_hz6cor)
% figure;
% imagesc([coherence(:,14),coherence(:,53)])
% title('Coherence Heatmap')
% xlabel([1,2]);
% %xticklabels({'6.25hz','25hz'})

%% patch old
%平均
all_patch = {};
for ori = 1:9
    for location  = 1:13
        all_patch{location,ori} = squeeze(mean(all_orient{location,ori},1))*29/86;
    end
end
clearvars -except all_patch
trail_num = length(all_orient{1,1}(:,1,1));
for ori = 1:9
    for location  = 1:13
        all_patch{location,ori} = all_patch{location,ori}+squeeze(mean(all_orient{location,ori},1))*trail_num/86;
    end
end

%% patch psd
sampleRate = 500; % Hz
fftlength = 1000;
% 使用汉明窗计算功率谱密度
window = hamming(256); % 汉明窗大小
noverlap = 128; % 重叠样本数
nfft = 4096; % FFT 点数

patchfft = {};
% 计算功率谱密度
for ori = 1:9
    for location = 1:13
        for coil = 1:96  
            [Pxx1, ~] = pwelch(all_patch{location,ori}(coil,:)', window, noverlap, nfft, sampleRate);
            patchfft{location,ori}(:,coil) = Pxx1;
           
        end
    end
end
% 52,206
coil = 96;
figure;
plot(f(1:fftlength),10*log10(ECfft(1:fftlength,coil)))
hold on 
plot(f(1:fftlength),10*log10(patchfft(1:fftlength,coil)))
plot(f(1:fftlength),10*log10(SCfft(1:fftlength,coil)))
plot(f(1:fftlength),10*log10(Singlepatchfft(1:fftlength,coil)))
hold off
title(sprintf('PSD-coil%d',coil))
xline([6.25 12.5 18.75 25],'--')
legend('EC','patchALL','SC','patch1')






