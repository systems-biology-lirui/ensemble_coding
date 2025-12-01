%% Master_Run_All.m
% 主程序：依次运行三个分析模块
% 确保另外三个文件已修改为 function 形式，且在 MATLAB 路径中。

clear; clc;
diary('Analysis_Log.txt'); % (可选) 将命令行输出保存到日志文件
total_start_time = tic;

fprintf('##########################################################\n');
fprintf('       开始运行完整分析流程 - %s\n', datestr(now));
fprintf('##########################################################\n\n');

%% 任务 1: SSVEP 拟合与解码 (3种策略)
try
    fprintf('=== [Task 1/3] 开始运行: SSVEP 拟合策略 ... ===\n');
    t1 = tic;
    
    % 调用函数
    ssvepb_fitdecoding_pipeline_new(); 
    
    fprintf('>>> Task 1 完成！耗时: %.2f 分钟\n\n', toc(t1)/60);
catch ME
    fprintf(2, '!!! Task 1 出错: %s\n', ME.message);
    fprintf(2, '错误发生于: %s (Line %d)\n\n', ME.stack(1).name, ME.stack(1).line);
    % 根据需要决定是否 return 终止，或者继续运行 Task 2
end

%% 任务 2: EVENT 拟合与解码 (3种策略)
try
    fprintf('=== [Task 2/3] 开始运行: EVENT 拟合策略 ... ===\n');
    t2 = tic;
    
    % 调用函数
    event_fitdecoding_pipeline_new();
    
    fprintf('>>> Task 2 完成！耗时: %.2f 分钟\n\n', toc(t2)/60);
catch ME
    fprintf(2, '!!! Task 2 出错: %s\n', ME.message);
    fprintf(2, '错误发生于: %s (Line %d)\n\n', ME.stack(1).name, ME.stack(1).line);
end

%% 任务 3: SSVEP_A 纯解码验证
try
    fprintf('=== [Task 3/3] 开始运行: SSVEP_A 纯解码分析 ... ===\n');
    t3 = tic;
    
    % 调用函数
    SSVEP_A_decoding_MGv_pipeline_new();
    
    fprintf('>>> Task 3 完成！耗时: %.2f 分钟\n\n', toc(t3)/60);
catch ME
    fprintf(2, '!!! Task 3 出错: %s\n', ME.message);
    fprintf(2, '错误发生于: %s (Line %d)\n\n', ME.stack(1).name, ME.stack(1).line);
end

%% 结束
total_time = toc(total_start_time);
fprintf('##########################################################\n');
fprintf('       所有任务处理完毕 - %s\n', datestr(now));
fprintf('       总耗时: %.2f 小时 (%.2f 分钟)\n', total_time/3600, total_time/60);
fprintf('##########################################################\n');
diary off; % 关闭日志
load handle; % (可选) 播放声音提示结束
sound(y, Fs);