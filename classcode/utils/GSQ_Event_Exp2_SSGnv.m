%% ----------------------------------Patch------------------------------%%
% 18*13+6 = 240trial；做6个session
function Event = GSQ_Event_Exp2_SSGnv(Event,repeat)
% 实验参数（扩大6倍后的参数）
nTrials = 27*13*repeat;          % 总试次数 = 1440
numBlank = 0;           % 空白试次数 = 36
numLocation = 13;           % 条件数量（保持13个location）
trialsPerCondition = 27*repeat;% 每个条件的试次数 = 108
numImages = 52;             % 每试次图片数（保持52）
stimPos = [1,14,27,40];     % 刺激位置索引（保持4个位置）
blankCode = 0;              % 空白编码（保持0）
numOrientations = 18;       % 朝向总数（保持18个）
repeatsPerOrientation = 6*repeat;  % 每个朝向重复次数 = 24

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

% 
% %% 验证关键参数
% % 检查条件试次分配
% disp(['条件计数器验证: ', mat2str(condCounter')]); % 应全显示19
% 
% % 检查朝向分布
% for c = 1:numLocation
%     allOrients = orientationPool{c}(:);
%     hist = zeros(1, numOrientations);
%     for o = 1:numOrientations
%         hist(o) = sum(allOrients == o);
%     end
%     assert(all(hist == repeatsPerOrientation), '朝向分布错误');
% end
% disp('所有条件朝向分布验证通过');

