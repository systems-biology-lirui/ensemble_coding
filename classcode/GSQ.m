%% ---------------------------------2025.4.3------------------------------%%
% 第二只猴
clear 
Event = struct();
SSVEP = struct();
blocks = {'MGv','MGnv','SG'};
datetoday = '0410';
%% ----------------------------------- Event-------------------------------%

% experiment2 GSQ
% 每天只能做1800trial，因此按照16个条件（13*location+EC+EC0+SC）
% 每个trial 6*18+6blank = 114trial；可以得到每个ori24个repeat，每个pattern4个repeat

% Patch条件需要将13个位置进行打乱
% 114*13 = 7*16*13


%% -----------------------------------EC----------------------------------%%

clearvars -except Event SSVEP blocks datetoday;

for block = 1:3
    % 参数设置
    nTrials = 114;                   % 总 trial 数
    nBlankTrials = 6;                % blank trials 数
    nNonBlankTrials = nTrials - nBlankTrials;  % 108 个 non-blank
    stimPositions = [1, 14, 27, 40]; % 刺激位置（每 trial 4 个）
    nOrientations = 18;              % 18 种朝向
    orientations = 1:18;         % 朝向值（0°, 10°, ..., 170°）
    nPatterns = 6;                   % 6 种刺激模式
    patternReps = 4;                 % 每种模式重复 4 次

    % 为每个朝向生成模式序列（6种模式 × 4次）
    stimInfo = struct('orientation', [], 'pattern', []);
    total_trials(nTrials) = struct('location', [], 'condition', [], 'stim_sequence', [], 'pattern', []);
    stimCount = 1;
    for orient = orientations
        patternPool = repmat(1:nPatterns, 1, patternReps);
        patternPool = patternPool(randperm(length(patternPool)));  % 打乱
        for i = 1:length(patternPool)
            stimInfo(stimCount).orientation = orient;
            stimInfo(stimCount).pattern = patternPool(i);
            stimCount = stimCount + 1;
        end
    end
    stimInfo = stimInfo(randperm(length(stimInfo)));  % 全局打乱

    % 初始化 trial 矩阵
    trialMatrix = zeros(nTrials, 52);
    patternMatrix = zeros(nTrials, 52);  % 可选：存储模式

    % 随机选择 blank trials
    blankTrialIndices = randperm(nTrials, nBlankTrials);
    nonBlankTrialIndices = setdiff(1:nTrials, blankTrialIndices);

    % 分配刺激到 non-blank trials
    stimCount = 1;
    for trialIdx = nonBlankTrialIndices
        for pos = stimPositions
            trialMatrix(trialIdx, pos) = stimInfo(stimCount).orientation;
            patternMatrix(trialIdx, pos) = stimInfo(stimCount).pattern;
            stimCount = stimCount + 1;
        end
    end

    % 验证
    for orient = orientations
        idx = [stimInfo.orientation] == orient;
        patternsForOrient = [stimInfo(idx).pattern];
        fprintf('朝向 %d° 的模式分布:\n', orient);
        tabulate(patternsForOrient);
    end
    assert(all(trialMatrix(blankTrialIndices, :) == 0, 'all'), 'Blank trials 有误！');

    for t = 1:nTrials
        total_trials(t).stim_sequence = trialMatrix(t,:);
        total_trials(t).pattern = patternMatrix(t, :);
    end
    Event.(blocks{block}) = total_trials;
end

%% ----------------------------------Patch------------------------------%%
% 18*13+6 = 240trial；做6个session
clearvars -except Event SSVEP blocks datetoday;
% 实验参数（扩大6倍后的参数）
nTrials = 240 * 6;          % 总试次数 = 1440
numBlank = 6 * 6;           % 空白试次数 = 36
numLocation = 13;           % 条件数量（保持13个location）
trialsPerCondition = 18 * 6;% 每个条件的试次数 = 108
numImages = 52;             % 每试次图片数（保持52）
stimPos = [1,14,27,40];     % 刺激位置索引（保持4个位置）
blankCode = 0;              % 空白编码（保持0）
numOrientations = 18;       % 朝向总数（保持18个）
repeatsPerOrientation = 4 * 6; % 每个朝向重复次数 = 24

% 验证参数有效性
assert(numBlank + numLocation*trialsPerCondition == nTrials, '参数不匹配');

% 初始化结构体
total_trials(nTrials) = struct('location', [], 'condition', [], 'stim_sequence', [], 'pattern', []);;

