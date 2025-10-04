% 文件路径
clear
for gsq=1 %需要生成几个GSQ文件
    
 

    filename = 'z432_repeats11_1.GSQ';

    %load(['session',num2str(gsq),'_patch.mat'])
    random_sequence_all = m1;
    % 加载文本文件
    fid = fopen(filename, 'r');
    C = textscan(fid, '%s', 'Delimiter', '\n');
    fclose(fid);

    % 找到包含数字的行的位置
    % num_start_rows = 20;  % 计算要读取的行数
    % num_end_rows = 12819;  % 计算要读取的行数
    numeric_lines = [];
    for i = 1:length(D{1})
        line_content = D{1}{i};
        if ~isempty(str2num(line_content))  % 检查行是否包含数字
            numeric_lines = [numeric_lines, i];
        end
    end
% mm = [];
% for i = 1:10800
%     numeric_line = C{1}{numeric_lines(i)};
%     values = strsplit(numeric_line, ',');
%     mm(i) = str2double(strrep(values{38},';',','));
% end
% m1=mm;
% m1(2161:2160*2)=m1(2161:2160*2)+144;
% m1(2160*2+1:2160*3)=m1(2160*2+1:2160*3)+144*2;
% m1(2160*3+1:2160*4)=m1(2160*3+1:2160*4)+144*3;

    % 遍历需要修改的行范围
    for line_idx = 1:(size(numeric_lines,2)-1)
        % 获取当前行的数据
        numeric_line = C{1}{numeric_lines(line_idx)};
        values = strsplit(numeric_line, ',');

        % 修改第 10 列的值（假设从1开始计数）
        values{38} = [num2str(random_sequence_all(line_idx-6480)),';'];  % 将第 10 列的值修改为 100

        % 重新构造这一行
        new_numeric_line = strjoin(values, ',');

        % 更新到原始文本数据中
        C{1}{numeric_lines(line_idx)} = new_numeric_line;
    end

    % 遍历需要修改的行范围
    for line_idx = size(numeric_lines,2)
        % 获取当前行的数据
        numeric_line = C{1}{numeric_lines(line_idx)};
        values = strsplit(numeric_line, ',');
        cellArray = cellfun(@num2str, num2cell(random_sequence_all), 'UniformOutput', false);
        % 修改第 10 列的值（假设从1开始计数）
        values = cellArray;  % 将第 10 列的值修改为 100
        values{size(random_sequence_all,2)} = [cellArray{size(random_sequence_all,2)},';'];  % 将第 10 列的值修改为 100
        % 重新构造这一行
        new_numeric_line = strjoin(values, ',');

        % 更新到原始文本数据中
        C{1}{numeric_lines(line_idx)} = new_numeric_line;
    end

    % 保存修改后的数据到新文件
    %new_filename = ['z144EC',num2str(gsq),'_20240826.GSQ'];
    new_filename = 'z144first_20240826.GSQ';
    fid = fopen(new_filename, 'w');
    for i = 1:length(C{1})
        fprintf(fid, '%s\n', C{1}{i});
    end
    fclose(fid);

    disp(['Modified data saved to ', new_filename]);
end