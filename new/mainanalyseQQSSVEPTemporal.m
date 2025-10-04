%% 提取Event SG中的最后一张，并按照平均朝向进行解码
% 标注trial中的图片，平均朝向，最后一张图片的朝向
% dbstop if error
selected_blocks = {'MGv', 'MGnv', 'SG', 'SSGnv', 'blank'};
mean_strategy = 1; % 1代表序列更新，2代表直接平均。
Days = [1,13];
MUA_LFP =2;
picloc = 8;
QQ_SSVEP_Temporal_Process(selected_blocks,mean_strategy,Days,MUA_LFP,picloc)




%% Temporal Decoding
clear;
load('SSVEP_Temporal_Days1_13_MUA2_SG_pic8.mat')
Mean_left = cat(1,SG_T(3:8).Data);
Mean_right = cat(1,SG_T(10:15).Data);
minnum = min(size(Mean_right,1),size(Mean_left,1));
coilselect = [0, 5, 9, 11, 15, 17, 18, 19, ...
    22, 23, 24, 26, 33, 34, 38, 40, 41, 42, ...
    48, 51, 52, 53, 66, 72, 73, 78, 79, 82, ...
    84, 87, 89]+1;
data_reshaped(1,:,:,:) = Mean_left(1:minnum,coilselect,:);
data_reshaped(2,:,:,:) = Mean_right(1:minnum,coilselect,:);
n_shuffles = 5;
[accuracy, p_value] = SVM_Decoding_LR(data_reshaped,n_shuffles);




%% ------------------------------------
function QQ_SSVEP_Temporal_Process(selected_blocks,mean_strategy,Days,MUA_LFP,picloc)
    
    load('D:\SSVEPA_Days1_13_MUA2_SG.mat')
    if ismember('SG', selected_blocks)
        % SG = cell(2,18);
        SG_T(1:18) = struct('Block', 'SG', 'Location', [], 'Pic_Ori', [], 'Pattern', [], 'Data',[], 'Trial', [] ,'Cluster', [],'Condition',[]);
        for i = 1:18
            SG_T(i).Pic_Ori = i;
        end
    end
    for i = 1:10
        for trial = 1:size(SG(i).Data,1)
            for pic = 15:10:65
                window = 100+(pic-1)*20+(-19:80);
                orisequence = SG(i).Pic_Ori(trial,(pic-7):pic);
    
                if mean_strategy ==1
                    meanori = cumulative_average(orisequence);
                else
                    meanori = mean(orisequence);
                end
                meanori = floor(meanori);
                currentData = single(SG(i).Data(trial,1:96,window));
                SG_T(meanori).Data = cat(1,SG_T(meanori).Data,currentData);
                SG_T(meanori).Trial = cat(1,SG_T(meanori).Trial,orisequence);
                SG_T(meanori).Condition = cat(1,SG_T(meanori).Condition,i);
            end
        end
    end
    MUAcondition = {'MUA1','MUA2','LFP'};
    save(sprintf('SSVEP_Temporal_Days%d_%d_%s_%s_pic%d.mat', Days(1), Days(end),MUAcondition{MUA_LFP}, 'SG', picloc), 'SG_T','-v7.3');
    % MUAcondition = {'MUA1','MUA2','LFP'};
    % for i = 1:length(selected_blocks)
    %     block = selected_blocks{i};
    %     if exist(block, 'var') && ~isempty(eval(block))
    %         save(sprintf('SSVEP_Temporal_Days%d_%d_%s_%s_pic%d.mat', Days(1), Days(end),MUAcondition{MUA_LFP}, block, picloc), block,'-v7.3');
    %     end
    % end
end

function meanori = cumulative_average(orisequence)
meanori = orisequence(1);
for i = 1:length(orisequence)
    meanori = (meanori+orisequence(i))/2;
end
end