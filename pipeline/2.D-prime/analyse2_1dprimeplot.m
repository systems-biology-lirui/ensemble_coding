%% --------------------绘制 D-prime的bar图-------------------------%
% readme(2025/7/10)
% 输入参数的调整与数据导入



% load('qq_exp1a_lfp_fftplot.mat')
% 参数设置
colors = [0.7 0.7 0.7; ...  
          0.7 0.2 0.2; ...  
          0.7 0.7 0.7];                     % bar color

lineColor = [0.8 0.8 0.8,0.2];      % line color

dotcolor = [0.7 0.7 0.7; ...  
          0.7 0.2 0.2; ...  
          0.7 0.7 0.7];                     % dot color

selectcoil = [1, 5, 7, 9, 13, 17, 19, 21, 22, 23, 25, 27, 30, 31, 38, 42, 55, 58, 60, 61, 63, 66, 73, 74, 80, 82, 83, 84, 89, 91]+1;                  % channel select

% additioncontent = 'all channels';
additioncontent = 'snr top 30';
% additioncontent = 'sg25 nosig';

for frequency = [1,3]
    a(1,:) = plot_content.SG.dprimeresult(frequency,:);
    a(2,:) = plot_content.MGnv.dprimeresult(frequency,:);
    a(3,:) = plot_content.MGv.dprimeresult(frequency,:);
    [fig_handle, axes_handle, anova_results, comparison_results, p_val] = ...
        advancedBarPlot(a(:,selectcoil)', ...
        'yLabel', 'D-prime', ...
        'titleText', sprintf('6.25hz %s',additioncontent), ...
        'alpha', 0.05,'barColor',colors,'lineColor',lineColor,'groupNames',{'SG','MGnv','MGv'},'dotColor',dotcolor);
end


%% ------------------- 为了满足某种条件的通道随机选取-----------------%
found = false;
i = 0;
common_values = [];
% 最大的随机重复次数
maxrepeatnum = 100000;
% 需要最大重合的通道序列
sel1 = [1, 5, 7, 9, 13, 17, 19, 21, 22, 23, 25, 27, 30, 31, 38, 42, 55, 58, 60, 61, 63, 66, 73, 74, 80, 82, 83, 84, 89, 91]+1;

% 随机选取
for m = 1:maxrepeatnum
    idx = randperm(96);
    % [h1,p] = ttest(a(1,idx(1:30)),0);
    [h2,p] = ttest(a(1,idx(1:30)),0);
    if  h2==0
        i = 1+1;
        found = true;
        common_values(i) = length(intersect(sel1, idx(1:30)));
        idx1(i,:) = idx(1:30); 
    end
end