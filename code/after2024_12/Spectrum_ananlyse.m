function [All_Spectrum, Fa_ROI] = Spectrum_ananlyse(All_data_pre, spectrum_factor)
% 计算功率谱

% 参数
timeLimits = [0 3.28]; % 秒
frequencyLimits = [0 250]; % Hz
sampleRate = 500; % Hz
startTime = 0; % 秒

[a_rows, a_cols] = size(All_data_pre);
All_Spectrum = cell(a_rows, a_cols);
Fa_ROI = []; % 初始化 Fa_ROI

% 计算时间索引
minIdx = ceil(max((timeLimits(1) - startTime) * sampleRate, 0)) + 1;
maxIdx = floor(min((timeLimits(2) - startTime) * sampleRate, 1640)) ; % 确保不越界

for location = 1:a_rows
    for ori = 1:a_cols
        b = size(All_data_pre{location, ori});
        All_Spectrum{location, ori} = zeros(b(2), 2533); % 预分配
        
        if spectrum_factor == 1
            for trial = 1:b(1)
                for coil = 1:b(2)
                    a_ROI = All_data_pre{location, ori}(trial, coil, 1:1640);
                    segment_ROI = squeeze(a_ROI(minIdx:maxIdx));
                    
                    % 计算频谱估计值
                    [Pa_ROI, Fa_ROI] = pspectrum(segment_ROI, sampleRate, ...
                        'FrequencyLimits', frequencyLimits,...
                        'FrequencyResolution',0.79);
                    All_Spectrum{location, ori}(coil, :) = All_Spectrum{location, ori}(coil, :) + Pa_ROI';                    
                end
            end
        else
            for coil = 1:b(2)
                a_ROI = mean(All_data_pre{location, ori}(:, coil, 1:1640), 1);
                segment_ROI = squeeze(a_ROI(minIdx:maxIdx));
                
                % 计算频谱估计值
                [Pa_ROI, Fa_ROI] = pspectrum(segment_ROI, sampleRate, ...
                    'FrequencyLimits', frequencyLimits,...
                    'FrequencyResolution', 0.79);
                All_Spectrum{location, ori}(coil, :) = Pa_ROI;
            end
        end
        fprintf('Processed location: %d;Processed orientation: %d\n', location, ori);
    end
end
