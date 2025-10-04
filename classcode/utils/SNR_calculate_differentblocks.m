function [selected_coil_final,selected_coil] = SNR_calculate_differentblocks(data_files,Labels,num)
candidatenum = num+5;
selected_coil = [];
for i = 1:length(data_files)
    data=load(data_files{i});
    SGSNR = zeros(18,candidatenum);
    for ori = 1:18
        % 得到每一种朝向下良好snr通道
        [~,sortidx] = SNR_calculate(squmean(data.(Labels{i})(ori).Data,1),candidatenum);
        SGSNR(ori,:) = sortidx;
    end

    % 汇总所有朝向，按照出现数量来选
    [uniqueValues, ~, idx] = unique(SGSNR); 
    counts = accumarray(idx, 1);
    [~,idx1] = sort(counts,'descend');
    selected_coil(i,:) = uniqueValues(idx1(1:candidatenum));

end
[uniqueValues, ~, idx] = unique(selected_coil); 
counts = accumarray(idx, 1);
[~,idx1] = sort(counts,'descend');
selected_coil_final = uniqueValues(idx1(1:num));