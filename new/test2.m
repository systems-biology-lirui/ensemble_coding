%% 解码
% clear
% dbstop if error
% macaque = 'DG';
% load(sprintf('D:\\Ensemble coding\\%sdata\\tooldata\\%sChannelselect.mat',macaque,macaque),'selected_coil_final');
% selected_blocks = {'MGv','MGnv','SG'};
% % selected_coil_final = [7,65,36,13,17,16,18,20,24,19,28,62,41,75,76,32,49,79,43,81,83,85,88,90,92];
% selected_coil_final = [7,9,13,17,18,19,21,22,23,24,25,27,35,38,39,41,51,61,73,74,80,82,84,87,89]+1;
% Colors = [62,181,95;233,173,107;120,158,175;142,50,40]/255;
% for m = 1:length(selected_blocks)
%     %load(sprintf('SSVEP_PIC_DATA_DG_MUA2_%s.mat',selected_bloc·ks{m}));
% 
%     % !!!!!!!!!!!!!!记得改时间!@!!!!!!!!!!!!!!!!!!!!!!!!
%     data1 = load(sprintf('D:\\Ensemble Coding\\%sdata\\Processed_Event\\%s_EVENT_Days25_29_MUA2_%s.mat',macaque,macaque,selected_blocks{m}));
% 
%     acc_real = [];
%     data = [];
%     n_shuffles = 50;
%     for i = 1:18
%         mm = data1.(selected_blocks{m});
%         data(i,:,:,:) = mm(i).Data(:,selected_coil_final,:);
%     end
% 
    minnum = 1000;
    for i = 1:108
        num = size(SSVEP_PIC_DATA{i},1);
        if num<=minnum
            minnum = num;
        end
    end
    for i = 1:108
        SSVEP_PIC_DATA{i} = SSVEP_PIC_DATA{i}(1:minnum,:,:);
    end
    n = 1:18;
    for i = 1:length(n)
        dd1 = SSVEP_PIC_DATA(:,n(i));
        dd = cat(1,dd1{:});
        for b = 1:6
            SSVEP_PIC_DATA{b,i} = [];
        end
        % num = size(dd,1);

        data(i,:,:,:) = dd(:,:,:);
    end
%     clear SSVEP_PIC_DATA
%     savename = 'SSVEP_Decoding_content';
%     disp(size(data,2));
%     % 把合并计算放在之前
%     for t = 1:(size(data,4)-1)
%         data_new(:,:,:,t) = mean(data(:,:,:,t:(t+1)),4);
%     end
%     [chance_level, accuracy, p_value] = SVM_Decoding_LR(data_new,n_shuffles,selected_blocks{m},savename);
%     clear data
%     % 记得改名字！！！！！！！！！！！！！！！！！！！
%     save(sprintf('D:\\Ensemble Coding\\%sdata\\Decoding\\EVENTorientationSVM_%s_MUA2.mat',macaque,selected_blocks{m}),'chance_level','accuracy','p_value');
% end
% Chance_Level = 1/18;
% file_path = 'D:\\Ensemble Coding\\DGdata\\Decoding\\';
% for i = 1:length(selected_blocks)
%      filename = sprintf('EVENTorientationSVM_%s_MUA2.mat',selected_blocks{i});
%      Accuracy_file{i} = fullfile(file_path,filename);
% end
% Colors = [62,181,95;233,173,107;120,158,175;142,50,40]/255;
% SVM_Decoding_Plot(Accuracy_file,Colors,Chance_Level)
%% 滤波器
% clear;
% dbstop if error
% tic;
% load('D:\\Ensemble Coding\\QQdata\\QQchannelselect.mat','selected_coil_final')
% selected_blocks = {'MGv','MGnv','SG'};
% 
% % 参数设置
% fs = 500; % 采样频率
% f1 = 95; % 带阻下限频率
% f2 = 105; % 带阻上限频率
% order = 4; % 滤波器阶数
% 
% % 设计带阻滤波器
% [b, a] = butter(order, [f1, f2]/(fs/2), 'stop');
% 
% num1 = 490;
% allnum = 460*6;
% coilnum = 8;
% selectcoil = [2,4,6,11,14,15,19,26];
% 
% for m = 1:3
%     n = 1:5:18;
%     load(sprintf('SSVEP_PIC_DATA%sMUA2.mat',selected_blocks{m}));
% 
%     data_reshaped = zeros(length(n),allnum,coilnum,100,'single');
%     for ori = 1:length(n)
% 
%         c= cat(1,SSVEP_PIC_DATA{:,n(ori)});
%         data_reshaped(ori,:,:,:) = c(1:allnum,selected_coil_final(selectcoil),:);
% 
%     end
%     clearvars SSVEP_PIC_DATA
%     n_shuffles = 20;
% 
%     % [accuracy, p_value] = SVM_Decoding_LR(data_reshaped,n_shuffles);
%     % save(sprintf('D:\\Ensembe plot\\QQdecoding\\SSVEPorientationSVM_day_%sMUA2.mat',selected_blocks{m}),'accuracy','p_value');
% end
% Chance_Level = 1/6;
% Accuracy_file={'D:\\Ensemble plot\\QQdecoding\\SSVEPorientationSVM_day_MGvMUA2.mat',...
%     'D:\\Ensemble plot\\QQdecoding\\SSVEPorientationSVM_day_MGnvMUA2.mat',...
%     'D:\\Ensemble plot\\QQdecoding\\SSVEPorientationSVM_day_SGMUA2.mat'};
% Colors = [62,181,95;233,173,107;120,158,175;142,50,40]/255;
% SVM_Decoding_Plot(Accuracy_file,Colors,Chance_Level)