% 生成试次标签（直接生成6倍后的完整序列）
trialLabels = [zeros(1, numBlank), kron(1:numLocation, ones(1, trialsPerCondition))];
trialLabels = trialLabels(randperm(nTrials)); % 全局随机化

% 生成每个条件的朝向池（调整重复次数为24）
orientationPool = cell(numLocation, 1);
for c = 1:numLocation
    % 生成基础序列：每个朝向重复24次
    orientations = repmat(1:numOrientations, 1, repeatsPerOrientation);
    
    % 验证总数：108试次 × 4刺激 = 432，18朝向 × 24重复 = 432
    assert(length(orientations) == trialsPerCondition * length(stimPos),...
        '朝向数量不匹配');
    
    % 打乱顺序并重塑为试次矩阵（108行 × 4列）
    orientationPool{c} = reshape(orientations(randperm(length(orientations))),...
        trialsPerCondition, []);
end

% 构建刺激序列
condCounter = ones(numLocation, 1); % 条件试次计数器

for t = 1:nTrials
    currentLabel = trialLabels(t);
    
    % 处理空白试次
    if currentLabel == 0
        total_trials(t).location = blankCode;
        total_trials(t).stim_sequence = zeros(1, numImages);
        continue;
    end
    
    % 处理条件试次
    currentCond = currentLabel;
    currentTrial = condCounter(currentCond);
    orients = orientationPool{currentCond}(currentTrial, :);
    condCounter(currentCond) = condCounter(currentCond) + 1;
    
    % 生成刺激序列
    stim_seq = zeros(1, numImages);
    stim_seq(stimPos) = orients; % 在刺激位置填入朝向
    
    % 存储结果
    total_trials(t).location = currentCond;
    total_trials(t).stim_sequence = stim_seq;
