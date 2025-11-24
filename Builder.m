classdef Builder < handle
    % NeuroDB.Builder
    % 职责：负责从 00_Raw 直接构建 01_Database 的 Master .mat
    
    properties
        RawPath
        SavePath
        SubjectName
        Fs = 500; % 默认采样率
    end
    
    methods
        function obj = Builder(subjName, projectRoot)
            obj.SubjectName = subjName;
            obj.RawPath = fullfile(projectRoot, 'Data', '00_Raw');
            obj.SavePath = fullfile(projectRoot, 'Data', '01_Database');
        end
        
        function run(obj)
            % 主执行函数
            files = dir(fullfile(obj.RawPath, sprintf('%s*.mat', obj.SubjectName)));
            if isempty(files), error('No files found for %s', obj.SubjectName); end
            
            fprintf('开始构建 %s 的数据库...\n', obj.SubjectName);
            
            %% Pass 1: 扫描维度 (不读数据，只读元信息)
            fprintf('Pass 1: 扫描文件维度...\n');
            [totalTrials, maxTimePoints, nCh] = obj.scan_dimensions(files);
            
            fprintf('检测结果: 总Trial=%d, 通道数=%d, 最大时间点=%d\n', ...
                totalTrials, nCh, maxTimePoints);
            
            %% 预分配内存 (Pre-allocation)
            % 核心数据容器：使用 NaN 填充，方便后续处理变长数据
            LFP_Tensor = nan(totalTrials, nCh, maxTimePoints, 'single'); % 用 single 省一半内存
            
            % 元数据容器：预定义 Table 的列
            MetaTable = table('Size', [totalTrials, 5], ...
                'VariableTypes', {'string', 'string', 'double', 'double', 'string'}, ...
                'VariableNames', {'Date', 'SessionID', 'GlobalTrialID', 'Duration', 'StimLabel'});
            
            %% Pass 2: 填充数据
            fprintf('Pass 2: 加载并填充数据...\n');
            current_idx = 1;
            
            hWait = waitbar(0, 'Processing Sessions...');
            
            for i = 1:length(files)
                fname = files(i).name;
                waitbar(i/length(files), hWait, sprintf('Loading: %s', fname));
                
                % 1. 解析文件名 (依赖辅助函数)
                [dateStr, sessID] = obj.parse_filename(fname);
                
                % 2. 加载数据
                loaded = load(fullfile(files(i).folder, fname));
                
                % --- 适配你的数据结构 (这里需要根据你的实际变量名修改) ---
                % 假设 loaded 里有一个结构体叫 SessionData 或直接就是 Data 变量
                % 下面假设数据在 loaded.Data 中，格式为 {nTrials x 1} 的 cell，每个 cell 是 [nCh x nTime]
                % 或者如果是 struct array: loaded.MGv.Data
                
                % [适配点]: 提取当前 Session 的数据矩阵
                [sessData, sessLabels] = obj.extract_session_data(loaded); 
                
                nTrialsInSess = size(sessData, 1); % 假设第一维是 trial
                
                % 3. 填入 Tensor (处理时间对齐)
                for t = 1:nTrialsInSess
                    trial_matrix = sessData{t}; % 假设是 cell，取出 [nCh x nTime]
                    if isempty(trial_matrix), continue; end
                    
                    T = size(trial_matrix, 2);
                    
                    % 填入大矩阵
                    LFP_Tensor(current_idx, :, 1:T) = trial_matrix;
                    
                    % 填入 MetaTable
                    MetaTable.Date(current_idx) = dateStr;
                    MetaTable.SessionID(current_idx) = sessID;
                    MetaTable.GlobalTrialID(current_idx) = current_idx;
                    MetaTable.Duration(current_idx) = T / obj.Fs;
                    MetaTable.StimLabel(current_idx) = sessLabels(t);
                    
                    current_idx = current_idx + 1;
                end
            end
            close(hWait);
            
            %% 保存
            saveName = fullfile(obj.SavePath, sprintf('%s_MasterDB.mat', obj.SubjectName));
            fprintf('正在保存到硬盘: %s ...\n', saveName);
            
            % 封装成最终结构体
            NeuroData.LFP = LFP_Tensor;
            NeuroData.Meta = MetaTable;
            NeuroData.Settings.Fs = obj.Fs;
            NeuroData.Settings.BuildDate = datetime('now');
            
            save(saveName, 'NeuroData', '-v7.3'); % 大文件必须用 v7.3
            fprintf('完成！\n');
        end
        
    end
    
    methods (Access = private)
        function [nTrials, maxT, nCh] = scan_dimensions(obj, files)
            % 快速扫描所有文件以确定总维度
            nTrials = 0;
            maxT = 0;
            nCh = 0;
            
            for i = 1:length(files)
                % 使用 matfile 函数，它可以在不加载整个文件的情况下读取变量信息！
                % 这是处理大数据的关键技巧
                m = matfile(fullfile(files(i).folder, files(i).name));
                
                % [适配点]: 假设你的数据变量叫 'MGv'
                % 这里需要根据你的实际情况写逻辑来获取该 Session 的 trial 数
                % 下面只是示例逻辑：
                varInfo = whos(m, 'MGv'); 
                if isempty(varInfo)
                     % 如果不是这个变量名，尝试找别的
                     continue; 
                end
                
                % 假设是 struct array，size 就是 trial 数
                nTrials = nTrials + varInfo.size(2); 
                
                % 为了获取 nCh 和 maxT，可能还是得读一小点数据，或者你有固定的 nCh
                % 这里建议读取第一个 trial 来确定 nCh
                if nCh == 0
                    temp = m.MGv(1,1); % 读第一个元素
                    nCh = size(temp.Data, 1); % 假设 Data 是 [Ch x Time]
                end
                
                % 估算最大时间点 (如果不想遍历所有 trial，可以给一个足够大的固定值，比如 5秒*500Hz)
                maxT = max(maxT, 5000); % 示例：强制预留足够空间
            end
        end
        
        function [dateStr, sessID] = parse_filename(~, fname)
            % 解析 'DG2-u736-001-500Hz.mat'
            parts = split(fname, '-');
            % parts{2} = 'u736' -> 需要你自己建立一个映射表转成 '20231025'
            dateStr = parts{2}; 
            sessID = str2double(parts{3});
        end
        
        function [dataCell, labels] = extract_session_data(~, loadedStruct)
            % [适配点]: 这里是脏活累活集中的地方
            % 把不同形态的原始数据统一转成 standard cell array
            
            % 假设 loadedStruct 里面有个 MGv 结构体数组
            rawStruct = loadedStruct.MGv; 
            n = length(rawStruct);
            
            dataCell = cell(n, 1);
            labels = strings(n, 1);
            
            for i = 1:n
                dataCell{i} = rawStruct(i).Data; % [Ch x Time]
                % 如果有 label
                % labels(i) = rawStruct(i).Label; 
            end
        end
    end
end