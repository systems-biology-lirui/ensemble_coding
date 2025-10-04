%% -----------------------------------EC----------------------------------%%
function Event = GSQ_Event_Exp2(Event,repeat)
blocks = {'MGv','MGnv','SG'};
for block = 1:3
    % 参数设置
    nTrials = 27*repeat;                   % 总 trial 数
    nBlankTrials = 0;                % blank trials 数
    nNonBlankTrials = nTrials - nBlankTrials;  % 108 个 non-blank
    stimPositions = [1, 14, 27, 40]; % 刺激位置（每 trial 4 个）
    nOrientations = 18;              % 18 种朝向
    orientations = 1:18;         % 朝向值（0°, 10°, ..., 170°）
    nPatterns = 6*repeat;                   % 6 种刺激模式
    patternReps = 1*repeat;                 % 每种模式重复 4 次

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
    % for orient = orientations
    %     idx = [stimInfo.orientation] == orient;
    %     patternsForOrient = [stimInfo(idx).pattern];
    %     fprintf('朝向 %d° 的模式分布:\n', orient);
    %     tabulate(patternsForOrient);
    % end
    % assert(all(trialMatrix(blankTrialIndices, :) == 0, 'all'), 'Blank trials 有误！');
    %
    for t = 1:nTrials
        total_trials(t).stim_sequence = trialMatrix(t,:);
        total_trials(t).pattern = patternMatrix(t, :);
    end
    Event.(blocks{block}) = total_trials;
end
end