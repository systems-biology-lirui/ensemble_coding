%% SSVEP中抽出图像
dbstop if error
label = {'MGv'};
macaque = 'QQ';
file_path = sprintf('D:/Ensemble coding/%sdata/Processed_Event/',macaque);
MUA_LFP = 'MUA2';
for i = 1:length(label)
    filename = sprintf('%s_SSVEP_Days1_27_%s_%s.mat',macaque,MUA_LFP,label{i});
    file_idx{i} = fullfile(file_path,filename);
end
label2 = 'Aold';

% SSVEP_Pic(file_idx,MUA_LFP,label);
SSVEP_Pic_Preallocated(file_idx, MUA_LFP, label, label2)

%% 拟合图片
load('SSVEP_PIC_DATA_Bnew_QQ_MUA2_SSGv.mat')
SSGv = SSVEP_PIC_DATA;
load('SSVEP_PIC_DATA_Bnew_QQ_MUA2_MGv.mat')
MGv = SSVEP_PIC_DATA;
clear SSVEP_PIC_DATA
%%
fitMGv = cell(18,6);
resMGv = cell(18,6);
MGv1 = {};
SSGv1 = {};
frequency = [50,100];
for m = 1:2
    [h1{m},h2{m}] = notch_filter(500, frequency(m), 10);
end

for ori = 1:18
    for pattern = 1:6
        if ~isempty(MGv{ori,pattern})
            MGv1{ori,pattern} = trialmean(MGv{ori,pattern});
            
            for location = 1:12
                SSGv1{ori,pattern,location} = trialmean(SSGv{ori,pattern,location});
            end
%             for m = 1:2
%                 for trial = 1:5
%                     for channel = 1:94
%                         MGv1{ori,pattern}(trial,channel,:) = filtfilt(h1{m},h2{m},squeeze(MGv1{ori,pattern}(trial,channel,:)));
%                         for location = 1:12
%                             SSGv1{ori,pattern,location}(trial,channel,:) = filtfilt(h1{m},h2{m},squeeze(SSGv1{ori,pattern,location}(trial,channel,:)));
%                         end
%                     end
%                 end
%             end
            [a,b,c] = size(MGv1{ori,pattern});
            fitMGv{ori,pattern} = zeros(a,b,c,'single');
            basedata = squmean(cat(4,SSGv1{ori,pattern,1:12}),1);
            realdata = squmean(MGv1{ori,pattern},1);
            % method           - (可选) 指定计算方法的字符串:
            % 'linear_unconstrained' (默认) - 标准多元线性回归，包含截距项，
            % 'linear_constrained'   - 线性回归，但对权重施加约束：
            % 'sum'                  - 直接将所有预测信号相加，不进行任何拟合。
            % 'scaled_sum'           - 先将所有预测信号相加，然后对这个“和信号”进行增益(gain)和偏移(offset)的线性拟合。
            method ='linear_unconstrained';
            [R{ori,pattern},W{ori,pattern},~] = trial_fitting(realdata,basedata,method);
            switch method
                case 'linear_unconstrained'
                    for channel = 1:94
                        for location = 1:12
                            fitMGv{ori,pattern}(:,channel,:) = fitMGv{ori,pattern}(:,channel,:)+SSGv1{ori,pattern,location}(:,channel,:)*W{ori,pattern}(channel,location+1);
                        end
                        fitMGv{ori,pattern}(:,channel,:) = fitMGv{ori,pattern}(:,channel,:)+W{ori,pattern}(channel,1);
                    end
                case 'scaled_sum'
                    summed_ssg = zeros(size(SSGv1{ori,pattern,1}));
                    for location = 1:12
                        summed_ssg = summed_ssg + SSGv1{ori,pattern,location};
                    end
                    for channel = 1:94
                        offset = W{ori,pattern}(channel, 1);
                        gain   = W{ori,pattern}(channel, 2);
                        fitMGv{ori,pattern}(:, channel, :) = summed_ssg(:, channel, :) * gain + offset;
                    end
            end
            resMGv{ori,pattern} = MGv1{ori,pattern}-fitMGv{ori,pattern};
