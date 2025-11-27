function config = Main_Config()
    % === 实验参数 ===
    config.Subject = 'QQ';
    config.DateRange = [87,116];
    
    % === 路径配置 ===
    rootPath = fileparts(fileparts(mfilename('fullpath')));
    config.Path.Raw  = sprintf('D:/ensemble_coding/%sdata/500hzdata/',config.Subject);
    config.Path.DB   = fullfile(rootPath, 'Data', '01_Database');
    config.Path.MetaDir = 'D:/ensemble_coding/Project_Ensemblecoding_2024/Data/00_Raw';
    
    config.TargetParadigms = {'SSVEP_A'}; % 例如：只看 SSVEP，不看 EVENT
    
    % === Block 列表 ===
    config.TargetBlocks = {'MGv'};
    
    config.DataType = 'MUA2';
    if strcmp(config.TargetParadigms,'EVENT')
        config.TrialLength = 1240; % EVENT1240
    else
        config.TrialLength = 1640;
    end
    config.Fs = 500;
    
    % 图片呈现参数 (你需要确认这里的时间间隔!)
    % 假设: 图片呈现 40ms, 如果紧接着下一张，SOA=40ms。如果有空隙，SOA > 40ms。
    % 这里以常见的 10Hz RSVP 为例 (100ms一张)：
    config.StimDuration = 40;     % ms (仅用于记录/画图)
    if strcmp(config.TargetParadigms,'EVENT')
        config.StimSOA      = 520;    % ms (Stimulus Onset Asynchrony, 两张图开始时间的间隔)
    else
        config.StimSOA      = 40;
    end
    config.StimOffset   = 200;    % ms (Trial开始后多久出现第一张图, 对应 Datainfo 的 pre-stim padding)
    
    % 切片窗口 (相对于每张图的 Onset)
    config.EpochWin     = [-40, 200]; % ms (前200ms基线, 后300ms反应)
end