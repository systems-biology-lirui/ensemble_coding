%%
labels = {'SG','MGnv','MGv'};
for session = 1:13
    idx{session} = ((session-1)*10+1):session*10;
end
idx{14} = 131:139;
for i = 1:length(labels)
    disp(i);
    data = load(sprintf('F:/Ensemble coding/QQdata/Processed_Event/QQ_SSVEP_Days1_27_MUA2_%s.mat',labels{i}));
    for cond = 1:10
        for session = 1:14
            data.(labels{i})(cond).meanData(session,:,:) = mean(data.(labels{i})(cond).Data(idx{session},:,:),1);
        end
    end
    
    save(sprintf('F:/Ensemble coding/QQdata/Processed_Event/QQ_SSVEP_Days1_27_MUAmean_%s.mat',labels{i}),'-struct',"data",labels{i});
end
%%
labels = {'SG','MGnv','MGv'};
for i = 1:length(labels)
    file_idx{i} = sprintf('F:/Ensemble coding/QQdata/Processed_Event/QQ_SSVEP_Days1_27_MUAmean_%s.mat',labels{i}');
end
Colors = [0.5,0.5,0.5;0.5,0.5,0.5;0.5,0.5,0.5];
selected_coil_final = 1:96;
plot_content_savepath = 'qq_mua';
fftanalyse_plot(file_idx,labels,Colors,selected_coil_final,plot_content_savepath)