%% 猕猴行为视频
% 示例：数值序列 1:3
% numericSeq = [0:13,19:23];
% preday = 2;
% postday = 5;
% postday1 = 5;
% % 将每个数值转换为字符串并存储到单元格数组中
% strCell = compose('%d', numericSeq);
% a = readtable('macaque1.xlsx','Sheet',1);
% b = a(2:13,3:21);
% % 将 table 转换为单元格数组
% dataCell = table2cell(b);
% 
% % 将字符型数据转换为数值矩阵
% dataMatrix = cell2mat(dataCell);
% % 假设数据已加载为 pre_data 和 post_data（5行天 × 10列小时）
% % 示例数据生成（可替换为实际数据）
% pre_data = dataMatrix(1:2,:);   % 5天 × 10小时，实验前数据
% post_data = dataMatrix(3:7,:);  % 5天 × 10小时，实验后数据
% post_data1 = dataMatrix(8:12,:); 
% 
% % 计算每个小时的均值
% pre_mean = mean(pre_data, 1);  % 按天平均，得到 1×10 的均值
% post_mean = mean(post_data, 1); % 1×10
% post_mean1 = mean(post_data1, 1);
% % 定义柱状图参数
% x = 1:19;            % 小时的位置（1到10）
% barWidth = 0.4;     % 柱状图宽度
% offset = 0.1;        % 散点横向分散的偏移量
% 
% % 绘制柱状图
% figure('Position',[0 0 1200 600])
% hold on;
% 
% % 实验前柱状图（左柱）
% b1 = bar(x - barWidth/2, pre_mean, barWidth/2, ...
%     'FaceColor', [183 245 222]/255, 'EdgeColor', 'k', 'LineWidth', 1);
% 
% % 实验后柱状图（右柱）
% b2 = bar(x , post_mean, barWidth/2, ...
%     'FaceColor', [213 170 190]/255, 'EdgeColor', 'k', 'LineWidth', 1);
% 
% % 实验后柱状图（右柱）
% b3 = bar(x + barWidth/2, post_mean1, barWidth/2, ...
%     'FaceColor', [167 192 223]/255, 'EdgeColor', 'k', 'LineWidth', 1);
% 
% % 在每个柱状图上叠加散点（按天数）
% for iHour = 1:18
%     % 实验前的散点（左柱）
%     xPre = x(iHour) - barWidth/2;
%     for iDay = 1:preday
%         scatter(xPre + (iDay-3)*offset/2, pre_data(iDay, iHour), ...
%             10, 'k', 'filled', 'MarkerEdgeColor', 'k');
%     end
% 
%     % 实验后的散点（右柱）
%     xPost = x(iHour) + barWidth/2;
%     for iDay = 1:postday
%         scatter(xPost + (iDay-3)*offset/2, post_data(iDay, iHour), ...
%             10, 'k', 'filled', 'MarkerEdgeColor', 'k');
%     end
% 
%     xPost1 = x(iHour) + barWidth/2;
%     for iDay = 1:postday1
%         scatter(xPost1 + (iDay-3)*offset/2, post_data1(iDay, iHour), ...
%             10, 'k', 'filled', 'MarkerEdgeColor', 'k');
%     end
% end
% 
% % 美化图形
% set(gca, 'XTick', x);           % 设置小时刻度
% xticklabels(strCell);
% xlabel('小时');
% ylabel('运动量');
% % title('冲击前后的运动量','FontSize',16,'FontWeight','bold');
% legend([b1, b2, b3], {'冲击前', '冲击后','恢复后'}, 'Location', 'northwest','EdgeColor','none');
% grid off;
% hold off;
% ax = gca;
% ax.LineWidth = 2;
% ax.FontSize = 12;
% ax.FontWeight = 'bold';
% ax.XAxis.FontSize = 12;
% ax.YAxis.FontSize = 12;
% ax.XAxis.FontWeight = 'bold';
%% 绘制tuning
% figure;
% for i = 1:18
%    % a = cat(1,SSVEP_PIC_DATA{:,i});
%     a = MGv(i).Data;
%     for channel = 1:96
% 
%         tuning(i,channel,:) = squmean(a(:,channel,:),1);
%     end
% end
% colormap('bone')
% chanmap = load('D:\Ensemble coding\QQdata\QQChannelMap.mat');%QQchannelMap
% load('D:\\Ensemble Coding\\QQdata\\QQchannelselect.mat','selected_coil_final');
% % load('D:\\Ensemble coding\\QQdata\\QQcoilselect','coilselect');
% for i = 1:96
%     n = find(chanmap.QQchannelMap'==i);
%     subplot(10,10,n);
%     meandata = squmean(tuning(:,i,40:60),3);
%     [a,idx] = sort(meandata);
%     tuning(:,i,:) = tuning(:,i,:) - tuning(idx(1),i,:); 
%     imagesc(squeeze(tuning(:,i,:)))
%     % 此条件没有，但总条件有
%     if ismember(i,selected_coil_final) 
% 
%         subtitle(i,'Color','r','FontWeight', 'bold');
%     else
%         subtitle(i)
%     end
% 
%     box off
% end
%% Channel_select
% data_files = {'D:\\EVENT_Days2_14_MUA2_MGv.mat',...
%     'D:\\EVENT_Days2_14_MUA2_MGnv.mat',...
%     'D:\\EVENT_Days2_14_MUA2_SG.mat'};
% Labels = {'MGv','MGnv','SG'};
% num = 30;
% [selected_coil_final,selected_coil] = SNR_calculate_differentblocks(data_files,Labels,num);
% 
% %%
% session_factor = final_sessions{1,1};
% ReFactor = IdxRearrage(respCode,session_factor);
% function ReFactor = IdxRearrage(respCode,session_factor)
% 
% for i = 1:length(respCode)
%     if respCode(i) ~= 1
%         session_factor(end+1) = session_factor(i);
% 
%     end
% end
% idx = respCode == -2;
% session_factor(idx) = [];
% ReFactor = session_factor;
% end
% 
% repeat = zeros(3,18);
% for i = [6,9]
%     for ori = 1:18
%         for session = 1
%             repeat(1,ori) = repeat(1,ori)+allrepeat{i,session}(ori).MGv;
%             repeat(2,ori) = repeat(2,ori)+allrepeat{i,session}(ori).MGnv;
%             repeat(3,ori) = repeat(3,ori)+allrepeat{i,session}(ori).SG;
%         end
%     end
% end

%% 
Days = [34,40];
condsel = [2,6];
macaque = 'QQ';
MUA_LFP = 'LFP';
savepath = sprintf('D:/Ensemble Coding/%sdata/Processed_Event',macaque);
Labels = {'MGv','MGnv','SG','fitMGv','normfitMGv','fitMGnv','normfitMGnv','centerSSGnv'};
% Labels = {'fitMGv','fitMGnv','centerSSGnv'};
% Colors = [62,181,95;233,173,107;120,158,175;142,50,40]/255;
Colors = [175,0,0;175,0,0;175,0,0;175,0,0;175,0,0;175,0,0;175,0,0;175,0,0;175,0,0;175,0,0;175,0,0;175,0,0]/255;
for i = 1 :length(Labels)
file_idx{i} = fullfile(savepath, sprintf('%s_SSVEPB_Days%d_%d_%s_%s.mat',macaque, Days(1), Days(end), MUA_LFP,Labels{i}));
end
% selected_coil_final = [74,67,69,68,72,81,1,33,35,39,45,82,34,36,38,40,86,7,51,53,87,6,9,17,15,55,8,58,57,91,92,25,21,60,94,14,20,27,29,64,61,56,28,30,59];
selected_coil_final = [75,79,43,78,81,41,45,82,84,38,47,49,85,42,44,51,88,17,50,46,89,8,54,52,58,91,92,23,25,21,62,60,14,16,20,27,29,31,63,56,22,24,26,28];
load(sprintf('D:/Ensemble coding/%sdata/tooldata/%schannelselect.mat',macaque,macaque),'selected_coil_final')
% selected_coil_final = [7,9,13,17,18,19,21,22,23,24,25,27,35,38,39,41,51,61,73,74,80,82,84,87,89]+1;
plot_content_savepath = sprintf('%s_exp1b_%s_%s_fftplot',macaque,MUA_LFP,Labels{1});
fftanalyse_plot(condsel,file_idx,Labels,Colors,selected_coil_final,plot_content_savepath)


%% fftanalyse
% for channel = 1:length(selected_coil_final)
% for t = 1:100
%     p_value(t) = ttest(squeeze(SSVEP_PIC_DATA{1,1}(1:700,selected_coil_final(channel),t)),squeeze(SSVEP_PIC_DATA{1,3}(1:700,selected_coil_final(channel),t)));
% end
% end
% for channel = 1:length(selected_coil_final)
% for t = 1:100
%     p_value(t,channel) = ttest(squeeze(MGv(1).Data(:,selected_coil_final(channel),t)),squeeze(MGv(9).Data(:,selected_coil_final(channel),t)));
% end
% end

% Colors = [62,181,95;233,173,107;120,158,175;142,50,40]/255;
% file_idx = {'QQ_SSVEP_Days9_27_LFP_MGnv.mat','QQ_SSVEP_Days9_27_LFP_MGnv.mat','QQ_SSVEP_Days9_27_LFP_MGnv.mat'};
% Labels = {'MGv','MGnv','SG'};
% coilselectfile = 'D:\\Ensemble coding\QQdata\tooldata\QQchannelselect.mat';
% fftanalyse_plot(file_idx,Labels,Colors,coilselectfile)

%% Meta_data名称标准化
% c = 5;
% for ii = 1:length(c)
%     for i = 1:152
%         for m = 1:size(Meta_data{i, c(ii)}, 2)
%             try
%                 % 复制值到新字段
%                 Meta_data{i, c(ii)}(m).Block = Meta_data{i, c(ii)}(m).block; 
%                 Meta_data{i, c(ii)}(m).Location = Meta_data{i, c(ii)}(m).location;
%                 Meta_data{i, c(ii)}(m).Condition = Meta_data{i, c(ii)}(m).condition;
%                 Meta_data{i, c(ii)}(m).Stim_Sequence = Meta_data{i, c(ii)}(m).stim_sequence;
%                 Meta_data{i, c(ii)}(m).Pattern = Meta_data{i, c(ii)}(m).pattern;
%                 Meta_data{i, c(ii)}(m).Pic_Idx = Meta_data{i, c(ii)}(m).pic_idx;
% 
%             catch ME
%                 % 如果出现错误，打印出错误信息和当前的 m 值
%                 fprintf('Error occurred at i=%d, ii=%d, m=%d: %s\n', i, ii, m, ME.message);
%                 % 选择是否继续执行或者退出
%                 % break; % 如果需要退出当前循环，可以取消注释这一行
%             end
%         end
% 
%         % 删除旧字段
%         Meta_data{i, c(ii)} = rmfield(Meta_data{i, c(ii)}, 'block'); 
%         Meta_data{i, c(ii)} = rmfield(Meta_data{i, c(ii)}, 'location'); 
%         Meta_data{i, c(ii)} = rmfield(Meta_data{i, c(ii)}, 'condition'); 
%         Meta_data{i, c(ii)} = rmfield(Meta_data{i, c(ii)}, 'stim_sequence'); 
%         Meta_data{i, c(ii)} = rmfield(Meta_data{i, c(ii)}, 'pattern'); 
%         Meta_data{i, c(ii)} = rmfield(Meta_data{i, c(ii)}, 'pic_idx'); 
%     end
% end
%% ssvep_pic
dbstop if error
label = {'MGv','MGnv','SG'};
macaque = 'QQ';
file_path = sprintf('D:/Ensemble coding/%sdata/Processed_Event/',macaque);
MUA_LFP = 'MUA2';
for i = 1:length(label)
    filename = sprintf('%s_SSVEP1000hz_Days9_27_%s_%s.mat',macaque,MUA_LFP,label{i});
    file_idx{i} = fullfile(file_path,filename);
end


SSVEP_Pic1000(file_idx,MUA_LFP,label);
%---------------------------提取SSVEPA中的pic---------------------------%
function SSVEP_Pic1000(file_idx,MUA_LFP,label)

% 从SSVEP的trial数据中提取处Pic数据
%
% 输入参数：
%   MUA_LFP - 信号选择：1-MUA{1}; 2-MUA{2}; 3-LFP
%
% 输出内容：
%   SSVEP_PIC_DATA - 6*18的cell，phase*ori


for i = 1:length(file_idx)
    data = load(file_idx{i});
    SSVEP_PIC_DATA = cell(18,18);
    for cond = 1:10
        if ~isempty(data.(label{i})(cond).Data)
            
            fprintf(sprintf('start%scond%d\n',label{i},cond));
            trialdata = single(data.(label{i})(cond).Data);
            if isempty(data.(label{i})(cond).Pattern)
                data.(label{i})(cond).Pattern = ones(size(trialdata,1),72);
            end
            for trial = 1:size(trialdata,1)
                for pic = 2:72
                    % window = 200+(pic-1)*40+1+(-40:159);
                    window = 100+(pic-1)*20+1+(-20:79);
                    ori = data.(label{i})(cond).Pic_Ori(trial,pic);
                    preori = data.(label{i})(cond).Pic_Ori(trial,pic-1);
                    % pattern = data.(label{i})(cond).Pattern(trial,pic);
                    currentdata = trialdata(trial,:,window);
                    trialbaseline = mean(trialdata(trial,:,1:100),3);
                    % picbaseline = mean(trialdata(trial,:,window(1:20)),3);
                    picbaseline =0;
                    SSVEP_PIC_DATA{ori,preori} = cat(1,SSVEP_PIC_DATA{ori,preori},currentdata-trialbaseline-picbaseline);
                end
            end
            data.(label{i})(cond).Data = [];
        end
    end
    [~,file_name,~] = fileparts(file_idx{i});

    save(sprintf('SSVEP1000hz_PIC_DATA_1A_%s_%s_%s.mat',file_name(1:2),MUA_LFP,label{i}),'SSVEP_PIC_DATA','-v7.3');
    fprintf('complete %s %s',MUA_LFP,label{i});
end


end
%% 绘制信号分布
% EVENT
% chanmap = load('D:\Ensemble coding\DGdata\tooldata\DGChannelMap.mat'); % QQchannelMap
% load('D:\\Ensemble Coding\\DGdata\tooldata\\DGchannelselect.mat', 'selected_coil_final');
% load('plotkey.mat');
% label = {'MGnv','MGv','SG'};
% for l = 1:length(label)
%     filename = sprintf('DG_EVENT_Days25_29_MUA2_%s.mat',label{l});
%     data = load(fullfile('D:\Ensemble coding\DGdata\','Processed_Event',filename));
%     % 创建一个新的图形窗口
% 
% 
%     % 第一遍循环，计算所有数据的最小值和最大值
%     linewidthvalue = [1.1:0.1:2,1.9:(-0.1):1.2];
% 
%     rawdata = data.(label{l});
%     figure;
%     for i = 1:96
%         % n = find(chanmap.QQchannelMap' == i);
%         subplot(10, 10, i);
%         for ori = 1:18
%             % 假设 SG(ori).Data 已经被定义并包含数据
% 
%             hold on
% 
%             menadata = squmean(rawdata(ori).Data(:,i,35:45),3);
%             [value,idx] = sort(menadata,'descend');
%             pd = fitdist(value,'Normal');
%             x_values = linspace(min(value), max(value), 100);
%             y_values = pdf(pd,x_values);
%             plot(x_values,y_values,'-','LineWidth',linewidthvalue(ori),'Color',Colorvalue_BR(ori,:));
%             xlim([-0.5 0.5]);
%             % histogram(value,-0.2:0.02:0.3)
%             subtitle(i)
%         end
%         hold off
%         % sgtitle(fprintf('Ori%d',ori));
%         % saveas(gcf, sprintf('Ori_%d.png', ori)); % 保存为 PNG 格式
%     end
%     sgtitle(sprintf('%s',label{l}));
% end
% SSVEP
% % 加载数据
% chanmap = load('D:\Ensemble coding\QQdata\tooldata\QQChannelMap.mat'); % QQchannelMap
% load('D:\\Ensemble Coding\\DGdata\tooldata\\DGchannelselect.mat', 'selected_coil_final');
% load('plotkey.mat');
% % 
% data = [];
% minnum = 484;
% for i = 1:108
%     num = size(SSVEP_PIC_DATA{i},1);
%     if num<=minnum
%         minnum = num;
%     end
% end
% for i = 1:108
%     SSVEP_PIC_DATA{i} = SSVEP_PIC_DATA{i}(1:minnum,:,:);
% end
% n = 1:18;
% for i = 1:length(n)
%     dd = SSVEP_PIC_DATA(:,n(i));
%     dd = cat(1,dd{:});
%     num = size(dd,1);
% 
%     rawdata(i,:,:,:) = dd(:,1:96,:);
% end
% clear SSVEP_PIC_DATA
% %
% 
% 
% 
% % label = {'MGnv','MGv','SG'};
% % filename = sprintf('QQ_EVENT_Days2_27_MUA2_%s.mat',label{l});
% data = load(fullfile('D:\Ensemble coding\QQdata\','Processed_Event',filename));
% 创建一个新的图形窗口


% 第一遍循环，计算所有数据的最小值和最大值
% linewidthvalue = [1.1:0.1:2,1.9:(-0.1):1.2];
% 
% % rawdata = data.(label{l});
% figure;
% for i = 1:96
%     n = find(chanmap.QQchannelMap' == i);
%     disp(i)
%     subplot(10, 10, n);
%     for ori = 1:18
%         % 假设 SG(ori).Data 已经被定义并包含数据
% 
%         hold on
% 
%         % meandata = squmean(rawdata(ori).Data(:,i,35:45),3);
%         meandata = squmean(rawdata(ori,:,i,35:45),4)';
%         [value,idx] = sort(meandata,'descend');
%         pd = fitdist(value,'Normal');
%         x_values = linspace(min(value), max(value), 100);
%         y_values = pdf(pd,x_values);
%         plot(x_values,y_values,'-','LineWidth',linewidthvalue(ori),'Color',Colorvalue_BR(ori,:));
%         xlim([-0.5 0.5]);
%         % histogram(value,20)
%         subtitle(i)
%     end
%     hold off
%     % sgtitle(fprintf('Ori%d',ori));
%     % saveas(gcf, sprintf('Ori_%d.png', ori)); % 保存为 PNG 格式
% end
%% SSVEP和EVETN图像合并
% 图像位置会错乱
% clear;
% chanmap = load('D:\Ensemble coding\DGdata\tooldata\DGChannelMap.mat');
% load('D:\\Ensemble Coding\\DGdata\tooldata\\DGchannelselect.mat', 'selected_coil_final');
% load('plotkey.mat');
% fig1 = openfig('EVENT_SG_DG.fig', 'reuse'); % 替换为您的第一个文件名
% axes1 = findall(fig1, 'Type', 'Axes'); % 获取所有子图的句柄
% 
% % 加载第二个 .fig 文件
% fig2 = openfig('SSVEP_SG_DG.fig', 'reuse'); % 替换为您的第二个文件名
% axes2 = findall(fig2, 'Type', 'Axes'); % 获取所有子图的句柄
% 
% % 创建一个新的图形窗口
% figure;
% 
% % 遍历每个子图，绘制内容
% for i = 1:96
% 
%     % 创建一个新的子图
%     n = find(chanmap.DGchannelMap' == i);
% 
%     original_pos = get(axes1(i), 'Position');
%     original_units = get(axes1(i), 'Units');
% 
%     % 在新图中创建 Axes，并设置其位置
%     new_axes = axes('Position', original_pos, 'Units', original_units);
%     % 将新创建的 axes 设为当前绘图目标
%     % axes(new_axes); % 或者 copyobj 第二个参数直接用 new_axes
% 
%     % 从第一个 .fig 文件中绘制
%     copyobj(get(axes1(i), 'Children'), new_axes); % 将第一个图中的子图内容复制到当前子图
% 
%     hold on; % 允许叠加绘图
%     if i <= length(axes2) % 确保索引在范围内
%         lines = get(axes2(i), 'Children'); % 获取第二个图中当前子图的所有线条
%         for m = 1:18
%             % 将第一条线转为虚线
%             set(lines(m), 'LineStyle', '--'); % 这里将第一条线改成虚线
%             set(lines(m), 'Color', Colorvalue_GY(m,:));
%         end
%     end
%     % ... 后面的代码逻辑，同样将 copyobj 的目标改为 new_axes ...
%     copyobj(get(axes2(i), 'Children'), new_axes); % 将第二个图中的子图内容复制到当前子图
% 
%     % 可选: 添加子图标题 (设到 new_axes 上)
%     % title(new_axes, sprintf('Channel %d', i));
%     % if ismember(i,selected_coil_final)
%     %     title(new_axes, sprintf('Channel %d', i),'Color',[1,0,0]);
%     % end
%     xlim(new_axes, [-0.5,0.5])
%     hold off; % 结束叠加
% 
% % 注意：如果使用这种方法，sgtitle 可能无法正常工作，因为 sgtitle 是为 subplot 网格设计的。
% % 您可能需要手动添加一个文本框作为总标题。
% end
% 
% % 设置全局标题或其他图形属性（可选）
% sgtitle('SG'); % 设置整体标题

%% 热图&tuning
% macaque = 'QQ';
% data = [];
% minnum = 2000;
% for i = 1:108
%     num = size(SSVEP_PIC_DATA{i},1);
%     if num<=minnum
%         minnum = num;
%     end
% end
% for i = 1:108
%     SSVEP_PIC_DATA{i} = SSVEP_PIC_DATA{i}(1:minnum,:,:);
% end
% n = 1:18;
% for i = 1:length(n)
%     dd1 = SSVEP_PIC_DATA(:,n(i));
%     dd = cat(1,dd1{:});
%     % num = size(dd,1);
% 
%     rawdata(i,:,:,:) = dd(:,1:96,:);
% end
% dayrawdata = [];
% for day = 1:250
%     idx = ((day-1)*20+1):day*20;
%     dayrawdata(:,day,:,:) = mean(rawdata(:,idx,:,:),2);
% end
% % 
% % for i = 1:108
% %     for day = 1:100
% %         idx = ((day-1)*20+1):day*20;
% %         mm(day,:,:) = mean(SSVEP_PIC_DATA{i}(idx,:,:),1);
% %     end
% %     SSVEP_PIC_DATA{i} = mm;
% % end
% chanmap = load(sprintf('D:\\Ensemble coding\\%sdata\\tooldata\\%sChannelMap.mat',macaque,macaque));%QQchannelMap
% load(sprintf('D:\\Ensemble Coding\\%sdata\\tooldata\\%schannelselect.mat',macaque,macaque),'selected_coil_final')
% 
% figure; % 创建一个新的图形窗口
% 
% for i = 1:96
%     data = squmean(dayrawdata(:,:,i,5:15),4);
% 
%     % 确保数据不是空的或无效的，否则后续 plot 会出错
%     if ~isempty(data) && ismatrix(data) && size(data,1) > 1 && size(data,2) > 1
% 
%         n = find(chanmap.QQchannelMap'==i);
% 
%         if ~isempty(n) && n > 0 && n <= 100 % 确保 n 是有效的子图索引
%             subplot(10,10,n);
% 
%             % 使用左 Y 轴绘制热图
%             yyaxis left;
%             imagesc(data'); % 热图，X轴是试验，Y轴是时间点
%             % 可选：设置 Y 轴标签
%             % ylabel('Time Point Index');
% 
%             % 使用右 Y 轴绘制线条
%             yyaxis right;
%             plot(mean(data,2)','LineWidth',2); % 线条，X轴是试验，Y轴是平均信号值
%             % 可选：设置 Y 轴标签
%             % ylabel('Mean Signal Value');
% 
%             % imagesc 默认会hold on，yyaxis 切换轴也会保留当前axes
%             % 所以这里不需要额外的 hold on/off
%             % hold on; % 在 yyaxis right 之后加 hold on 也是可以的
% 
%             % 可选：设置 Y 轴颜色以区分
%             ax = gca;
%             ax.YAxis(1).Color = 'k'; % 左Y轴（热图）的颜色
%             ax.YAxis(2).Color = get(ax.Children(1),'Color'); % 右Y轴（线条）的颜色，匹配线条颜色
% 
%             % 设置标题
%             if ismember(i,selected_coil_final)
%                 subtitle(num2str(i),'Color','r','FontWeight', 'bold');
%             else
%                 subtitle(num2str(i));
%             end
% 
%             box off;
% 
%         else
%              fprintf('Warning: Invalid subplot index for channel %d (n=%d).\n', i, n);
%              % Optionally, plot an empty subplot or error message
%              % subplot(10,10,i); text(0.5,0.5,'Invalid Subplot Index','HorizontalAlignment','center');
%         end
%     else
%          fprintf('Warning: Data for channel %d is invalid or empty.\n', i);
%          % Optionally, plot an empty subplot or error message
%          % subplot(10,10,i); text(0.5,0.5,'No Valid Data','HorizontalAlignment','center');
%     end
% end

%%
% filename = 'comb_trial_SG1.npy'; % 你的 .npy 文件路径
% 
% % 确保 MATLAB 能够访问 Python 和 numpy
% % 第一次使用可能需要一些时间来启动 Python 解释器
% try
%     py.importlib.import_module('numpy');
%     fprintf('Python and numpy imported successfully.\n');
% catch ME
%     error('Could not import numpy in Python. Please check your Python environment and make sure numpy is installed. Error: %s', ME.message);
% end
% 
% fprintf('Attempting to load %s using numpy...\n', filename);
% 
% try
%     % 使用 Python 的 numpy.load 函数加载 .npy 文件
%     % 注意：默认情况下 numpy.load 会将整个数组加载到内存中
%     numpy_array = py.numpy.load(filename);
% 
%     fprintf('Successfully loaded data into Python numpy array. Converting to MATLAB...\n');
% 
%     % 将 Python 的 numpy 数组转换为 MATLAB 数组
%     % MATLAB 的 py2mat 函数会进行类型转换
%     matlab_data = single(numpy_array);
% 
%     fprintf('Successfully converted to MATLAB array. Data size: [%s]\n', num2str(size(matlab_data)));
% 
%     % 现在你可以在 MATLAB 中使用 matlab_data 变量了
% 
% catch ME
%     error('Error loading or converting .npy file: %s', ME.message);
% end
% 
% % 清理 Python 变量 (可选，由垃圾回收机制处理)
% clear numpy_array;

%%
% data1 = squmean(data2,2);

% chanmap = load('D:\Ensemble coding\QQdata\tooldata\QQChannelMap.mat');%QQchannelMap
% load('D:\\Ensemble Coding\\QQdata\tooldata\\QQchannelselect.mat','selected_coil_final')
% for i = 1:96
%     n = find(chanmap.QQchannelMap'==i);
%     subplot(10,10,n);
%     hold on
%     for ori = 1:18
%         if ismember(i,selected_coil_final)
%             plot(squeeze(data1(ori,i,:)),'Color','r');
%             subtitle(i,'Color','r','FontWeight', 'bold');
%         else
%             plot(squeeze(data1(ori,i,:)),'b');
%             subtitle(i);
%         end
%     end
%     hold off
%     box off
% end

% for ori = 1:18
%     rawdata(ori,:,:,:) = SSVEP_PIC_DATA{1,ori}(1:900,:,:);
% end
% figure;
% for i = 1:96
% data = squmean(rawdata(:,:,i,:),2);
% n = find(DGchannelMap'==i);
% subplot(10,10,n);
% yyaxis left;
% imagesc(data');
% yyaxis right;
% plot(mean(data(:,35:45),2),'LineWidth',2);
% end
% 
% for ori = 1:18
%     data1{ori} = cat(1,SSVEP_PIC_DATA{:,ori});
% end
% data1{1,15} = cat(1,data1{1,15},data1{1,15});
% for ori = 1:18
%     data(ori,:,:,:) = data1{1,ori}(1:900,:,:);
% end
% 
% data = [];
% for day = 1:18
% dd= [];
% data1 = [];
% for ori = 1:18
% dd = cat(1,dd,SG(ori).Data(((day-1)*9+1):day*9,:,:));
% end
% data(day,:,:,:) = dd;
% end
% dd = normalize(dd);
% for ori = 1:18
%     data1(ori,:,:,:) = dd(((ori-1)*28+1):ori*28,:,:);
% end
% data = cat(2,data,data1);
% end
% 
% for ori = 1:18
%     data =[];
%     subplot(4,5,ori)
%     for day = 1:18
%         data(day,:,:,:) = SG(ori).Data(((day-1)*9+1):day*9,:,:);
%     end
%     [chance_level, accuracy, p_value] = SVM_Decoding_LR(data,1,'1','1');
%     plot(accuracy);
% end
% 
% data = [];
% for day = 1:15
%     dd = [];
%     for ori = 1:18
%         dd = cat(1,dd,squeeze(comb_trial_signals(ori,((day-1)*350+1):day*350,:,:)));
%     end
%     data(day,:,:,:) = dd;
% end
