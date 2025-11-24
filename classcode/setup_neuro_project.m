function setup_neuro_project()
% SETUP_NEURO_PROJECT 自动化搭建神经科学数据分析项目框架
% 运行此脚本将生成 Data, Code, Docs 等文件夹及核心 Class 文件

    % 获取当前路径作为项目根目录
    projectRoot = pwd;
    fprintf('正在初始化项目于: %s\n', projectRoot);

    %% 1. 定义目录结构
    dirs = {
        'Data/00_Raw',           '原始数据存放区 (请将 .mat 文件放入此处)';
        'Data/01_Database',      '最终生成的标准化大文件存放区';
        'Code/+NeuroDB',         '核心数据构建包';
        'Code/+Analysis',        '具体分析代码包';
        'Code/Scripts',          '日常运行脚本';
        'Docs',                  '文档与记录';
        'Results/Figures',       '图片输出';
        'Results/Stats',         '统计结果';
    };

    %% 2. 创建文件夹
    for i = 1:size(dirs, 1)
        folderPath = fullfile(projectRoot, dirs{i, 1});
        if ~exist(folderPath, 'dir')
            mkdir(folderPath);
            fprintf('[创建] 文件夹: %s\n', dirs{i, 1});
        else
            fprintf('[跳过] 文件夹已存在: %s\n', dirs{i, 1});
        end
    end

    %% 3. 写入核心代码: Builder.m (在 +NeuroDB 中)
    builderContent = get_builder_code();
    writeFile(fullfile(projectRoot, 'Code', '+NeuroDB', 'Builder.m'), builderContent);

    %% 4. 写入全局配置: Main_Config.m (在 Code 中)
    configContent = get_config_code();
    writeFile(fullfile(projectRoot, 'Code', 'Main_Config.m'), configContent);

    %% 5. 写入示例运行脚本: run_pipeline.m (在 Scripts 中)
    runContent = get_run_script_code();
    writeFile(fullfile(projectRoot, 'Code', 'Scripts', 'run_pipeline.m'), runContent);

    %% 6. 生成一个示例 Excel 记录表
    create_dummy_log(fullfile(projectRoot, 'Docs', 'Subject_Log.xlsx'));

    fprintf('\n================================================\n');
    fprintf('项目框架构建完成！\n');
    fprintf('下一步请执行：\n');
    fprintf('1. 将你的原始 .mat 文件复制到 Data/00_Raw/\n');
    fprintf('2. 打开 Code/+NeuroDB/Builder.m，根据 "适配点" 注释修改变量名\n');
    fprintf('3. 运行 Code/Scripts/run_pipeline.m 测试流程\n');
    fprintf('================================================\n');

end

%% --- 辅助函数：写入文件 ---
function writeFile(filepath, content)
    fid = fopen(filepath, 'w', 'n', 'UTF-8'); % 强制 UTF-8
    if fid == -1
        warning('无法写入文件: %s', filepath);
        return;
    end
    fprintf(fid, '%s', content);
    fclose(fid);
    fprintf('[写入] 文件: %s\n', filepath);
end

%% --- 辅助函数：生成 Excel ---
function create_dummy_log(filepath)
    if exist(filepath, 'file'), return; end
    % 创建一个简单的 Table
    T = table({'u736'; 'u737'}, {'2023-10-25'; '2023-10-26'}, {'Fixation'; 'Sequence'}, ...
        'VariableNames', {'DateCode', 'RealDate', 'Paradigm'});
    try
        writetable(T, filepath);
        fprintf('[生成] 示例文档: %s\n', filepath);
    catch
        warning('Excel 写入失败，请手动创建 Docs/Subject_Log.xlsx');
    end
end

%% --- 代码模板内容 ---

function code = get_config_code()
code = [...
"function config = Main_Config()"
"    % 全局配置文件"
"    "
"    % 路径配置"
"    config.Path.Root = fileparts(fileparts(mfilename('fullpath'))); % 自动定位到项目根目录"
"    config.Path.Raw = fullfile(config.Path.Root, 'Data', '00_Raw');"
"    config.Path.DB = fullfile(config.Path.Root, 'Data', '01_Database');"
"    "
"    % 实验参数"
"    config.Exp.Fs = 500;           % 采样率"
"    config.Exp.SubjectList = {'DG', 'Macaque2'};"
"end"
];
code = strjoin(code, newline);
end

