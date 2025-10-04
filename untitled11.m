 for i=  1:108
SSVEP_PIC_DATA{i} =trialmean(SSVEP_PIC_DATA{i}(1:585,:,:));
 end
 for ori = 1:18
     data(ori,:,1,:) =cat(4,SSVEP_PIC_DATA{ori,:});
 end
%%
% coil1 =[74,67,68,72,45,38,40,86,7,87,58,91,92,25,94,29,64,61,56,30];
% coil2 = [74,67,69,68,72,81,1,33,35,39,45,82,34,36,38,40,86,7,51,53,87,6,9,17,15,55,8,58,57,91,92,25,21,60,94,14,20,27,29,64,61,56,28,30,59];
coil1 =[25,20,29,22,24,26,32,59,94,96,21,27,28,61,30,93];
coil2 = [ 31	26	21	32	20	28	60	94	59	29	52 ,96	22	64	61	95	24	30	62	16	25	27	93	23	12	91	57	58];
coil0 = [6	9	17	15	50	46	56	55	89	90	8	11	13	19	54	52	58	57	91	92	10	12	23	25	21	62	60	59	94	93	14	16	20	27	29	31	64	61	63	96	18	22	24	26	28	30	32	95];
% coil2 = [];
coil3 = setdiff(coil0,coil2);
dd = SG;
data  = [];
trialnum = 140;
for ori = 1:18
    data(ori,:,1,:) = squmean(dd(ori).Data(1:trialnum,coil1,:),2);
    data(ori,:,2,:) = squmean(dd(ori).Data(1:trialnum,coil2,:),2);
    data(ori,:,3,:) = squmean(dd(ori).Data(1:trialnum,coil3,:),2);
end

[acc_real_mean, p_value, perm_accuracies_mean,detailed_results] = SVM_Decoding_LR(single(data(1:18,:,:,:)), 0, 50);
decodingdata = [];
for ori = 1:18
    decodingdata(ori,:,:,:) = dd(ori).Data(1:trialnum,coil2,:);
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
selected_coil_final = [79,43,78,81,47,49,85,42,46,89,58,91,92,25,21,62,60,20,27,22,24,26];
% selected_coil_final = [75,79,43,78,81,41,45,82,84,38,47,49,85,42,44,51,88,17,50,46,89,8,54,52,58,91,92,23,25,21,62,60,14,16,20,27,29,31,63,56,22,24,26,28]
[accuracies_cv_train1,accuracies_test1]= generalizationDecoding(trainData1(:,:,selected_coil_final,:),testData(:,:,selected_coil_final,:),'cross-temporal');


function finaldata = trialmean(data)
    [trialnum,channel,time] =  size(data);
    m = floor(trialnum/5);
    n = trialnum-mod(trialnum,5);
    o = n/m;
    
    midata = reshape(data(1:n,:,:),[o,m,channel,time]);
    finaldata = squmean(midata,2);
end