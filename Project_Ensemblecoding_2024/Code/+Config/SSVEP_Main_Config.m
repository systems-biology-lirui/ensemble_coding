function config = SSVEP_Main_Config()
    % MAIN_CONFIG 全局参数配置
    
    % === 1. 路径配置 ===
    config.Path.Root = fileparts(fileparts(mfilename('fullpath'))); 
    % config.Path.Raw  = fullfile(config.Path.Root, 'Data', '00_Raw');
    config.Path.Raw  = 'D:\ensemble_coding\DGdata\500hzdata';
    config.Path.DB   = fullfile(config.Path.Root, 'Data', '01_Database');
    
    % 元数据索引文件路径 (请确认这些路径是否需要硬编码，或也放入 Data 文件夹)
    config.Path.MetaIndices = 'D:\ensemble_coding\DGdata\tooldata\'; 
    
    % === 2. 实验参数 ===
    config.Subject = 'DG'; % 'DG' or 'QQ'
    config.Days = [1,5:8,11:13,15,17,18,21:23,25:27]; % 要处理的天数 (示例: DG_A)
    
    config.DataType = 'MUA2'; % 'MUA1', 'MUA2', 'LFP'
    config.BlocksToExtract = {'SG', 'MGv', 'MGnv', 'SSGnv', 'blank'}; 
    
    % SSVEP 特殊参数
    config.SSGLocation = 1:13; 
    config.Params.Fs = 500;
    
    % A/B 范式定义
    config.Paradigm = 'B'; % 'A' or 'B'
end