function code = get_run_script_code()
code = [...
"% run_pipeline.m - 执行数据汇总流程"
""
"%% 1. 环境初始化"
"restoredefaultpath;"
"current_script_path = fileparts(mfilename('fullpath'));"
"project_root = fileparts(fileparts(current_script_path)); % 回退两层到根目录"
"addpath(genpath(fullfile(project_root, 'Code'))); % 将 Code 文件夹加入路径"
""
"config = Main_Config();"
"fprintf('项目路径已加载: %s\n', config.Path.Root);"
""
"%% 2. 运行构建器 (Builder)"
"% 针对 'DG' 这个 Subject 进行构建"
"subjectName = 'DG';"
""
"% 初始化构建器"
"builder = NeuroDB.Builder(subjectName, config.Path.Root);"
""
"% [可选] 如果你要调试，可以只处理前 5 个文件"
"% builder.DebugMode = true;"
""
"% 运行构建"
"builder.run();"
""
"%% 3. 测试读取结果"
"outputFile = fullfile(config.Path.DB, [subjectName '_MasterDB.mat']);"
"if exist(outputFile, 'file')"
"    fprintf('正在加载生成的数据库以进行验证...\\n');"
"    load(outputFile, 'NeuroData');"
"    disp('数据概览:');"
"    disp(NeuroData);"
"    disp('Meta Table 前5行:');"
"    disp(NeuroData.Meta(1:5,:));"
"else"
"    warning('未找到生成的文件，请检查 Builder 是否报错。');"
"end"
];
code = strjoin(code, newline);
end