%             if size(fitMGv{ori,pattern},1)>360
%                 fitMGv{ori,pattern} = fitMGv{ori,pattern}(1:36,:,:);
%                 resMGv{ori,pattern} = resMGv{ori,pattern}(1:36,:,:);
%             elseif size(MGv1{ori,pattern},1)==180
%                 fitMGv{ori,pattern} = repmat(fitMGv{ori,pattern},2,1,1);
%                 resMGv{ori,pattern} = repmat(resMGv{ori,pattern},2,1,1);
%             elseif size(MGv1{ori,pattern},1)==90
%                 fitMGv{ori,pattern} = repmat(fitMGv{ori,pattern},4,1,1);
%                 resMGv{ori,pattern} = repmat(resMGv{ori,pattern},4,1,1);
%             end
        end
    end
end

clearvars -except fitMGv resMGv R W

load('SSVEP_PIC_DATA_Anew_QQ_MUA2_MGv.mat')

for i = 1:numel(SSVEP_PIC_DATA)
    SSVEP_PIC_DATA{i} = trialmean(SSVEP_PIC_DATA{i}(:,1:94,:));
end
MGv = SSVEP_PIC_DATA;
clear SSVEP_PIC_DATA
%% generalizationDecoding
ch =94;
mm = size(fitMGv{1,1},1);
a = cat(4,fitMGv{:});
a = reshape(a,[mm,ch,100,18,6]);
trainData1 = permute(reshape(permute(a,[5,1,2,3,4]),[mm*6,94,100,18]),[4,1,2,3]);

mm = size(MGv{1,1},1);
b = cat(4,MGv{:});
b = reshape(b,[mm,ch,100,18,6]);
testData = permute(reshape(permute(b,[5,1,2,3,4]),[mm*6,94,100,18]),[4,1,2,3]);

c = cat(4,resMGv{:});
c = reshape(c,[mm,ch,100,18,6]);
trainData2 = permute(reshape(permute(c,[5,1,2,3,4]),[mm*6,94,100,18]),[4,1,2,3]);

load('D:\Ensemble coding\QQdata\tooldata\QQchannelselect.mat')
selected_coil_final = [79,43,78,81,47,49,85,42,46,89,58,91,92,25,21,62,60,20,27,22,24,26];
% selected_coil_final = [75,79,43,78,81,41,45,82,84,38,47,49,85,42,44,51,88,17,50,46,89,8,54,52,58,91,92,23,25,21,62,60,14,16,20,27,29,31,63,56,22,24,26,28]
[accuracies_cv_train1,accuracies_test1]= generalizationDecoding(trainData1(:,:,selected_coil_final,:),testData(:,:,selected_coil_final,:));
[accuracies_cv_train2,accuracies_test2]= generalizationDecoding(trainData2(:,:,selected_coil_final,:),testData(:,:,selected_coil_final,:));
figure;
subplot(1,2,1)
 hold on
plot(smooth(accuracies_cv_train1))
plot(smooth(accuracies_test1))

subplot(1,2,2)
 hold on
plot(smooth(accuracies_cv_train2))
plot(smooth(accuracies_test2))

%%
ch =94;
mm = 133;
a = cat(4,data{:});
a = reshape(a,[mm,ch,100,15,4]);
b = permute(a,[5,1,2,3,4]);
b = reshape(b,[mm*4,ch,100,15]);
b = permute(b,[4,1,2,3]);
% QQnew 粗选
coil1 = [74,67,69,68,72,81,1,33,35,39,45,82,34,36,38,40,86,7,51,53,87,6,9,17,15,55,8,58,57,91,92,25,21,60,94,14,20,27,29,64,61,56,28,30,59];
coil2 = setdiff(1:96,[52,54,66,78]);
% QQnew 精选
coil3 =[74,67,68,72,45,38,40,86,7,87,58,91,92,25,94,29,64,61,56,30];
% QQold
coil4 = [10	18	19	20	21	22	23	24	25	26	28	31	32	39	43	46	52	56	62	74	75	77	83	84	85	90	88	92	49	76];
[acc_real_mean1, p_value, perm_accuracies_mean,detailed_results] = SVM_Decoding_LR(single(b(:,:,coil4,:)), 0, 50);

figure;
subplot(1,2,1);
hold on
plot(smooth(acc_real_mean1),'LineWidth',2,'Color','b');
subplot(1,2,2);
hold on
for i = 1:size(a,4)
        c = squeeze(a(:,:,:,i,:));
%         c = reshape(c,[6,5,94,100,6]);
%         c = permute(squmean(c,2),[4,1,2,3]);
        c = permute(c,[4,1,2,3]);
        [acc_real_mean, p_value, perm_accuracies_mean,detailed_results] = SVM_Decoding_LR(single(c(:,:,coil4,:)), 0, 50);
        % plot(accuracy(i,:),'LineStyle','--','LineWidth',0.5);
        accuracy(i,:) = acc_real_mean;
