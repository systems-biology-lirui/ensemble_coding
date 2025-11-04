channel1 =[74,67,68,72,45,38,40,86,7,87,58,91,92,25,94,29,64,61,56,30];
channel2 = [74,67,69,68,72,81,1,33,35,39,45,82,34,36,38,40,86,7,51,53,87,6,9,17,15,55,8,58,57,91,92,25,21,60,94,14,20,27,29,64,61,56,28,30,59];
channels{1} =channel1;
channels{2} = channel2;
subtitles = {'channelsnum = 20','channelsnum = 45'};
figure;
for i = 2
    subplot(1,2,i)
    channel = channels{1};
    hold on;
    for meannum = 10
       
        fprintf('channel = %d, finaltrial = %d',i,meannum);
        SSVEP_PIC_DATA1 = cell(18,6);
        for op=  1:108
            SSVEP_PIC_DATA1{op} =trialmean(SSVEP_PIC_DATA{op}(1:585,:,:),meannum);
        end

        % ------------------------Ori decoding ---------------------------%
        data = [];
        for ori = 1:18
            data(ori,:,:,:) =cat(1,SSVEP_PIC_DATA1{ori,:});
        end
        [acc_real_mean, p_value, perm_accuracies_mean,detailed_results,mm] = SVM_Decoding_LR(single(data([1,9],:,channel,:)), 0, 50);
        
        % ----------------------ori1 pattern ------------------------------%
        for pattern = 1:6
            patterndata(pattern,:,:,:) = SSVEP_PIC_DATA1{1,pattern};
        end
        [acc_real_mean1, p_value, perm_accuracies_mean,detailed_results,mm1] = SVM_Decoding_LR(single(patterndata(1:2,:,channel,:)), 0, 50);

        % ----------------------ori1 pattern ------------------------------%
        for pattern = 1:6
            patterndata(pattern,:,:,:) = SSVEP_PIC_DATA1{9,pattern};
        end
        [acc_real_mean2, p_value, perm_accuracies_mean,detailed_results,mm2] = SVM_Decoding_LR(single(patterndata(1:2,:,channel,:)), 0, 50);

        plot(smooth(acc_real_mean),'LineWidth',2,'DisplayName',sprintf('finaltrial = %d',meannum));

    end
    legend();
    xticks(0:10:100)
    yline(1/18,'--')
    xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160'})
    subtitle(subtitles{i})
end
%%
% channel1 =[74,67,68,72,45,38,40,86,7,87,58,91,92,25,94,29,64,61,56,30];
% channel2 = [74,67,69,68,72,81,1,33,35,39,45,82,34,36,38,40,86,7,51,53,87,6,9,17,15,55,8,58,57,91,92,25,21,60,94,14,20,27,29,64,61,56,28,30,59];
channel1 =[25,20,29,22,24,26,32,59,94,21,27,28,61,30,93];
channel2 = [ 31	26	21	32	20	28	60	94	59	29	52 ,96	22	64	61	95	24	30	62	16	25	27	93	23	12	91	57	58];
channel0 = [6	9	17	15	50	46	56	55	89	90	8	11	13	19	54	52	58	57	91	92	10	12	23	25	21	62	60	59	94	93	14	16	20	27	29	31	64	61	63	96	18	22	24	26	28	30	32	95];
% channel2 = [];
channel3 = setdiff(channel0,channel2);
dd = SG;
data  = [];
trialnum = 140;
for ori = 1:18
    data(ori,:,1,:) = squmean(dd(ori).Data(1:trialnum,channel1,:),2);
    data(ori,:,2,:) = squmean(dd(ori).Data(1:trialnum,channel2,:),2);
    data(ori,:,3,:) = squmean(dd(ori).Data(1:trialnum,channel3,:),2);
end

[acc_real_mean, p_value, perm_accuracies_mean,detailed_results] = SVM_Decoding_LR(single(data([1,3,5,7,9],:,:,:)), 0, 50);
decodingdata = [];
for ori = 1:18
    decodingdata(ori,:,:,:) = dd(ori).Data(1:trialnum,channel2,:);
