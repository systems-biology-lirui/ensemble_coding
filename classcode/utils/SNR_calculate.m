function [SNR,sortidx] = SNR_calculate(data,num)
% SNR_calculate用于计算信噪比
% 公式为(max(signal)-mean(base))/std(base)
% input:
%   data:channel*time
%   num: channels you need
% output:
SNR1 = zeros(size(data,1));
for channel = 1:size(data,1)
    signal = data(channel,21:end);
    noise = data(channel,1:20);
    SNR1(channel) = (max(signal)-mean(noise))/std(noise);
end
[SNR,sortidx] = sort(SNR1,'descend');
SNR = SNR(1:num);
sortidx = sortidx(1:num);


