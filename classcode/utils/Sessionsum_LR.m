function Sessionsum_LR(A_B,Days1,Days2,MUA_LFP)
% Sessionsum_LR用于分批数据的合并
% 输入：
%   一系列文件参数
MUAcondition = {'MUA1','MUA2','LFP'};
selected_blocks= {'MGv', 'MGnv', 'SG', 'SSGnv'};
% selected_blocks= {'SSGnv'};
for i = 1:length(selected_blocks)
    block = selected_blocks{i};
    data1 = load(sprintf('SSVEP%s_Days%d_%d_%s_%s.mat', A_B, Days1(1), Days1(end),MUAcondition{MUA_LFP}, block), block);
    data2 = load(sprintf('SSVEP%s_Days%d_%d_%s_%s.mat', A_B, Days2(1), Days2(end),MUAcondition{MUA_LFP}, block), block);
    for n = 1:length(data1.(block))
        data1.(block)(n).Location = cat(1,data1.(block)(n).Location,data2.(block)(n).Location);
        data2.(block)(n).Location = [];
        data1.(block)(n).Pic_Ori = cat(1,data1.(block)(n).Pic_Ori,data2.(block)(n).Pic_Ori);
        data2.(block)(n).Pic_Ori = [];
        data1.(block)(n).Pattern = cat(1,data1.(block)(n).Pattern,data2.(block)(n).Pattern);
        data2.(block)(n).Pattern = [];
        data1.(block)(n).Data = cat(1,data1.(block)(n).Data,data2.(block)(n).Data);
        data2.(block)(n).Data = [];
    end
    save(sprintf('SSVEP%s_Days%d_%d_%s_%s.mat', A_B, Days1(1), Days2(end),MUAcondition{MUA_LFP}, block),  '-struct', 'data1', sprintf('%s',block),'-v7.3');
    clear data1 data2
    fprintf('complete %s\n',block);
end
