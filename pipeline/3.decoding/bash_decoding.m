% 多条件解码
selected_coil_final = [7,9,13,17,18,19,21,22,23,24,25,27,35,38,39,41,51,61,73,74,80,82,84,87,89]+1;
label = {'MGv','MGnv','SG'};
for i = 1:length(label)
    file_idx{i} = sprintf('QQ_EVENT_Days2_27_LFP_%s.mat',label{i});
    file_idx{i+3} = sprintf('QQ_EVENT_Days2_27_MUA2_%s.mat',label{i});
end
decoding_accuracy = {};
decoding_chance = {};
decoding_p_value = {};
for i = 1:length(file_idx)
    data = load(file_idx{i});
    decoding_data = zeros(18,162,96,100);
    for ori = 1:18
        decoding_data(ori,:,:,:) = data.(label{mod(i,3)})(ori).Data;
    end
    [accuracy, p_value,chance_level] = SVM_Decoding_LR(single(decoding_data(:,:,selected_coil_final,:)),true,50);
    decoding_accuracy{i} = accuracy;
    decoding_chance{i} = chance_level;
    decoding_p_value{i} = p_value;
    fprintf('Decoding complete %s',label{mod(i,3)});
end