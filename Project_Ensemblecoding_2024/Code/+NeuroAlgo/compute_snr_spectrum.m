function snr_data = compute_snr_spectrum(psd_data, freq_vec)
    % psd_data: [..., nFreq]
    % freq_vec: [nFreq]
    
    snr_data = zeros(size(psd_data), 'like', psd_data);
    nFreq = length(freq_vec);
    res = freq_vec(2) - freq_vec(1); % 频率分辨率
    
    % 转换范围为索引数
    idx_range_outer = round(2.0 / res);   % 2Hz
    idx_range_inner = round(0.25 / res);  % 0.25Hz
    
    for i = 1:nFreq
        % 确定邻域索引
        idx_start = max(1, i - idx_range_outer);
        idx_end   = min(nFreq, i + idx_range_outer);
        
        indices = idx_start:idx_end;
        
        % 排除中间保护区 (Inner Exclusion)
        idx_exclude_start = max(1, i - idx_range_inner);
        idx_exclude_end   = min(nFreq, i + idx_range_inner);
        
        mask = indices < idx_exclude_start | indices > idx_exclude_end;
        neighbor_indices = indices(mask);
        
        if isempty(neighbor_indices)
            snr_data(:, :, i) = 1; % 无法计算，设为1 (0dB)
        else
            % 取邻域噪声平均
            noise_floor = mean(psd_data(:, :, neighbor_indices), 3);
            snr_data(:, :, i) = psd_data(:, :, i) ./ noise_floor;
        end
    end
end