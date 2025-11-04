mgv_data = [];
mgnv_data = [];
% selected_coil_final = [74,67,69,68,72,81,1,33,35,39,45,82,34,36,38,40,86,7,51,53,87,6,9,17,15,55,8,58,57,91,92,25,21,60,94,14,20,27,29,64,61,56,28,30,59];
for ori = 1:18
    % mgv_data(ori,:,:,:)= MGv(ori).Data(37:80,1:94,:)-squmean(MGv(ori).Data(37:80,1:94,1:20),3);
    % mgnv_data(ori,:,:,:)= MGnv(ori).Data(37:80,1:94,:)-squmean(MGnv(ori).Data(37:80,1:94,1:20),3);
    mgv_data(ori,:,:,:)= MGv(ori).Data-squmean(MGv(ori).Data(:,:,1:20),3);
    mgnv_data(ori,:,:,:)= MGnv(ori).Data-squmean(MGnv(ori).Data(:,:,1:20),3);
end

decoding_data = permute(cat(4,squmean(mgnv_data,1),squmean(mgv_data,1)),[4,1,2,3]);
%%
[acc_real_mean, p_value, perm_accuracies_mean,detailed_results,mm] = SVM_Decoding_LR(decoding_data(:,1:72,selected_coil_final,:),0,50);
% [acc_real_mean1, p_value, perm_accuracies_mean,detailed_results,mm] = SVM_Decoding_LR(mgv_data(:,:,selected_coil_final,:),0,50);
figure;
plot(smooth(acc_real_mean))
hold on
plot(smooth(acc_real_mean1))
yline([0.0556,0.5],'--')
ylim([0,0.8])

%%
mgv_data = [];
mgnv_data = [];
selected_coil_final = [74,67,69,68,72,81,1,33,35,39,45,82,34,36,38,40,86,7,51,53,87,6,9,17,15,55,8,58,57,91,92,25,21,60,94,14,20,27,29,64,61,56,28,30,59];
for ori = 1:18
    mgv_data(ori,:,:,:)= MGv(ori).Data(1:80,1:94,:)-squmean(MGv(ori).Data(1:80,1:94,1:20),3);
    mgnv_data(ori,:,:,:)= MGnv(ori).Data(1:80,1:94,:)-squmean(MGnv(ori).Data(1:80,1:94,1:20),3);
    % mgv_data(ori,:,:,:)= MGv(ori).Data-squmean(MGv(ori).Data(:,:,1:20),3);
    % mgnv_data(ori,:,:,:)= MGnv(ori).Data-squmean(MGnv(ori).Data(:,:,1:20),3);
end


figure;
for ori = 1:18
    disp(ori)
    decoding_data = cat(1,mgnv_data(ori,:,:,:),mgv_data(ori,:,:,:));
    [acc_real_mean(ori,:), p_value, perm_accuracies_mean,detailed_results,mm] = SVM_Decoding_LR(decoding_data(:,:,selected_coil_final,:),0,50);

end
imagesc(acc_real_mean)
%%
neural_data = [];
% dayidx = {1:36,37:55,55:80};
% dayidx = {1:72,73:114,115:126,127:150};
dayidx = {1:30,31:60,61:90,91:120};
for day = 1:length(dayidx)
    idx = dayidx{day};
    neural_data(day,:,:) = squmean(mgnv_data(:,idx,:,:),[1,2]);
    neural_data(day+length(dayidx),:,:) = squmean(mgv_data(:,idx,:,:),[1,2]);
end
%%
figure;
subplot(1,2,1)
imagesc(squeeze(decoding_data(1,:,62,:)));

subplot(1,2,2)
imagesc(squeeze(decoding_data(2,:,62,:)));

%%
figure;
channels = [67,68];
for ori = 1:18
    for chan = 1:length(channels)
    subplot(length(channels),18,ori+(chan-1)*18)
    imagesc(squeeze(mgnv_data(ori,:,channels(chan),:)))
    subtitle(num2str(channels(chan)))
    end
end