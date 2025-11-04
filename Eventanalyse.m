

%% Event重新组织
label = {'MGv','MGnv','SG','centerSSGnv'};
macaque = 'QQ';
file_path = sprintf('D:/ensemble_coding/%sdata/Processed_Event/',macaque);
mua_lfp = 'MUA2';
for i = 1:length(label)
    filename = sprintf('%s_EVENT_Days39_42_%s_%s.mat',macaque,mua_lfp,label{i});
    file_idx{i} = fullfile(file_path,filename);
end
label2 = 'new';
EVENT_Pic_Preallocated(file_idx, mua_lfp, label, label2)


%% centerSSGnv
date = 25:29;
load(sprintf('D:\\ensemble_coding\\DGdata\\Processed_Event\\DG_EVENT_Days%d_%d_MUA2_SSGnv.mat',date(1),date(end)));
condition = 1:18;
for i = 1:18; centerSSGnv(i).Block = 'centerSSGnv'; centerSSGnv(i).Target_Ori = condition(i); centerSSGnv(i).Location = 13;end
for i = 1:18
    centerSSGnv(i).Data = SSGnv(216+i).Data;
    centerSSGnv(i).Pattern = SSGnv(216+i).Pattern;
    centerSSGnv(i).Pic_Ori = SSGnv(216+i).Pic_Ori;
end
save(sprintf('D:\\ensemble_coding\\DGdata\\Processed_Event\\DG_EVENT_Days%d_%d_MUA2_centerSSGnv.mat',date(1),date(end)),'centerSSGnv');

%% Decoding1

label = {'MGv','MGnv','SG','centerSSGnv'};
macaque = 'DG';
file_path = sprintf('D:/ensemble_coding/%sdata/Processed_Event/',macaque);
mua_lfp = 'MUA2';
channel1 = [27,24,29,26,62,31,28,64,30,59,61,32];
% channel1 =[74,67,68,72,45,38,40,86,7,87,58,91,92,25,94,29,64,61,56,30];
channel2 = [74,67,69,68,72,81,1,33,35,39,45,82,34,36,38,40,86,7,51,53,87,6,9,17,15,55,8,58,57,91,92,25,21,60,94,14,20,27,29,64,61,56,28,30,59];
channel3 = 1:96;
channels{1} = channel1;
channels{2} = channel2;
channels{3} = channel3;
subtitles = {'channelsnum = 20','channelsnum = 45','channelsnum = 20','channelsnum = 45'};

for i = 1:length(label)
    filename = sprintf('%s_EVENT_Days25_29_%s_%s.mat',macaque,mua_lfp,label{i});
    file_idx{i} = fullfile(file_path,filename);
end
figure;
for i = 1:length(label)
    fprintf(label{i})
    predata = load(file_idx{i});
    data = [];
    for ori = 1:18
        data(ori,:,:,:) = predata.(label{i})(ori).Data(1:140,:,:);
    end
    for c = 1
    [acc1, p_value, perm_accuracies_mean,detailed_results] = SVM_Decoding_LR(single(data([1,9],:,channels{c},:)), 1, 50);
    acc_all{i,c} = acc1;
    p{i,c} = p_value;
    shuffle{i,c} = perm_accuracies_mean;
    end
end
%%
Colors = lines(4);
for i = [1,3]
    subplot(1,3,i)
    for l = 1:4
        hold on
        plot(smooth(acc_all{l,i}),'LineWidth',2,'DisplayName',sprintf(label{i}),'Color',Colors(l,:))
        plot(smooth(shuffle{l,i}),'LineWidth',1,'Color',[0.6,0.6,0.6])
        m = find(p{l,i}<0.05);
        y_marker_pos = 0.5-l*0.02;
        stem(m, repmat(y_marker_pos, size(m)), '.', 'MarkerFaceColor', 'k', ...
        'MarkerSize', 5, 'LineWidth', 1, 'Clipping', 'off','LineStyle','none','MarkerEdgeColor',Colors(l,:));
    end
    subtitle(subtitles{i})
    legend();
    xticks(0:10:100)
    yline(1/2,'--')
    xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160'})
    ylim([0.4,1])
end

%% Decoding2
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

function finaldata = trialmean(data,minnum)
    [trialnum,channel,time] =  size(data);
    m = floor(trialnum/minnum);
    n = minnum*m;
    
    midata = reshape(data(1:n,:,:),[minnum,m,channel,time]);
    finaldata = squmean(midata,1);
end

