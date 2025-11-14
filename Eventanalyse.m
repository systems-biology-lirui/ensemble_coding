

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
date = 39:42;
load(sprintf('D:\\ensemble_coding\\QQdata\\Processed_Event\\QQ_EVENT_Days%d_%d_LFP_SSGnv.mat',date(1),date(end)));
condition = 1:18;
for i = 1:18; centerSSGnv(i).Block = 'centerSSGnv'; centerSSGnv(i).Target_Ori = condition(i); centerSSGnv(i).Location = 13;end
for i = 1:18
    centerSSGnv(i).Data = SSGnv(216+i).Data;
    centerSSGnv(i).Pattern = SSGnv(216+i).Pattern;
    centerSSGnv(i).Pic_Ori = SSGnv(216+i).Pic_Ori;
end
save(sprintf('D:\\ensemble_coding\\QQdata\\Processed_Event\\QQ_EVENT_Days%d_%d_LFP_centerSSGnv.mat',date(1),date(end)),'centerSSGnv');

%% Decoding1
a = {'DG','QQ','QQ'};
b = {'DG','QQ_old','QQ_new'};
c = {'LFP','MUA2'};
d = [25,29; 2,27; 39,42];
label = {'fitMGnv','resMGnv'};
load('sel_channel_Yge.mat','sel_channel');
for macaque_idx = 1:33
    macaque = a{macaque_idx};
    file_path = sprintf('D:/ensemble_coding/%sdata/Processed_Event/',macaque);
    for data_idx = 2
        mua_lfp = c{data_idx};
        channels = sel_channel.(b{macaque_idx});
        
        % subtitles = {'channelsnum = 20','channelsnum = 45','channelsnum = 20','channelsnum = 45'};

        for i = 1:length(label)
            data_date = d(macaque_idx,:);
            filename = sprintf('%s_EVENT_Days%d_%d_%s_%s.mat',macaque,data_date(1),data_date(2),mua_lfp,label{i});
            file_idx{i} = fullfile(file_path,filename);
        end
        for i = 1:length(label)
            fprintf(label{i})
            predata = load(file_idx{i});
            minnum = 1000;
            for ori = 1:18
                ori_num = size(predata.(label{i})(ori).Data,1);
                if ori_num<minnum
                    minnum = ori_num;
                end
            end
            data = zeros(18,minnum,length(channels),100,'single');
            for ori = 1:18
                data(ori,:,:,:) = predata.(label{i})(ori).Data(1:minnum,channels,:);
            end

            [acc1, p_value, perm_accuracies_mean,detailed_results,linear_weight] = SVM_Decoding_LR(data, 1, 5,5);
            decoding_result.acc_all.(b{macaque_idx}){i,data_idx} = acc1;
            decoding_result.p.(b{macaque_idx}){i,data_idx} = p_value;
            decoding_result.shuffle.(b{macaque_idx}){i,data_idx} = perm_accuracies_mean;
            decoding_result.details.(b{macaque_idx}){i,data_idx} = detailed_results;
            decoding_result.linear.(b{macaque_idx}){i,data_idx} = linear_weight;
        end
    end
end
% save('decoding_result_Yge_fitres.mat',"decoding_result",'-v7.3');
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

%% Decoding2(pattern之间会进行平均)
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
%% Decoding Plot
figure;
b = {'DG','QQ_old','QQ_new'};
c = {'LFP','MUA2'};
for macaque_idx = 1:3
    for data_idx = 2
        mua_lfp = c{data_idx};
        subplot(3,2,(macaque_idx-1)*2+data_idx);
        hold on
        Colors = lines(4);
        for i = 1:4

            accuracy = cell2mat(decoding_result.details.(b{macaque_idx}){i,data_idx}.real_acc_dist)';
            Chance_Level = cell2mat(decoding_result.details.(b{macaque_idx}){i,data_idx}.perm_acc_dist)';
            [n_timepoints,n_shuffle] = size(Chance_Level);
            
            % 绘制Accuracy()
            plot(1:n_timepoints,mean(accuracy,2),'LineWidth',1.5,'Color',Colors(i,:));
            plot(1:n_timepoints,mean(Chance_Level,2),'LineWidth',1.5,'Color',[0.5,0.5,0.5]);
            
            % 绘制标准误
            accuracy_mean = mean(accuracy,2)';
            accuracy_std = std(accuracy,0,2)';
            x = 1:n_timepoints;
            fill([x fliplr(x)], [accuracy_mean+accuracy_std fliplr(accuracy_mean-accuracy_std)],...
                Colors(i,:), 'EdgeColor', 'none', 'FaceAlpha', 0.3);


            chance_mean = mean(Chance_Level,2)';
            chance_std = std(Chance_Level,0,2)';
            fill([x fliplr(x)], [chance_mean+chance_std fliplr(chance_mean-chance_std)],...
                [0.5,0.5,0.5], 'EdgeColor', 'none', 'FaceAlpha', 0.1);

            p_value = decoding_result.p.(b{macaque_idx}){i,data_idx};

            % 绘制显著点
            m = find(p_value<=0.01);
            y_marker_pos = 1/18-0.01*i;
            stem(m, repmat(y_marker_pos, size(m)), '.', 'MarkerFaceColor', 'k', ...
                'MarkerSize', 5, 'LineWidth', 1, 'Clipping', 'off','LineStyle','none','MarkerEdgeColor',Colors(i,:));

        end
        subtitle(sprintf('%s %s',b{macaque_idx},c{data_idx}));

        ax = gca;
        ax.LineWidth = 2;
        ax.FontSize = 12;
        ax.FontWeight = 'bold';
        ax.XAxis.FontSize = 12;
        ax.YAxis.FontSize = 12;
        ax.XAxis.FontWeight = 'bold';

        xticks(0:10:100);
        xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160'});
    end
end


%% Decoding 权重编码轨迹
a = {'DG','QQ','QQ'};
b = {'DG','QQ_old','QQ_new'};
c = {'LFP','MUA2'};

for macaque_idx = 3
    for data_idx = 1
        mua_lfp = c{data_idx};
        subplot(3,2,(macaque_idx-1)*2+data_idx);
        hold on
        linear_data = {};
        for t = 1:100
            for i = 1:4
                idx = tril(true(18),-1);
                data = decoding_result.linear.(b{macaque_idx}){i,data_idx}{1,t}(idx);
                linear_data{i}(t,:) = mean(cat(2,data{:}),2);
            end
        end
        plot_options = struct();
        plot_options.legend_labels = {'fitMGnv','resMGnv'};
        % plot_options.legend_labels = {'fitMGnv','resMGnv'};
        plot_options.main_title = sprintf('Analysis for %s - %s', b{macaque_idx}, c{data_idx});
        
        % 自定义时间轴
        plot_options.time_axis_info.ticks = 0:10:100;
        plot_options.time_axis_info.labels = {'-40','-20','0','20','40','60','80','100','120','140','160'};
        [results, handles] = analyzeAndPlotTrajectories(linear_data, [1, 2], plot_options);
    end
end


function finaldata = trialmean(data,minnum)
    [trialnum,channel,time] =  size(data);
    m = floor(trialnum/minnum);
    n = minnum*m;
    
    midata = reshape(data(1:n,:,:),[minnum,m,channel,time]);
    finaldata = squmean(midata,1);
end

