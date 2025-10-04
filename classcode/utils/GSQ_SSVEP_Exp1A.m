function SSVEP = GSQ_SSVEP_Exp1A(SSVEP,repeat)
blocks = {'MGv'};
for block = 1:length(blocks)
totalTrials = 10*repeat;            % 总试次数
blankTrials = 0;             % 空白试次数
randomTrials = 1*repeat;            % 随机试次数
baseOrientations = [1,9];    % 基础朝向集合 (9个)
trialsPerBase = 1*repeat;           % 每个基础朝向试次数
numPatterns = 6;              % 每个朝向的模式数
totalOrientations = 18;       % 总朝向数
positionsPerTrial = 72;       % 每试次位置数
stimInterval = 4;             % 固定刺激间隔
blankCode = 0;              % 空白编码

total_trials(totalTrials) = struct('location', [], 'condition', [], 'stim_sequence', [], 'pattern', []);

% 验证参数合理性
% assert(length(baseOrientations) == 9, '基础朝向数量错误');
% assert(blankTrials + randomTrials + 9*trialsPerBase == totalTrials, '试次总数不匹配');

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
    baseOri = currentType;
    
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
% orientationHist = zeros(1, totalOrientations);
% patternHist = zeros(totalOrientations, numPatterns);
% 
% for t = 1:totalTrials
%     if trialTypes(t) ~= 0
%         orientationHist = orientationHist + histcounts(stimMatrix{t}, 0.5:1:totalOrientations+0.5);
%         for o = 1:totalOrientations
%             patternHist(o,:) = patternHist(o,:) + histcounts(patternMatrix{t}(stimMatrix{t}==o), 0.5:1:numPatterns+0.5);
%         end
%     end
% end
% 
% % 显示统计结果
% figure('Position', [100,100,1200,600])
% subplot(1,2,1)
% bar(orientationHist)
% title('各朝向总出现次数分布')
% xlabel('朝向编号'), ylabel('出现次数')
% 
% subplot(1,2,2)
% imagesc(patternHist)
% colorbar
% title('各朝向模式使用分布')
% xlabel('模式编号'), ylabel('朝向编号')