end
plot(mean(accuracy,1),'LineWidth',2,'Color','k');
subplot(1,2,1)
hold on
plot(smooth(mean(accuracy,1)),'LineWidth',2,'Color','r');
subplot(1,2,1)
xticks(0:10:100)
xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160'})
subtitle('Orientation Decoding')
xlabel('Time(ms)')
ylabel('Accuracy')
yline(0.0556,'--');
xline(20)
subplot(1,2,2)
xticks(0:10:100)
xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160'})
subtitle('Pattern Decoding')
xlabel('Time(ms)')
ylabel('Accuracy')
yline(0.1667,'--');
xline(20)
%%
a = permute(comb_trial_signals,[3,4,1,5,2]);
size(a)
coil3 =[10	18	19	20	21	22	23	24	25	26	28	31	32	39	43	46	52	56	62	74	75	77	83	84	85	90	88	92	49	76];
a = permute(comb_trial_signals,[3,4,1,5,2]);
a = a(:,1:585,coil3,:,:);
for ori = 1:18
    b = squeeze(a(:,:,:,:,ori));
    b = permute(b,[2,3,4,1]);
    b = squmean(reshape(b,[9,585/9,30,75,6]),1);
    b = permute(b,[4,1,2,3]);
    [acc_real_mean, p_value, perm_accuracies_mean,detailed_results] = SVM_Decoding_LR(single(b), 0, 50);
    accuracy(ori,:) = acc_real_mean;
end
plot(smooth(mean(accuracy,1)),'LineWidth',2,'Color','k');
xticks(0:10:90)
xticklabels({'-20','0','20','40','60','80','100','120','140','160'})
yline(1/6,'--')
%%
a = reshape(a,[850*6,length(coil3),100,18]);
a = squmean(reshape(a,[60*5,17,length(coil3),100,18]),1);
a = permute(a,[4,1,2,3]);
[acc_real_mean1, p_value, perm_accuracies_mean,detailed_results] = SVM_Decoding_LR(single(a), 0, 50);
plot(smooth(acc_real_mean1),'LineWidth',2,'Color','b');
%% 用姜柳明降采样的数据
% for i = 1:18
%     Datainfo = struct();
%     load(sprintf('D:\\Ensemble coding\\QQdata\\500hzdata\\QQ2-u163-%03d-500Hz.mat',i-1));
%     for trial = 1:length(allLFP)
% 
%         original_matrix = allLFP{trial};
%         target_cols = 1640;
%         [rows, cols] = size(original_matrix);
% 
%         if cols < target_cols
%             padded_matrix = zeros(rows,target_cols);
%             padded_matrix(:, 1:cols) = original_matrix;
%             allLFP{trial} = [];
%             allLFP{trial} = padded_matrix;
% 
%         end
% 
%         original_matrix = allMUA{trial};
%         target_cols = 1640;
%         [rows, cols] = size(original_matrix);
% 
%         if cols < target_cols
%             padded_matrix = zeros(rows,target_cols);
%             padded_matrix(:, 1:cols) = original_matrix;
%             allMUA{trial} = [];
%             allMUA{trial} = padded_matrix;
%         end
% 
%         allLFP{trial} = allLFP{trial}(:,1:1640);
% 
%         allMUA{trial} = allMUA{trial}(:,1:1640);
%     end
%     Datainfo.trial_LFP = double(permute(cat(3,allLFP{:}),[3,1,2]));
%     Datainfo.trial_MUA{2} = double(permute(cat(3,allMUA{:}),[3,1,2]))/100;
%     respCode(respCode==-2)=-1;
%     Datainfo.VSinfo.sMbmInfo.respCode = respCode;
%     save(sprintf('D:\\Ensemble coding\\QQdata\\500hzdata\\QQ2-u163-%03d-500Hz.mat',i-1),"allMUA","allLFP","respCode","Datainfo")
%     disp(i)
% end

function finaldata = trialmean(data)
    [trialnum,channel,time] =  size(data);
    m = floor(trialnum/5);
    n = trialnum-mod(trialnum,5);
    o = n/m;
    
    midata = reshape(data(1:n,:,:),[o,m,channel,time]);
    finaldata = squmean(midata,2);
end
