filename = 'z144s2_EC_20240724.GSQ';

fid = fopen(filename, 'r');
C = textscan(fid, '%s', 'Delimiter', '\n');
fclose(fid);
numeric_lines = [];
for i = 1:length(C{1})
    line_content = C{1}{i};
    if ~isempty(str2num(line_content))  % 检查行是否包含数字
        numeric_lines = [numeric_lines, i];
    end
end
a = zeros(1,6480);
for line_idx = 1:size(numeric_lines,2)-1
    % 获取当前行的数据
    numeric_line = C{1}{numeric_lines(line_idx)};
    values = strsplit(numeric_line, ',');

    % 修改第 10 列的值（假设从1开始计数）
    aa = strsplit(values{38}, ';');  
    a (line_idx)=str2double(aa{1});% 将第 10 列的值修改为 100
end

i_orimean = zeros(1620*1);
li_phasemean = zeros(1620*1);
for m = 1: 1620
    li_idx = a(4*(m-1)+1:4*m);
    li = data(:,:,li_idx);
    nonMultiplesOfFour = find(~mod(1:4, 4) == 0);
    li_nontar = li(:, :, nonMultiplesOfFour);
    li_mean = mean(mean(li_nontar,2),3);
    li_orimean(m,1) = li_mean(1,1);
    li_phasemean(m,1) =li_mean(2,1);
end
plot(li_orimean)




