%% 单通道的朝向解码能力
time_idx = 1:100;
AUC_matrix =  zeros(18,18,96,2);
for ori1 = 1:18
    for ori2 = 1:18
        for channel = 1:96
            cond1_ori1 = squmean(SSGnv(ori1+54).Data(:,channel,time_idx),3);
            cond1_ori2 = squmean(SSGnv(ori2+54).Data(:,channel,time_idx),3);
            cond2_ori1 = squmean(MGnv(ori1).Data(:,channel,time_idx),3);
            cond2_ori2 = squmean(MGnv(ori2).Data(:,channel,time_idx),3);
            labels = [zeros(length(cond1_ori1),1);ones(length(cond1_ori1),1)];
            scores_c1 = [cond1_ori1;cond1_ori2];
            scores_c2 = [cond2_ori1;cond2_ori2];
            posclass = 1; 
            [X1, Y1, T1, AUC1] = perfcurve(labels, scores_c1, posclass);
            [X2, Y2, T2, AUC2] = perfcurve(labels, scores_c2, posclass);

            AUC_matrix(ori1,ori2,channel,1) = AUC1;
            AUC_matrix(ori1,ori2,channel,2) = AUC2;
        end
    end
end
%% 单通道朝向辨别能力的统计
figure;
AUC1_matrix = AUC_matrix;
AUC1_matrix(AUC_matrix<0.5) = 1-AUC_matrix(AUC_matrix<0.5);
imagesc(squmean(AUC1_matrix(:,:,selected_coil_final,2),3));
% channels = setdiff(1:96,selected_coil_final);
channels = 1:96;
data1 = AUC1_matrix(:,:,channels,1);
data2 = AUC1_matrix(:,:,channels,2);
[h, p, ~, stats] = ttest(data1(:),data2(:));
bar([mean(data1(:)),mean(data2(:))]);
%% 群体神经元朝向辨别能力（平均）
time_idx = 1:100;
AUC_matrix =  zeros(18,18,2);
% selected_coil_final = setdiff(1:96,selected_coil_final);
% selected_coil_final = 1:96;
for ori1 = 1:18
    for ori2 = 1:18
            cond1_ori1 = squmean(SSGnv(ori1+216).Data(:,selected_coil_final,time_idx),[2,3]);
            cond1_ori2 = squmean(SSGnv(ori2+216).Data(:,selected_coil_final,time_idx),[2,3]);
            cond2_ori1 = squmean(MGnv(ori1).Data(:,selected_coil_final,time_idx),[2,3]);
            cond2_ori2 = squmean(MGnv(ori2).Data(:,selected_coil_final,time_idx),[2,3]);
            labels = [zeros(length(cond1_ori1),1);ones(length(cond1_ori1),1)];
            scores_c1 = [cond1_ori1;cond1_ori2];
            scores_c2 = [cond2_ori1;cond2_ori2];
            posclass = 1; 
            [X1, Y1, T1, AUC1] = perfcurve(labels, scores_c1, posclass);
            [X2, Y2, T2, AUC2] = perfcurve(labels, scores_c2, posclass);

            AUC_matrix(ori1,ori2,1) = AUC1;
            AUC_matrix(ori1,ori2,2) = AUC2;
    end
end
%% 群体神经元朝向辨别能力统计（平均通道）
figure;
AUC1_matrix = AUC_matrix;
AUC1_matrix(AUC_matrix<0.5) = 1-AUC_matrix(AUC_matrix<0.5);
imagesc(squeeze(AUC1_matrix(:,:,1)-AUC1_matrix(:,:,2)));
data1 = AUC1_matrix(1:16,1:16,1);
data2 = AUC1_matrix(1:16,1:16,2);
[h, p, ~, stats] = ttest(data1(:),data2(:));
figure;
bar([mean(data1(:)),mean(data2(:))]);