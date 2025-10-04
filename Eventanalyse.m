

%% Event重新组织
label = {'MGv','MGnv','SG','centerSSGnv'};
macaque = 'QQ';
file_path = sprintf('D:/Ensemble coding/%sdata/Processed_Event/',macaque);
MUA_LFP = 'MUA2';
for i = 1:length(label)
    filename = sprintf('%s_EVENT_Days39_40_%s_%s.mat',macaque,MUA_LFP,label{i});
    file_idx{i} = fullfile(file_path,filename);
end
label2 = 'new';
EVENT_Pic_Preallocated(file_idx, MUA_LFP, label, label2)


%% centerSSGnv
date = 39:40;
load(sprintf('D:\\Ensemble coding\\QQdata\\Processed_Event\\QQ_EVENT_Days%d_%d_MUA2_SSGnv.mat',date(1),date(2)));
condition = 1:18;
for i = 1:18; centerSSGnv(i).Block = 'centerSSGnv'; centerSSGnv(i).Target_Ori = condition(i); centerSSGnv(i).Location = 13;end
for i = 1:18
    centerSSGnv(i).Data = SSGnv(216+i).Data;
    centerSSGnv(i).Pattern = SSGnv(216+i).Pattern;
    centerSSGnv(i).Pic_Ori = SSGnv(216+i).Pic_Ori;
end
save(sprintf('D:\\Ensemble coding\\QQdata\\Processed_Event\\QQ_EVENT_Days%d_%d_MUA2_centerSSGnv.mat',date(1),date(2)),'centerSSGnv');


%%
label = {'MGv','MGnv','SG','centerSSGnv'};

for l = 1:length(label)
    filename = sprintf('EVENT_PIC_DATA_new_QQ_MUA2_%s.mat',label{l});
    load(filename);

    for i = 1:numel(EVENT_PIC_DATA)
        EVENT_PIC_DATA{i} = trialmean(EVENT_PIC_DATA{i}(:,1:94,:));
    end
    ch =94;
    mm = size(EVENT_PIC_DATA{1,1},1);
    a = cat(4,EVENT_PIC_DATA{:});
    a = reshape(a,[mm,ch,100,18,6]);
    selected_coil_final = [79,43,78,81,47,49,85,42,46,89,58,91,92,25,21,62,60,20,27,22,24,26];
    trainData1 = permute(reshape(permute(a,[5,1,2,3,4]),[mm*6,94,100,18]),[4,1,2,3]);
    clear EVENT_PIC_DATA
    [accuracies_cv_train1,accuracies_test1]= generalizationDecoding(trainData1(:,:,selected_coil_final,:),trainData1(:,:,selected_coil_final,:));
    accuracy{l} = accuracies_cv_train1;
    accg{l} = accuracies_test1;
end

function finaldata = trialmean(data)
    [trialnum,channel,time] =  size(data);
    m = floor(trialnum/5);
    n = trialnum-mod(trialnum,5);
    o = n/m;
    
    midata = reshape(data(1:n,:,:),[o,m,channel,time]);
    finaldata = squmean(midata,2);
end