end
[acc_real_mean1, p_value, perm_accuracies_mean,detailed_results] = SVM_Decoding_LR(single(decodingdata(1:18,:,:,:)), 0, 50);
figure;
hold on;
plot(smooth(acc_real_mean),'LineWidth',2);
plot(smooth(acc_real_mean1),'LineWidth',2);
xticks(0:10:100)
yline(1/18,'--')
xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160'})
legend({'mean-channel','multi-channel'})
%%
clear;
load('SSVEP_PIC_DATA_Bnew_QQ_MUA2_MGv.mat')
MGv = SSVEP_PIC_DATA;
load('SSVEP_PIC_DATA_Bnew_QQ_MUA2_SG.mat')
SG = SSVEP_PIC_DATA;
clear SSVEP_PIC_DATA
MGv1 = {};
SG1 = {};
for ori = 1:18
    for pattern = 1:6
        if ~isempty(MGv{ori,pattern})
            MGv1{ori,pattern} = trialmean(MGv{ori,pattern});
            SG1{ori,pattern} = trialmean(SG{ori,pattern});
        end
    end
end
ch =94;
mm = size(SG1{1,1},1);
a = cat(4,SG1{:});
a = reshape(a,[mm,ch,100,18,6]);
trainData1 = permute(reshape(permute(a,[5,1,2,3,4]),[mm*6,94,100,18]),[4,1,2,3]);

mm = size(MGv1{1,1},1);
b = cat(4,MGv1{:});
b = reshape(b,[mm,ch,100,18,6]);
testData = permute(reshape(permute(b,[5,1,2,3,4]),[mm*6,94,100,18]),[4,1,2,3]);


load('D:\Ensemble coding\QQdata\tooldata\QQchannelselect.mat')
selected_channel_final = [79,43,78,81,47,49,85,42,46,89,58,91,92,25,21,62,60,20,27,22,24,26];
% selected_channel_final = [75,79,43,78,81,41,45,82,84,38,47,49,85,42,44,51,88,17,50,46,89,8,54,52,58,91,92,23,25,21,62,60,14,16,20,27,29,31,63,56,22,24,26,28]
[accuracies_cv_train1,accuracies_test1]= generalizationDecoding(trainData1(:,:,selected_channel_final,:),testData(:,:,selected_channel_final,:),'cross-temporal');
%%
data = {};
channel = 64;
k = [1,5,10,15,20,30,50,100];
for m = 1:length(k)
data{1,1} = ttmean(squeeze(squmean(SSVEP_PIC_DATA{1,1}(1:585,channel,36:40),3)),k);
data{1,2} = ttmean(squeeze(squmean(SSVEP_PIC_DATA{1,1}(1:585,channel,61:65),3)),k);
data{2,1} = ttmean(squeeze(squmean(SSVEP_PIC_DATA{9,1}(1:585,channel,36:40),3)),k);
data{2,2} = ttmean(squeeze(squmean(SSVEP_PIC_DATA{9,1}(1:585,channel,61:65),3)),k);

figure;
subplot(1,2,1)
hold on 
for i = 1:2
    histogram(data{i,1},[0:0.1:1]);
end

subplot(1,2,2)
hold on 
for i = 1:2
    histogram(data{i,2},[0:0.1:1]);
end
end
function finaldata = ttmean(data,minnum)
    trialnum =  size(data);
    m = floor(trialnum/minnum);
    n = trialnum-mod(trialnum,minnum);
    o = n/m;
    
    midata = reshape(data(1:n),[o,m]);
    finaldata = squmean(midata,2);
end

function finaldata = trialmean(data,minnum)
    [trialnum,channel,time] =  size(data);
    m = floor(trialnum/minnum);
    n = minnum*m;
    
    midata = reshape(data(1:n,:,:),[minnum,m,channel,time]);
    finaldata = squmean(midata,1);
end
