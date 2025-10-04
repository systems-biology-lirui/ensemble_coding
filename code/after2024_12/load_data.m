
function [stimID_data, Meta_data, All_data] = load_data(Days, Conditions, Type, sessionIdx,pattern)
    global All_data
    % 加载和处理实验数据
    %
    % 输入参数:
    %   Days        - 数组，表示实验天数
    %   Conditions  - 条件编号
    %   Type        - 数据类型 (e.g., "trial_LFP")
    %   sessionIdx  - 包含session信息的索引
    %
    % 输出参数:
    %   stimID_data - 每个实验天的StimID
    %   Meta_data   - 元信息，如Trial分类和图片朝向等
    %   All_data    - 每个实验天的完整数据

    % 初始化数据
    numDays = length(Days);
    All_data = cell(1, numDays);
    Meta_data = cell(1, numDays);
    stimID_data = cell(1, numDays);

    % 遍历每一天
    for dayIdx = 1:numDays
        day = Days(dayIdx);
        
        % 获取Session信息
        Sessions = sessionIdx{Conditions, day};
        
        % 初始化当日数据存储
        All_data{dayIdx} = cell(1, length(Sessions));
        Meta_data{dayIdx} = cell(1, length(Sessions));
        stimID_data{dayIdx} = cell(1, length(Sessions));

        % 遍历Session
        for dataIdx = 1:length(Sessions)
            session = Sessions(dataIdx);

            % 加载数据文件
            dataPath = sprintf('D:\\Ensemble coding\\data\\%sdata\\DG2-u%d-%03d-500Hz.mat', ...
                               sessionIdx{2, day}, sessionIdx{1, day}, session);
            loadedData = load(dataPath);
            Datainfo = loadedData.Datainfo;

            % StimID矫正
            StimID = real_stimID(Datainfo, day);

            % 提取元信息         
            metaidx = meta_analyse(StimID, Conditions, day, pattern);

            % 提取数据
            if strcmp(Type, "trial_LFP")
                data = Datainfo.(Type);
            else
                data = Datainfo.(Type){2};
            end

            % 存储数据
            if Days <24
                All_data{dayIdx}{dataIdx} = single(data(:,1:96,1:1640));
            else
                All_data{dayIdx}{dataIdx} = single(data(:,1:96,1:1240));
            end
            Meta_data{dayIdx}{dataIdx} = metaidx;
            stimID_data{dayIdx}{dataIdx} = StimID;
            
            clear loadedData Datainfo StimID metaidx data;
            
            % 显示当前Session信息
            fprintf('Processed Session: %d\n', session);
        end
        
        % 显示当前Day信息
        fprintf('Processed Day: %d\n', day);
    end
end

function StimID = real_stimID(Datainfo, day)
    % 矫正StimID以匹配实际数据
    %
    % 输入参数:
    %   Datainfo - 数据结构体，包含StimID和响应码等信息
    %   day      - 当前实验天
    %
    % 输出参数:
    %   StimID   - 矫正后的StimID

    % 每个Trial的图片数
    trail_picnum = 72 * (day < 24) + 52 * (day >= 24);

    % 计算TrialStimID矩阵
    allpicnum = length(Datainfo.Seq.StimID);
    TrialStimID = reshape(Datainfo.Seq.StimID, [trail_picnum, allpicnum / trail_picnum])';

    % 矫正StimID
    RealOrdid = [];
    for kk = 1:length(Datainfo.VSinfo.sMbmInfo.respCode)
        RealOrdid = [RealOrdid; TrialStimID(kk, :)];
        if Datainfo.VSinfo.sMbmInfo.respCode(kk) ~= 1
            TrialStimID = cat(1, TrialStimID, TrialStimID(kk, :));
        end
    end

    % 提取有效Trial
    RealTrialID = find(Datainfo.VSinfo.sMbmInfo.respCode == 1);
    StimID = RealOrdid(RealTrialID, :)';
end

function metaidx = meta_analyse(StimID, Conditions, day, pattern)
    % 分析元信息，包括图片朝向、位置和Trial类别
    %
    % 输入参数:
    %   StimID     - 矫正后的StimID
    %   Conditions - 条件编号
    %   day        - 当前实验天
    %
    % 输出参数:
    %   metaidx    - 包含图片朝向、位置等信息的结构体

    % 初始化变量
    ori = [];
    location = [];
    trial_cluster = [];
    pic_pattern = [];

    % 根据条件编号分析数据
    switch Conditions
        case 3  % EC
            ori = floor((StimID - 1) / 18) + 1;

        case {4, 5}  % EC0, SC
            ori = mod(StimID, 18);
            ori(StimID == 109) = 19;
            ori(ori == 0) = 18;

        case 6  % Patch
            location = floor((StimID - 1) / 108) + 1;
            ori = mod(StimID - (location - 1) * 108, 18);
            ori(StimID == 1405) = 19;
            ori(ori == 0) = 18;

        case 8  % ECpatch
            location = process_ECpatch_location(StimID);
            ori = process_ECpatch_ori(StimID);
    end


    % Trial分类
    if day < 24
        trial_cluster = classify_trials(ori);
    end
    % EC中的pattern分类
    if pattern == 1
        pic_pattern = floor((mod(StimID-1, 18)/3))+1;
    end
    pic_pattern(StimID==325) = 7;
    % 存储元信息
    metaidx = {ori, location, trial_cluster,pic_pattern};
end

function location = process_ECpatch_location(StimID)
    % 处理ECpatch的Location
    location = StimID;
    location(location < 3889) = mod(location(location < 3889), 12);
    location(location == 0) = 12;
    location(location == 3889) = 15; %blank
    location(location > 3889 & location < 3998) = 13;
    location(location > 3997) = 14;
end

function ori = process_ECpatch_ori(StimID)
    % 处理ECpatch的图片朝向
    ori = StimID;
    ori(ori < 3889) = floor((ori(ori < 3889) - 1) / 216) + 1;
    ori(ori == 3889) = 19;
    ori(ori > 3889 & ori < 3998) = mod((ori(ori > 3889 & ori < 3998) - 3889), 18);
    ori(ori > 3997) = mod((ori(ori > 3997) - 3997), 18);
    ori(ori == 0) = 18;
end

function trial_cluster = classify_trials(ori)
    % 根据图片朝向分类Trial
    trial_cluster = -ones(1, size(ori, 2));  % 初始化为随机Trial (-1)
    for i = 1:size(ori, 2)
        sequence = ori(:, i);
        if length(unique(sequence(4:4:end))) == 1
            trial_cluster(i) = unique(sequence(4:4:end));  % 目标Trial
        end
    end
    trial_cluster(trial_cluster==-1) = 20;
end
