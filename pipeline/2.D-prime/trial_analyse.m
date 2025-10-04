% function SSVEP_SSG_prefitanalyse()
% trial 水平的拟合
date = [34,40];
%% centerSSGnv
load(sprintf('D:\\Ensemble coding\\QQdata\\Processed_Event\\QQ_SSVEPB_Days%d_%d_LFP_SSGnv.mat',date(1),date(2)));
condition = -1:2:17;
for i = 1:10; centerSSGnv(i).Block = 'centerSSGnv'; centerSSGnv(i).Target_Ori = condition(i); centerSSGnv(i).Location = 13;end
for i = 1:10
    centerSSGnv(i).Data = SSGnv(120+i).Data;
    centerSSGnv(i).Pattern = SSGnv(120+i).Pattern;
    centerSSGnv(i).Pic_Ori = SSGnv(120+i).Pic_Ori;
end
save(sprintf('D:\\Ensemble coding\\QQdata\\Processed_Event\\QQ_SSVEPB_Days%d_%d_LFP_centerSSGnv.mat',date(1),date(2)),'centerSSGnv');
%% fitMGv
%   method           - (可选) 指定计算方法的字符串:
%                      'linear'     (默认) - 对12个位置进行完整线性回归。
%                      'sum'        - 直接将12个位置的信号相加。
%                      'scaled_sum' - 对12个位置信号的和进行增益和偏移拟合。
clearvars -except date
date = [34,40];
load(sprintf('D:\\Ensemble coding\\QQdata\\Processed_Event\\QQ_SSVEPB_Days%d_%d_LFP_SSGv.mat',date(1),date(2)));
load(sprintf('D:\\Ensemble coding\\QQdata\\Processed_Event\\QQ_SSVEPB_Days%d_%d_LFP_MGv.mat',date(1),date(2)));
[fitMGv,a] = generate_fit_data(SSGv, MGv, 'fitMGv','linear');
[normfitMGv,b] = generate_fit_data(SSGv, MGv, 'normfitMGv','scaled_sum');
save(sprintf('D:\\Ensemble coding\\QQdata\\Processed_Event\\QQ_SSVEPB_Days%d_%d_LFP_fitMGv.mat',date(1),date(2)),'fitMGv')
save(sprintf('D:\\Ensemble coding\\QQdata\\Processed_Event\\QQ_SSVEPB_Days%d_%d_LFP_normfitMGv.mat',date(1),date(2)),'normfitMGv')

%% fitMGnv
%   method           - (可选) 指定计算方法的字符串:
%                      'linear'     (默认) - 对12个位置进行完整线性回归。
%                      'sum'        - 直接将12个位置的信号相加。
%                      'scaled_sum' - 对12个位置信号的和进行增益和偏移拟合。
clearvars -except date
date = [34,40];
load(sprintf('D:\\Ensemble coding\\QQdata\\Processed_Event\\QQ_SSVEPB_Days%d_%d_LFP_SSGnv.mat',date(1),date(2)));
load(sprintf('D:\\Ensemble coding\\QQdata\\Processed_Event\\QQ_SSVEPB_Days%d_%d_LFP_MGnv.mat',date(1),date(2)));
[fitMGnv,a] = generate_fit_data(SSGnv, MGnv, 'fitMGnv','linear');
[normfitMGnv,b] = generate_fit_data(SSGnv, MGnv, 'normfitMGnv','scaled_sum');
save(sprintf('D:\\Ensemble coding\\QQdata\\Processed_Event\\QQ_SSVEPB_Days%d_%d_LFP_fitMGnv.mat',date(1),date(2)),'fitMGnv')
save(sprintf('D:\\Ensemble coding\\QQdata\\Processed_Event\\QQ_SSVEPB_Days%d_%d_LFP_normfitMGnv.mat',date(1),date(2)),'normfitMGnv')
%%
figure('position',[100,100,400,700]);
 selchannel =  [75,79,43,78,81,41,45,82,84,38,47,49,85,42,44,51,88,17,50,46,89,8,54,52,58,91,92,23,25,21,62,60,14,16,20,27,29,31,63,56,22,24,26,28];
subplot(2,1,1)
hold on
mm = squmean(cat(2,b.R2_adj),2);
xline(mean(mm(selchannel)),'--','Color','blue')
histogram(mm(selchannel),0:0.1:1)
text(mean(mm(selchannel)),40,sprintf('linear fit mean = %.2f',mean(mm(selchannel))));
mm = squmean(cat(2,a.R2_adj),2);
xline(mean(mm(selchannel)),'--','Color','red')
histogram(mm(selchannel),0:0.1:1,'FaceColor',[175,0,0]/256)
text(mean(mm(selchannel)),30,sprintf('norm fit mean = %.2f',mean(mm(selchannel))));
title('MGnv R2adj')
ylim([0,50])

subplot(2,1,2)
hold on
nn = squmean(cat(2,b.RMSE),2);
xline(mean(nn(selchannel)),'--','Color','blue')
histogram(nn(selchannel),100:20:300)
text(mean(nn(selchannel)),40,sprintf('linear fit mean = %.2f',mean(nn(selchannel))));

nn = squmean(cat(2,a.RMSE),2);
xline(mean(nn(selchannel)),'--','Color','red')
histogram(nn(selchannel),100:20:300,'FaceColor',[175,0,0]/256)
text(mean(nn(selchannel)),30,sprintf('norm fit mean = %.2f',mean(nn(selchannel))));
title('MGnv RMSE')
ylim([0,50])