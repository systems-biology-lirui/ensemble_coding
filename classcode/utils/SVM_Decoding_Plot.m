function SVM_Decoding_Plot(Accuracy_file,Colors,Chance_Level)
n_conditions = length(Accuracy_file);
figure;
% 绘制Chance-level
% n_time = 100;
% plot(1:n_time,Chance_Level*ones(1,n_time),'--','LineWidth',1.5,'Color',[0.7,0.7,0.7]);
hold on 
for i = 1:n_conditions

    % 读取数据
    load(Accuracy_file{i},'acc_real_all_folds','perm_acc_all_shuffles');
    accuracy = cell2mat(acc_real_all_folds');
    Chance_Level = cell2mat(perm_acc_all_shuffles)';
    
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
        [0.5,0.5,0.5], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    
    for t = 1:n_timepoints
        p_value(t) = sum(Chance_Level(t,:)>= accuracy_mean(t)) / n_shuffle;
    end
    % 绘制显著点
    m = find(p_value<=0.05);
    y_marker_pos = 1/18-0.01*i;
    stem(m, repmat(y_marker_pos, size(m)), '.', 'MarkerFaceColor', 'k', ...
        'MarkerSize', 5, 'LineWidth', 1, 'Clipping', 'off','LineStyle','none','MarkerEdgeColor',Colors(i,:));
    
end
title('Decoding')

ax = gca;
ax.LineWidth = 2;
ax.FontSize = 12;
ax.FontWeight = 'bold';
ax.XAxis.FontSize = 12;
ax.YAxis.FontSize = 12;
ax.XAxis.FontWeight = 'bold';

xticks(0:10:100);
xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160'});