function code = get_builder_code()
code = [...
"classdef Builder < handle"
"    % NEURODB.BUILDER"
"    % 职责：采用双遍扫描法 (Two-Pass)，从 Raw 直接构建 Database"
"    % 自动处理预分配内存和对齐"
"    "
"    properties"
"        RawPath"
"        SavePath"
"        SubjectName"
"        Fs = 500;"
"        DebugMode = false; % 设为 true 时只处理少量文件"
"    end"
"    "
"    methods"
"        function obj = Builder(subjName, projectRoot)"
"            obj.SubjectName = subjName;"
"            obj.RawPath = fullfile(projectRoot, 'Data', '00_Raw');"
"            obj.SavePath = fullfile(projectRoot, 'Data', '01_Database');"
"        end"
"        "
"        function run(obj)"
"            % 获取文件列表 (匹配 DG*.mat)"
"            pattern = sprintf('%s*.mat', obj.SubjectName);"
"            files = dir(fullfile(obj.RawPath, pattern));"
"            "
"            if isempty(files)"
"                error('在 %s 未找到以 %s 开头的 .mat 文件', obj.RawPath, obj.SubjectName);"
"            end"
"            "
"            if obj.DebugMode"
"                files = files(1:min(5, length(files)));"
"                fprintf('*** 调试模式：仅处理前 %d 个文件 ***\\n', length(files));"
"            end"
"            "
"            %% Pass 1: 扫描维度"
"            fprintf('[Pass 1] 扫描文件维度...\\n');"
"            [totalTrials, maxTimePoints, nCh] = obj.scan_dimensions(files);"
"            "
"            fprintf('  -> 总Trial数: %d\\n', totalTrials);"
"            fprintf('  -> 通道数:    %d\\n', nCh);"
"            fprintf('  -> 最大长度:  %d (%.2f秒)\\n', maxTimePoints, maxTimePoints/obj.Fs);"
"            "
"            %% 预分配内存"
"            fprintf('[Alloc] 预分配内存...\\n');"
"            % 使用 single 类型减少一半内存占用 (如果精度要求极高可用 double)"
"            LFP_Tensor = nan(totalTrials, nCh, maxTimePoints, 'single');"
"            "
"            % 初始化 Meta Table"
"            MetaTable = table('Size', [totalTrials, 5], ..."
"                'VariableTypes', {'string', 'string', 'double', 'double', 'string'}, ..."
"                'VariableNames', {'Date', 'SessionID', 'GlobalTrialID', 'Duration', 'Label'});"
"            "
"            %% Pass 2: 填充数据"
"            fprintf('[Pass 2] 加载并填充数据...\\n');"
"            current_idx = 1;"
"            hWait = waitbar(0, 'Processing...');"
"            "
"            for i = 1:length(files)"
"                fname = files(i).name;"
"                if mod(i, 10) == 0, waitbar(i/length(files), hWait, sprintf('File %d/%d', i, length(files))); end"
"                "
"                % 1. 解析文件名"
"                [dateStr, sessID] = obj.parse_filename(fname);"
"                "
"                % 2. 加载数据"
"                loaded = load(fullfile(files(i).folder, fname));"
"                "
"                % 3. 提取标准格式数据"
"                [sessData, sessLabels] = obj.extract_session_data(loaded, fname);"
"                if isempty(sessData), continue; end"
"                "
"                % 4. 填入 Tensor"
"                nTrialsInSess = size(sessData, 1);"
"                "
"                for t = 1:nTrialsInSess"
"                    trial_mat = sessData{t}; % [Ch x Time]"
"                    "
"                    % 维度检查与转置"
"                    [dim1, dim2] = size(trial_mat);"
"                    if dim1 ~= nCh && dim2 == nCh"
"                        % 如果是 Time x Ch，转置为 Ch x Time"
"                        trial_mat = trial_mat';"
"                    end"
"                    "
"                    T = size(trial_mat, 2);"
"                    if T > maxTimePoints, T = maxTimePoints; trial_mat = trial_mat(:, 1:T); end"
"                    "
"                    % 写入矩阵"
"                    LFP_Tensor(current_idx, :, 1:T) = trial_mat;"
"                    "
"                    % 写入 Meta"
"                    MetaTable.Date(current_idx) = dateStr;"
"                    MetaTable.SessionID(current_idx) = sessID;"
"                    MetaTable.GlobalTrialID(current_idx) = current_idx;"
"                    MetaTable.Duration(current_idx) = T/obj.Fs;"
"                    if ~isempty(sessLabels)"
"                        MetaTable.Label(current_idx) = sessLabels(t);"
"                    end"
"                    "
"                    current_idx = current_idx + 1;"
"                end"
"            end"
"            close(hWait);"
"            "
"            %% 保存"
"            saveName = fullfile(obj.SavePath, sprintf('%s_MasterDB.mat', obj.SubjectName));"
"            fprintf('[Save] 正在保存到: %s ...\\n', saveName);"
"            "
"            NeuroData.LFP = LFP_Tensor;"
"            NeuroData.Meta = MetaTable;"
"            NeuroData.Settings.Fs = obj.Fs;"
"            NeuroData.Settings.Created = datetime('now');"
"            "
"            save(saveName, 'NeuroData', '-v7.3');"
"            fprintf('数据库构建完成！\\n');"
"        end"
"    end"
"    "
"    methods (Access = private)"
"        function [nTrials, maxT, nCh] = scan_dimensions(obj, files)"
"            nTrials = 0; maxT = 0; nCh = 0;"
"            "
"            for i = 1:length(files)"
"                m = matfile(fullfile(files(i).folder, files(i).name));"
"                "
"                % === [适配点 1]: 修改此处以匹配你的变量名 ==="
"                % 假设变量名包含 'MGv' 或 'Data'"
"                varInfo = whos(m);"
"                targetVar = '';"
"                for v = 1:length(varInfo)"
"                    if contains(varInfo(v).name, 'MGv') || contains(varInfo(v).name, 'Data')"
"                        targetVar = varInfo(v).name;"
"                        break;"
"                    end"
"                end"
"                "
"                if isempty(targetVar), continue; end"
"                "
"                % 假设是 Struct Array，长度为 1xN (N trials)"
"                thisTrials = varInfo(v).size(2); "
"                nTrials = nTrials + thisTrials;"
"                "
"                % 读取第一个 Trial 来确定通道数"
"                if nCh == 0"
"                    tempStruct = m.(targetVar)(1,1);"
"                    % === [适配点 2]: 确保读取到数据矩阵 ==="
"                    % 假设结构体里有个 .Data 字段"
"                    if isfield(tempStruct, 'Data')"
"                        dataMat = tempStruct.Data;"
"                    else"
"                        dataMat = tempStruct; % 或者它本身就是数据"
"                    end"
"                    % 确保是 Ch x Time"
"                    if size(dataMat, 1) > size(dataMat, 2)"
"                         % 如果行数远大于列数，可能是 Time x Ch，按需调整逻辑"
"                         % 但通常 64ch x 1000time"
"                         nCh = size(dataMat, 1);"
"                    else"
"                         nCh = size(dataMat, 1);"
"                    end"
"                end"
"                "
"                % 估算最大时长 (为了安全，设个默认值，或者需要遍历读取)"
"                maxT = max(maxT, 10000); % 默认先给 20秒 (10000点)"
"            end"
"        end"
"        "
"        function [dateStr, sessID] = parse_filename(~, fname)"
"            % 解析 'DG2-u736-001-500Hz.mat'"
"            try"
"                parts = split(fname, '-');"
"                % u736 -> 实际上你可能需要查 Excel 表"
"                dateStr = parts{2}; "
"                sessID = str2double(parts{3});"
"            catch"
"                dateStr = 'Unknown'; sessID = 0;"
"            end"
"        end"
"        "
"        function [dataCell, labels] = extract_session_data(~, loaded, fname)"
"            % === [适配点 3]: 核心数据提取逻辑 ==="
"            "
"            % 1. 自动寻找那个 Struct 变量"
"            fn = fieldnames(loaded);"
"            % 简单粗暴找包含 'MGv' 的变量"
"            targetName = fn{contains(fn, 'MGv')};"
"            if isempty(targetName), targetName = fn{1}; end % 没找到就取第一个"
"            "
"            rawStruct = loaded.(targetName);"
"            "
"            % 2. 转换为 Cell Array"
"            n = length(rawStruct);"
"            dataCell = cell(n, 1);"
"            labels = strings(n, 1);"
"            "
"            for i = 1:n"
"                % 假设结构是 rawStruct(i).Data"
"                if isfield(rawStruct(i), 'Data')"
"                    dataCell{i} = rawStruct(i).Data;"
"                else"
"                    % 如果结构体本身就是数据?"
"                    % dataCell{i} = rawStruct(i);"
"                end"
"                "
"                % 假设结构是 rawStruct(i).Label"
"                % labels(i) = string(rawStruct(i).Label);"
"            end"
"        end"
"    end"
"end"
];
code = strjoin(code, newline);
end