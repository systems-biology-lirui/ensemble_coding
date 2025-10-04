% 清理工作区和命令行，关闭所有已打开的图形窗口
clearvars -except pic_idx_concatenated final_sessions
clc;
close all;

% 1. 参数设置 (User Configuration)
% -------------------------------------------------------------------------
% 请根据你的实际情况修改以下参数
% (新增) 窗口位置和大小 [左边距, 下边距, 宽度, 高度]，单位为像素
% 如果你想让MATLAB使用默认大小和位置，可以将此行注释掉或设置为空 []
windowPosition = [100, 100, 800, 600]; % [x, y, width, height]
% 图片所在的文件夹路径
% 例如: 'C:\Users\YourName\Desktop\MyImages'
% 或者使用相对路径: 'images' (表示脚本所在目录下的images文件夹)
imageFolder = 'D:\\Ensemble coding\\0915\\newsti0915'; 

% 图片播放序列 (核心部分)
% 这是一个数字向量，其中的数字代表要播放的图片在文件列表中的索引。
% 例如，如果有5张图片，你想按照第3张、第1张、第5张的顺序播放，就这样设置：
presentationSequence = pic_idx_concatenated{2,4}(1:3400);

% 每张图片显示的时间（单位：秒）
displayDuration = 0.04; % 每张图片显示2秒

% 两张图片之间的间隔时间（显示一个空白屏幕，单位：秒）
% 如果不需要间隔，可以设为 0
ISI= 0; % 间隔0.5秒

% 2. 准备工作：获取图片文件列表
% -------------------------------------------------------------------------
% 构造文件搜索模式
filePattern = fullfile(imageFolder, '*.bmp');

% 使用 dir 函数获取所有符合条件的文件的信息
imageFiles = dir(filePattern);

% 检查是否找到了任何图片文件
if isempty(imageFiles)
    error('在指定的文件夹 "%s" 中没有找到任何 .bmp 文件。请检查路径是否正确。', imageFolder);
end

% 提取所有文件名，并存放在一个 cell 数组中
% MATLAB 的 dir 函数通常会按字母顺序返回文件列表
allFileNames = {imageFiles.name};

% (可选，但强烈建议) 在命令行窗口显示找到的文件及其顺序
% 这样可以帮助你正确地设置上面的 `presentationSequence`
fprintf('在文件夹中找到 %d 个 .bmp 文件，顺序如下:\n', length(allFileNames));
for i = 1:length(allFileNames)
    fprintf('  %d: %s\n', i, allFileNames{i});
end

% 检查播放序列是否有效
if max(presentationSequence) > length(allFileNames) || min(presentationSequence) < 1
    error('`presentationSequence` 包含无效的索引。索引必须在 1 到 %d 之间。', length(allFileNames));
end

% 3. 创建并准备图形窗口
% -------------------------------------------------------------------------
fprintf('\n准备开始播放，按任意键继续...\n');
pause; % 等待用户按键，给用户准备时间

% 创建一个图形窗口
hFig = figure;

% 设置窗口属性，使其全屏、无菜单栏和工具栏，背景为黑色
% 设置窗口属性，使其成为一个普通的、带标题的窗口
set(hFig, 'Name', '图片播放器', ...    % 给窗口一个标题
          'NumberTitle', 'off', ...     % 不显示 "Figure 1" 这样的编号
          'Color', 'k', ...             % 背景仍然设为黑色，以配合ISI
          'MenuBar', 'figure', ...      % 显示标准的菜单栏
          'ToolBar', 'auto');         % 显示标准的工具栏

% 如果在参数部分定义了窗口位置和大小，则应用它
if ~isempty(windowPosition)
    set(hFig, 'Position', windowPosition);
end
% 创建一个坐标轴用于显示图片，并使其填满整个窗口
hAx = gca;
set(hAx, 'Units', 'normalized', 'Position', [0 0 1 1]);
axis off; % 关闭坐标轴的刻度和边框

% 4. 按预设顺序循环播放图片
% -------------------------------------------------------------------------
fprintf('开始播放...\n');

try
    % 遍历你定义的播放序列
    for i = 1:length(presentationSequence)
        % 从播放序列中获取当前要显示的图片索引
        currentImageIndex = presentationSequence(i);
        
        % 根据索引获取文件名
        currentImageName = allFileNames{currentImageIndex};
        
        % 构建完整的图片文件路径
        fullImageName = fullfile(imageFolder, currentImageName);
        
        % 读取图片文件
        imgData = imread(fullImageName);
        
        % 在坐标轴上显示图片
        imshow(imgData, 'Parent', hAx);
        
        % 强制MATLAB立即刷新窗口并显示图片
        drawnow;
        
        % 打印当前播放信息到命令行
        fprintf('正在播放第 %d/%d 张图片: %s (文件列表中的第 %d 个)\n', ...
                i, length(presentationSequence), currentImageName, currentImageIndex);
        
        % 等待指定的显示时间
        pause(displayDuration);
        
        % 如果设置了间隔时间 (ISI > 0)
        if mod(i,52)==0
            ISI=1;
        else
            ISI=0;
        end
        if ISI > 0
            % 清空坐标轴，显示黑色背景
            cla(hAx);
            drawnow;
            % 等待间隔时间
            pause(ISI);
        end
    end

catch ME % 如果循环中出现错误 (例如文件损坏)，则捕获异常
    % 关闭图形窗口
    close(hFig);
    % 重新抛出错误，让用户知道出了什么问题
    rethrow(ME);
end

% 5. 结束与清理
% -------------------------------------------------------------------------
% 播放完成后，关闭图形窗口
close(hFig);

fprintf('\n播放结束。\n');