%% 汇总整理数据（trial）
currentPath = fileparts(mfilename('fullpath')); % Code/Scripts
rootPath = fileparts(fileparts(currentPath));   % Project Root
addpath(genpath(fullfile(rootPath, 'Code')));   % 加入 Code 路径

config = Main_Config();
% config.TargetBlocks = {'SSGnv'}; % 只跑这一个测试一下

builder = NeuroDB.Builder(config);
builder.run();


%% trial水平的处理
config = Main_Config();
dbPath = 'D:/ensemble_coding/Project_Ensemblecoding_2024/Data/01_Database';
analyzer = NeuroDB.NeuroAnalyzer('DG', 'SSGv', 'SSVEP_B', 'MUA2', dbPath);

%% 进行切片（PIC）
[avgEpochs, avgMeta] = analyzer.slice_epochs('AverageRepeats', true);

head(avgMeta)