end
Event.SSGnv = total_trials;
%% 验证关键参数
% 检查条件试次分配
disp(['条件计数器验证: ', mat2str(condCounter')]); % 应全显示19

% 检查朝向分布
for c = 1:numLocation
    allOrients = orientationPool{c}(:);
    hist = zeros(1, numOrientations);
    for o = 1:numOrientations
        hist(o) = sum(allOrients == o);
    end
    assert(all(hist == repeatsPerOrientation), '朝向分布错误');
end
disp('所有条件朝向分布验证通过');







%% -------------------------------- SSVEP-------------------------------------%%



% 按照一个能做1800trial
% 一共16（13location+EC+EC0+SC）*11（9ori+random+blank）=176，相当于每天每种
% 条件能做10个repeat，EC/EC0/SC一个session11*10个trial。（EC还要考虑pattern）
% Patch做5个session，每个session里面2repeat*11*13trial



%% ---------------------------------EC---------------------------------------%%
clearvars -except Event SSVEP blocks datetoday;

for block = 1:3
totalTrials = 110;            % 总试次数
blankTrials = 10;             % 空白试次数
randomTrials = 10;            % 随机试次数
baseOrientations = 1:2:17;    % 基础朝向集合 (9个)
trialsPerBase = 10;           % 每个基础朝向试次数
numPatterns = 6;              % 每个朝向的模式数
totalOrientations = 18;       % 总朝向数
positionsPerTrial = 72;       % 每试次位置数
stimInterval = 4;             % 固定刺激间隔
blankCode = 0;              % 空白编码

total_trials(110) = struct('location', [], 'condition', [], 'stim_sequence', [], 'pattern', []);

% 验证参数合理性
assert(length(baseOrientations) == 9, '基础朝向数量错误');
assert(blankTrials + randomTrials + 9*trialsPerBase == totalTrials, '试次总数不匹配');

% 生成试次标签序列
trialTypes = [zeros(1, blankTrials), ...             % 空白试次
             -ones(1, randomTrials), ...             % 随机试次
             kron(1:2:17, ones(1, trialsPerBase))];     % 基础朝向试次
shuffledIndex = randperm(totalTrials);
trialTypes = trialTypes(shuffledIndex); % 随机化顺序

% 初始化模式分配系统
% 记录每个朝向的模式使用计数（行：朝向，列：模式）
patternCounters = ones(totalOrientations, numPatterns);
% 每个朝向的当前模式指针
currentPattern = ones(totalOrientations, 1);

% 创建主数据存储结构
stimMatrix = cell(totalTrials, 1);   % 刺激编码矩阵
patternMatrix = cell(totalTrials, 1); % 模式编码矩阵

globalOriCount = zeros(1, totalOrientations);
% 遍历所有试次生成内容
for t = 1:totalTrials
    currentType = trialTypes(t);
    baseOri = baseOrientations(mod(currentType-1,9)+1)*(currentType>0);
    
    if currentType == 0 % 空白试次
        stimMatrix{t} = blankCode * ones(1, positionsPerTrial);
        patternMatrix{t} = zeros(1, positionsPerTrial);
        
    elseif currentType == -1 % 随机试次
        % 生成基础序列（每个朝向重复4次）
        oriPool = repelem(1:totalOrientations, 4);
        oriPool = oriPool(randperm(length(oriPool)));
        
        % 分配模式并更新计数器
        [stimSeq, patternSeq] = deal(zeros(1, positionsPerTrial));
        for p = 1:positionsPerTrial
            ori = oriPool(p);
            pattern = currentPattern(ori);
            stimSeq(p) = ori;
            patternSeq(p) = pattern;
            
            % 更新模式计数器
            patternCounters(ori, pattern) = patternCounters(ori, pattern) + 1;
            currentPattern(ori) = mod(currentPattern(ori), numPatterns) + 1;
        end
        
        stimMatrix{t} = stimSeq;
        patternMatrix{t} = patternSeq;
        
    else % 基础朝向试次
        % 确定固定刺激位置
        fixedPositions = stimInterval:stimInterval:positionsPerTrial;
        variablePositions = setdiff(1:positionsPerTrial, fixedPositions);
        
        % 生成刺激序列
        [stimSeq, patternSeq] = deal(zeros(1, positionsPerTrial));
        
        % 处理固定位置
        stimSeq(fixedPositions) = baseOri;
        for p = fixedPositions
            pattern = currentPattern(baseOri);
            patternSeq(p) = pattern;
            patternCounters(baseOri, pattern) = patternCounters(baseOri, pattern) + 1;
            currentPattern(baseOri) = mod(currentPattern(baseOri), numPatterns) + 1;
            globalOriCount(baseOri) = globalOriCount(baseOri)+1;
        end
        
        % 处理可变位置（排除基础朝向）
        availableOrientations = setdiff(1:totalOrientations, baseOri);
        for p = variablePositions
            % 动态计算选择权重（当前出现次数越少权重越高）
            counts = globalOriCount(availableOrientations);
            selectionWeights = exp(-3*(counts-min(counts))); % 加1避免除零

            % 归一化权重并概率采样
            selectionWeights = selectionWeights / sum(selectionWeights);
            ori = randsample(availableOrientations, 1, true, selectionWeights);

            % 更新全局计数器
            globalOriCount(ori) = globalOriCount(ori) + 1;

            % 模式选择逻辑（保持原有代码）
            pattern = currentPattern(ori);
            stimSeq(p) = ori;
            patternSeq(p) = pattern;

            % 更新模式计数器
            patternCounters(ori, pattern) = patternCounters(ori, pattern) + 1;
            currentPattern(ori) = mod(currentPattern(ori), numPatterns) + 1;
        end
        
        stimMatrix{t} = stimSeq;
        patternMatrix{t} = patternSeq;
    end
    total_trials(t).stim_sequence = stimMatrix{t};
    total_trials(t).condition = currentType;
    total_trials(t).pattern = patternMatrix{t};
end
SSVEP.(blocks{block}) = total_trials;
end


%% 验证模块
% 统计每个朝向的总出现次数
orientationHist = zeros(1, totalOrientations);
patternHist = zeros(totalOrientations, numPatterns);

for t = 1:totalTrials
    if trialTypes(t) ~= 0
        orientationHist = orientationHist + histcounts(stimMatrix{t}, 0.5:1:totalOrientations+0.5);
        for o = 1:totalOrientations
            patternHist(o,:) = patternHist(o,:) + histcounts(patternMatrix{t}(stimMatrix{t}==o), 0.5:1:numPatterns+0.5);
        end
    end
end

% 显示统计结果
figure('Position', [100,100,1200,600])
subplot(1,2,1)
bar(orientationHist)
title('各朝向总出现次数分布')
xlabel('朝向编号'), ylabel('出现次数')

subplot(1,2,2)
imagesc(patternHist)
colorbar
title('各朝向模式使用分布')
xlabel('模式编号'), ylabel('朝向编号')






%% ----------------------------------------Patch0---------------------------%%

clearvars -except Event SSVEP blocks datetoday;
% 定义参数
num_locations = 13;
trials_per_location = 110;
num_blank = 10;
num_random = 10;
orientations = 1:2:17; % 9种整体朝向条件
trials_per_orientation = 10;
globalOriCount = zeros(13, 18);

% 验证条件总数
assert(num_blank + num_random + length(orientations)*trials_per_orientation == trials_per_location, '条件数量不匹配');

% 生成基础条件数组（每个location使用）
condition_base = [zeros(1, num_blank), -ones(1, num_random)];
for o = orientations
    condition_base = [condition_base, repmat(o, 1, trials_per_orientation)];
end

% 预分配存储结构
total_trials(num_locations * trials_per_location) = struct('location', [], 'condition', [], 'stim_sequence', [], 'pattern', []);
index = 1;

% 生成每个location的trial
for loc = 1:num_locations
    % 打乱当前location的条件顺序
    shuffled_conditions = condition_base(randperm(trials_per_location));
    
    % 填充当前location的trial信息
    for t = 1:trials_per_location
        total_trials(index).location = loc;
        total_trials(index).condition = shuffled_conditions(t);
        index = index + 1;
    end
end

% 全局打乱所有trial顺序
total_trials = total_trials(randperm(numel(total_trials)));

% 生成每个trial的刺激序列
for i = 1:numel(total_trials)
    trial = total_trials(i);
    
    if trial.condition == 0       % Blank trial
        stim_seq = ones(72, 1) * 325;
        
    elseif trial.condition == -1  % Random trial
        orientations_random = repmat(1:18, 1, 4);
        stim_seq = orientations_random(randperm(72))';
        
    else                          % 定向trial
        ori_val = trial.condition;
        stim_seq = zeros(72, 1);
        
        % 设置固定位置
        fixed_positions = 4:4:72;
        stim_seq(fixed_positions) = ori_val;
        globalOriCount(total_trials(i).location,ori_val) = globalOriCount(total_trials(i).location,ori_val) + 18;
        % 生成随机位置
        other_positions = setdiff(1:72, fixed_positions);
        available_orientations = setdiff(1:18, ori_val);
        for pic = other_positions

            % 动态计算选择权重（当前出现次数越少权重越高）
            counts = globalOriCount(total_trials(i).location,available_orientations);
            selectionWeights = exp(-3*(counts-min(counts))); % 加1避免除零

            % 归一化权重并概率采样
            selectionWeights = selectionWeights / sum(selectionWeights);
            ori = randsample(available_orientations, 1, true, selectionWeights);

            % 更新全局计数器
            globalOriCount(total_trials(i).location,ori) = globalOriCount(total_trials(i).location,ori) + 1;

            stim_seq(pic) = ori;
        end
        
    end
    
    total_trials(i).stim_sequence = stim_seq';
end
SSVEP.SSGnv = total_trials;
%% 验证
figure;
orientationHist = zeros(13, 18);


for t = 1:286
    
        orientationHist(total_trials(t).location,:) = orientationHist(total_trials(t).location,:) + histcounts(total_trials(t).stim_sequence, 0.5:1:18+0.5);
        
    
end

imagesc(orientationHist)


%% ----------------------------Patchvar ----------------------------------%
% 依旧采用与第一只猴相同的序列
clearvars -except Event SSVEP blocks datetoday;

ntrialtype = 3;            % 3个trialtype
nLocations = 13;        % 13个location条件
nRepeats = 35;          % 每个条件重复35次
nTrialsPerBlock = nLocations * nRepeats*ntrialtype;  % 每个trialtype的总试次数 = 13×35 = 455
% 预分配结构体
total_trials(nTrialsPerBlock) = struct('location', [], 'condition', [], 'stim_sequence', [], 'pattern', []);
all_trials = [];
for trialtype = 1:ntrialtype
    for loc = 1:nLocations
        all_trials = [all_trials; repmat([trialtype, loc], nRepeats, 1)];
    end
end
% 随机打乱所有试次
random_order = randperm(size(all_trials, 1));
all_trials = all_trials(random_order, :);

for i = 1:size(all_trials, 1)
    total_trials(i).location = all_trials(i, 2);      % Location编号
    total_trials(i).condition = all_trials(i, 1);    % trialtype编号
    
end
SSVEP.SSGv = total_trials;

save(sprintf('D:\\Ensemble coding\\sti\\GSQdata2025%s.mat',datetoday),'SSVEP',"Event");
%% -----------------------------feature2picID-----------------------------%

clearvars -except Event SSVEP blocks datetoday;
load('D:\\Ensemble coding\\data\\PatchvarSequence.mat','target90','target10','random');
% 构建新的刺激库，
% 1-3888 SSGv；
% 3889-5292 SSGnv；
% 5293-5400 SG；
% 5401-5508 MGnv；
% 5509-5832MGv；
% 5833 blank；

% MGv
for i = 1:size([SSVEP.MGv.condition],2)
    if SSVEP.MGv(i).condition ~= 0
        SSVEP.MGv(i).pic_idx = 5508 + (SSVEP.MGv(i).stim_sequence-1)*18+(SSVEP.MGv(i).pattern-1)*3+1;
    else
        SSVEP.MGv(i).pic_idx = 5508 + ones(1,72)*325;
    end
    SSVEP.MGv(i).block = 'MGv';
end
for i = 1:size(Event.MGv,2)
    if any(Event.MGv(i).stim_sequence,'all') 
        for pic = 1:52
            if Event.MGv(i).stim_sequence(pic) == 0
                Event.MGv(i).pic_idx(pic) = 5833;
            else
                Event.MGv(i).pic_idx(pic) = 5508 + (Event.MGv(i).stim_sequence(pic)-1)*18+(Event.MGv(i).pattern(pic)-1)*3+1;
            end
        end
    else
        Event.MGv(i).pic_idx = 5508 + ones(1,52)*325;
        Event.MGv(i).condition = 0;
    end
    Event.MGv(i).block = 'MGv';
end
% MGnv
for i = 1:size([SSVEP.MGnv.condition],2)
    if SSVEP.MGnv(i).condition ~= 0
        SSVEP.MGnv(i).pic_idx = 5400 + (SSVEP.MGnv(i).stim_sequence-1)*1+(SSVEP.MGnv(i).pattern-1)*18+1;
    else
        SSVEP.MGnv(i).pic_idx = 5508 + ones(1,72)*325;
    end
    SSVEP.MGnv(i).block = 'MGnv';
end
for i = 1:size(Event.MGnv,2)
    if any(Event.MGnv(i).stim_sequence,'all') 
        for pic = 1:52
            if Event.MGnv(i).stim_sequence(pic) == 0
                Event.MGnv(i).pic_idx(pic) = 5833;
            else
                Event.MGnv(i).pic_idx(pic) = 5400 + (Event.MGnv(i).stim_sequence(pic)-1)*1+(Event.MGnv(i).pattern(pic)-1)*18+1;
            end
        end
    else
        Event.MGnv(i).pic_idx = 5508 + ones(1,52)*325;
        Event.MGnv(i).condition = 0;
    end
    Event.MGnv(i).block = 'MGnv';
end
% SG
for i = 1:size([SSVEP.SG.condition],2)
    if SSVEP.SG(i).condition ~= 0
        SSVEP.SG(i).pic_idx = 5292 + (SSVEP.SG(i).stim_sequence-1)*1+(SSVEP.SG(i).pattern-1)*18+1;
    else
        SSVEP.SG(i).pic_idx = 5508 + ones(1,72)*325;
    end
    SSVEP.SG(i).block = 'SG';
end
for i = 1:size(Event.SG,2)
    if any(Event.SG(i).stim_sequence,'all') 
        for pic = 1:52
            if Event.SG(i).stim_sequence(pic) == 0
                Event.SG(i).pic_idx(pic) = 5833;
            else
                Event.SG(i).pic_idx(pic) = 5292 + (Event.SG(i).stim_sequence(pic)-1)*1+(Event.SG(i).pattern(pic)-1)*18+1;
            end
        end
        
    else
        Event.SG(i).pic_idx = 5508 + ones(1,52)*325;
        Event.SG(i).condition = 0;
    end
    Event.SG(i).block = 'SG';
end
% SSGnv
for i = 1:size([SSVEP.SSGnv.condition],2)
    if SSVEP.SSGnv(i).condition ~= 0
        SSVEP.SSGnv(i).pic_idx = 3888 + (SSVEP.SSGnv(i).stim_sequence-1)*1+(SSVEP.SSGnv(i).location-1)*108+1;
    else
        SSVEP.SSGnv(i).pic_idx = 5508 + ones(1,72)*325;
    end
    SSVEP.SSGnv(i).block = 'SSGnv';
end
for i = 1:size(Event.SSGnv,2)
    if any(Event.SSGnv(i).stim_sequence,'all') 
        for pic = 1:52
            if Event.SSGnv(i).stim_sequence(pic) == 0
                Event.SSGnv(i).pic_idx(pic) = 5833;
            else
                Event.SSGnv(i).pic_idx(pic) = 3888 + (Event.SSGnv(i).stim_sequence(pic)-1)*1+(Event.SSGnv(i).location-1)*108+1;
            end
        end
    else
        Event.SSGnv(i).pic_idx = 5508 + ones(1,52)*325;
        Event.SSGnv(i).condition = 0;
    end
    Event.SSGnv(i).block = 'SSGnv';
end
% SSGv
for i = 1:size([SSVEP.SSGv.condition],2)
    if SSVEP.SSGv(i).location ~= 13
        if SSVEP.SSGv(i).condition == 1
            SSVEP.SSGv(i).pic_idx = 0 + (target10-1)*12+SSVEP.SSGnv(i).location;
        elseif SSVEP.SSGv(i).condition == 2
            SSVEP.SSGv(i).pic_idx = 0 + (target90-1)*12+SSVEP.SSGnv(i).location;
        else
            SSVEP.SSGv(i).pic_idx = 0 + (random-1)*12+SSVEP.SSGnv(i).location;
        end
    else
        
        if SSVEP.SSGv(i).condition == 1
            ori_seq = floor((target10-1)/18)+1;
            
        elseif SSVEP.SSGv(i).condition == 2
            ori_seq = floor((target90-1)/18)+1;
        else
            ori_seq = floor((random-1)/18)+1;
        end
        SSVEP.SSGv(i).pic_idx = 3888 + (ori_seq-1)*1+(SSVEP.SSGnv(i).location-1)*108+1;
    end
    SSVEP.SSGv(i).block = 'SSGv';
end







%% ------------------------------分离session------------------------------%
% SSVEP
clearvars -except Event SSVEP blocks datetoday;
% 定义参数
block_names = {'MGv', 'MGnv', 'SG', 'SSGnv'};  % 4 个 block
num_blocks = length(block_names);
num_sessions = 10;
num_blanks = 2;  % 每个 session 插入的 blank 数量

% Step 1: 处理前 3 个 block（MGv, MGnv, SG）
all_sessions = cell(num_blocks, num_sessions);

for b = 1:3  % 前 3 个 block
    block = SSVEP.(block_names{b});
    conditions = [block.condition];
    
    % 排除 condition=0 的情况
    valid_indices = find(conditions ~= 0);
    block = block(valid_indices);
    conditions = conditions(valid_indices);
    
    unique_conditions = unique(conditions);
    num_conditions = length(unique_conditions);
    
    % 记录每个 condition 的索引
    [~, ~, idx] = unique(conditions, 'stable');
    all_indices = accumarray(idx, (1:length(block))', [], @(x) {x});
    
    % 随机打乱索引顺序
    for i = 1:num_conditions
        all_indices{i} = all_indices{i}(randperm(num_sessions));
    end
    
    % 生成当前 block 的 10 个 session
    for session = 1:num_sessions
        session_indices = zeros(1, num_conditions);
        for cond = 1:num_conditions
            session_indices(cond) = all_indices{cond}(session);
        end
        all_sessions{b, session} = block(session_indices);
    end
end

% Step 2: 处理第 4 个 block（SSGnv）
block = SSVEP.SSGnv;
locations = [block.location];
conditions = [block.condition];

% 排除 condition=0 的情况
valid_indices = find(conditions ~= 0);
block = block(valid_indices);
locations = locations(valid_indices);
conditions = conditions(valid_indices);

% 生成唯一的组合键（location + condition）
combo_keys = [locations; conditions]';
[unique_combo, ~, combo_idx] = unique(combo_keys, 'rows', 'stable');
num_combos = size(unique_combo, 1);

% 检查数据合规性
assert(length(block) == num_combos * num_sessions, 'SSGnv 的交叉组合数量应为 num_combos × 10');

% 记录每个组合的索引
all_indices = accumarray(combo_idx, (1:length(block))', [], @(x) {x});

% 随机打乱索引顺序
for i = 1:num_combos
    all_indices{i} = all_indices{i}(randperm(num_sessions));
end

% 生成当前 block 的 10 个 session
for session = 1:num_sessions
    session_indices = zeros(1, num_combos);
    for combo = 1:num_combos
        session_indices(combo) = all_indices{combo}(session);
    end
    all_sessions{4, session} = block(session_indices);
end

% Step 3: 合并 4 个 block 并打乱顺序
final_sessions = cell(num_sessions, 1);
pic_idx_concatenated = cell(num_sessions, 1); 
for session = 1:num_sessions
    % 提取 4 个 block 的当前 session
    blocks_in_session = cell(1, num_blocks);
    for b = 1:num_blocks
        blocks_in_session{b} = all_sessions{b, session};
    end
    
    % 打乱 block 的顺序
    shuffled_order = randperm(num_blocks);
    shuffled_blocks = blocks_in_session(shuffled_order);
    
    % 横向拼接
    session_data = [shuffled_blocks{:}];
    
    % 插入 blank 实例
    blank_struct = struct(...
        'location', 0, ...
        'condition', 0, ...
        'stim_sequence', [], ...
        'pattern',[], ...
        'pic_idx', 5833 * ones(1, 72), ...
        'block', 'blank' ...
    );
    
    % 随机选择插入位置（不重复）
    insert_positions = randperm(length(session_data) + num_blanks, num_blanks);
    insert_positions = sort(insert_positions);
    
    % 插入 blank
    for i = 1:num_blanks
        session_data = [session_data(1:insert_positions(i)-1), blank_struct, session_data(insert_positions(i):end)];
    end
    
    final_sessions{session} = session_data;
    pic_idx_concatenated{session} = [session_data.pic_idx];
end

% 验证结果
for session = 1:num_sessions
    % 检查 blank 实例
    blank_flags = [final_sessions{session}.condition] == 0;
    assert(sum(blank_flags) == num_blanks, 'Blank 实例数量不正确');
    
    % 检查非 blank 数据的唯一性
    non_blank_data = final_sessions{session}(~blank_flags);
    for b = 1:3
        block_data = non_blank_data(strcmp({non_blank_data.block}, block_names{b}));
        conditions = [block_data.condition];
        assert(all(conditions ~= 0) && length(unique(conditions)) == length(conditions), ...
               '非 blank 数据的 condition 不唯一或包含 0');
    end
    
    % 检查 SSGnv 的交叉组合唯一性
    ssgnv_data = non_blank_data(strcmp({non_blank_data.block}, 'SSGnv'));
    combo_check = [[ssgnv_data.location]; [ssgnv_data.condition]]';
    assert(size(unique(combo_check, 'rows'), 1) == size(combo_check, 1), ...
           'SSGnv 交叉组合不唯一');
end

disp('所有验证通过！');

save(sprintf('D:\\Ensemble coding\\sti\\GSQdata_session2025%s.mat',datetoday),'final_sessions',"pic_idx_concatenated");










%% -------------------------- Event Session--------------------------------%
clearvars -except Event SSVEP blocks datetoday;
% 定义参数
block_names = {'MGv', 'MGnv', 'SG', 'SSGnv'};  % 4 个 block
num_blocks = length(block_names);
num_sessions = 6;          % Session 总数改为6
num_blanks = 4;            % 每个 session 插入的 blank 数量
session_size_per_block = 18; % 前3个block每个session包含18个实例

% Step 1: 处理前3个block (MGv, MGnv, SG)
all_sessions = cell(num_blocks, num_sessions); 

for b = 1:3  % 处理前3个block
    block = Event.(block_names{b});
    
    zero_indices = find(arrayfun(@(x) isequal(x.condition, 0), block));
    valid_indices=setdiff(1:size(block,2),zero_indices);
    block = block(valid_indices);
    
    
    % 检查数据量是否足够
    required_instances = num_sessions * session_size_per_block;
    assert(length(block) >= required_instances, ...
        'Block %s 有效实例不足，需要至少 %d 个，当前 %d 个', block_names{b}, required_instances, length(block));
    
    % 随机打乱并选择所需实例
    shuffled_indices = randperm(length(block), required_instances); 
    block = block(shuffled_indices);
    
    % 切分为6个session (每个session 18个)
    for session = 1:num_sessions
        start_idx = (session-1)*session_size_per_block + 1;
        end_idx = session*session_size_per_block;
        all_sessions{b, session} = block(start_idx:end_idx);
    end
end

% Step 2: 处理第4个block (SSGnv)
block = Event.SSGnv;
locations = [block.location];
zero_indices = find(arrayfun(@(x) isequal(x.condition, 0), block));
valid_indices=setdiff(1:size(block,2),zero_indices);

block = block(valid_indices);
locations = locations(valid_indices);

% 获取唯一location并检查数量
unique_locations = unique(locations);
num_locations = length(unique_locations); 

% 为每个location分配18×6=108个实例到6个session
for loc_idx = 1:num_locations
    loc = unique_locations(loc_idx);
    loc_indices = find(locations == loc);  % 当前location的所有实例
    
    % 随机选择108个实例
    assert(length(loc_indices) >= 108, 'Location %d 实例不足，需要108个，当前%d个', loc, length(loc_indices));
    selected_indices = loc_indices(randperm(length(loc_indices), 108));
    
    % 分配到6个session，每个session18个
    for session = 1:num_sessions
        start_idx = (session-1)*18 + 1;
        end_idx = session*18;
        session_data = block(selected_indices(start_idx:end_idx));
        all_sessions{4, session} = [all_sessions{4, session}, session_data];
    end
end

% 打乱每个session中SSGnv实例的顺序
for session = 1:num_sessions
    shuffled_indices = randperm(length(all_sessions{4, session}));
    all_sessions{4, session} = all_sessions{4, session}(shuffled_indices);
end

% Step 3: 合并block并插入blank实例
final_sessions = cell(num_sessions, 1);
pic_idx_concatenated = cell(num_sessions, 1);

for session = 1:num_sessions
    % 提取四个block的数据
    session_data = [];
    for b = 1:num_blocks
        session_data = [session_data, all_sessions{b, session}];
    end
    
    % 打乱block顺序 (例如 [SSGnv, MGv, SG, MGnv])
    block_order = randperm(num_blocks);
    shuffled_data = [];
    for b = block_order
        shuffled_data = [shuffled_data, all_sessions{b, session}];
    end
    
    % 插入4个blank实例
    blank_struct = struct(...
        'location', 0, ...
        'condition', 0, ...
        'stim_sequence', [], ...
        'pattern', [], ...
        'pic_idx', 5833 * ones(1,52), ...
        'block', 'blank' ...
    );
    
    % 随机选择插入位置（不重复）
    insert_positions = randperm(length(session_data) + num_blanks, num_blanks);
    insert_positions = sort(insert_positions);
    
    % 插入 blank
    for i = 1:num_blanks
        session_data = [session_data(1:insert_positions(i)-1), blank_struct, session_data(insert_positions(i):end)];
    end
    
    final_sessions{session} = session_data;
    pic_idx_concatenated{session} = [session_data.pic_idx];
end



% 保存数据
save(sprintf('D:\\Ensemble coding\\sti\\GSQdata_session2025%s.mat', datetoday), 'final_sessions', "pic_idx_concatenated");



%% ---------------------------GSQ------------------------------------------------------------%
clearvars -except final_sessions pic_idx_concatenated datetoday
load('D:\\Ensemble coding\\data\\gsqbase.mat');
% for i = 1:10
%     pic_idx_concatenated{i,1} = pic_idx_concatenated{i,1}-3888;
% end
C = {};
for i = 1:size(final_sessions,1)
    C{1,i}(1:19,1) = D{1,1}(1:19,1);
    flash_num=length(pic_idx_concatenated{i,1});
    %数字列
    C{1,i}(20:(19+flash_num)) = D{1,1}(20,1);
    C{1,i}((20+flash_num):(29+flash_num)) = D{1,1}(11540:11549,1);
    
    %整理数据
    numeric_lines = [];
    for m = 1:length(C{1,i})
        line_content = C{1,i}{m};
        if ~isempty(str2num(line_content))  % 检查行是否包含数字
            numeric_lines = [numeric_lines, m];
        end
    end
    for line_idx = 1:(size(numeric_lines,2)-1)
        numeric_line = C{1,i}{numeric_lines(line_idx)};
        values = strsplit(numeric_line, ',');
        % 修改第 10 列的值（假设从1开始计数）
        values{38} = [num2str(pic_idx_concatenated{i,1}(line_idx)),';']; 
        new_numeric_line = strjoin(values, ',');

        C{1,i}{numeric_lines(line_idx)} = new_numeric_line;
    end
    for line_idx = size(numeric_lines,2)
        % 获取当前行的数据
        numeric_line = C{1,i}{numeric_lines(line_idx)};
        values = strsplit(numeric_line, ',');
        cellArray = cellfun(@num2str, num2cell(pic_idx_concatenated{i,1}), 'UniformOutput', false);
        values = cellArray;  % 将第 10 列的值修改为 100
        values{size(pic_idx_concatenated{i,1},2)} = [cellArray{size(pic_idx_concatenated{i,1},2)},';'];  % 将第 10 列的值修改为 100
        new_numeric_line = strjoin(values, ',');
        C{1,i}{numeric_lines(line_idx)} = new_numeric_line;
    end
    %修改总数
    
    C{1,i}(4,1) = {sprintf('SequenceLength = %d;',flash_num)};
    
    new_filename = sprintf('z5833session%d_2025%s.GSQ',i,datetoday);
        
    fid = fopen(new_filename, 'w');
    for n = 1:length(C{1,i})
        fprintf(fid, '%s\n', C{1,i}{n});
    end
    fclose(fid);

    disp(['Modified data saved to ', new_filename]);

end

