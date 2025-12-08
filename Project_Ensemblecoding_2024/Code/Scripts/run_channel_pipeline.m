clear;
clc;
tic;
macaques = {'DG','QQ_old','QQ_new'};
load('Yge_channelSNR.mat','sel_channel');

% 解码器参数
options.do_permutation = false;
options.n_shuffles     = 5;
options.n_repetitions  = 1; % 重复次数，用于计算误差棒或平均线
options.k_fold         = 5;
options.time_smooth_win = 2;
options.mode           = 'cross_condition';
channel_num_idx = [1,2,3,4,5:5:80];
acc = struct();
target_ori = 1:18;
for m = 2:3
    macaque = macaques{m};
    data = load(sprintf('D:/ensemble_coding/Project_Ensemblecoding_2024/Results/Figures/SSVEP_B2EVENT/%s_SSVEP_FitResults_Strategy1.mat',macaque));
    Mat_MGv_B_SSVEP = matrix5to4(data.Mat_MGv_B);
    Mat_MGv_A_SSVEP = matrix5to4(data.Mat_MGv_A_SSVEP);
    Res_Mat_SSVEP = matrix5to4(data.Res_Mat_SSVEP);
    Fit_Mat = matrix5to4(data.Fit_Mat);
    clear data
    [a,b] = sort(sel_channel.(macaque),'descend');
    for c = 1:length(channel_num_idx)
        fprintf('----------c = %d----------',c)
        num = channel_num_idx(c);
        [~,b] = sort(sel_channel.(macaque),'descend');
        channels = b(1:num);
        decodingresult = Master_Decoder(Mat_MGv_B_SSVEP(target_ori,:,channels,:),Mat_MGv_A_SSVEP(target_ori,:,channels,:),options);
        acc.real{m,c} = decodingresult.acc_real_mean;
        decodingresult = Master_Decoder(Fit_Mat(target_ori,:,channels,:),Mat_MGv_A_SSVEP(target_ori,:,channels,:),options);
        acc.fit{m,c} = decodingresult.acc_real_mean;
        decodingresult = Master_Decoder(Res_Mat_SSVEP(target_ori,:,channels,:),Mat_MGv_A_SSVEP(target_ori,:,channels,:),options);
        acc.res{m,c} = decodingresult.acc_real_mean;
    end
end
toc;
%%

for m = 1:3
    subplot(3,3,m)
    data1 = cat(1,acc.real{m,:});
    NeuroPlot.plot_orierp_diffcolor(gca,data1);
    xticks(1:10:121)
    xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160','180','200'})
    ylabel('ACC')
    xlabel('Time(ms)')
    set(gca, 'FontSize', 12, 'LineWidth', 1.2, 'TickDir', 'out');
    box(gca, 'off');
    subtitle(sprintf('%s\nReal',macaques{m}))
    grid off
    xline([45,60],'--','LineWidth',1.5)

    subplot(3,3,m+3)
    data1 = cat(1,acc.fit{m,:});
    NeuroPlot.plot_orierp_diffcolor(gca,data1);
    xticks(1:10:121)
    xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160','180','200'})
    ylabel('ACC')
    xlabel('Time(ms)')
    set(gca, 'FontSize', 12, 'LineWidth', 1.2, 'TickDir', 'out');
    box(gca, 'off');
    grid off
    subtitle('Fit')
    xline([45,60],'--','LineWidth',1.5)


    subplot(3,3,m+6)
    data1 = cat(1,acc.res{m,:});
    NeuroPlot.plot_orierp_diffcolor(gca,data1);
    xticks(1:10:121)
    xticklabels({'-40','-20','0','20','40','60','80','100','120','140','160','180','200'})
    ylabel('ACC')
    xlabel('Time(ms)')
    set(gca, 'FontSize', 12, 'LineWidth', 1.2, 'TickDir', 'out');
    box(gca, 'off');
    grid off
    subtitle('Res')
    xline([45,60],'--','LineWidth',1.5)

end
%%
figure;


function output = matrix5to4(input)
[a,b,c,d,e] = size(input);
output = reshape(input,[a,b*c,d,e]);
end