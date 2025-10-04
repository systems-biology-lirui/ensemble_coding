function SSVEP_b = GSQ_SSVEP_Exp1B(SSVEP_b,repeat)
%% SSGv
ntrialtype = 3;            % 3个trialtype
nLocations = 12;        % 13个location条件
nRepeats = repeat;          % 每个条件重复35次

nTrialsPerBlock = nLocations * nRepeats*ntrialtype;  % 每个trialtype的总试次数 = 13×35 = 455
% 预分配结构体
total_trials(nTrialsPerBlock) = struct('location', [], 'condition', [], 'stim_sequence', [], 'pattern', []);
all_trials = [];
for trialtype = [-1,1,9]
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
SSVEP_b.SSGv = total_trials;

%% SSGnv
nLocations = 13;
nTrialsPerBlock = nLocations * nRepeats*ntrialtype;  % 每个trialtype的总试次数 = 13×35 = 455
% 预分配结构体
total_trials(nTrialsPerBlock) = struct('location', [], 'condition', [], 'stim_sequence', [], 'pattern', []);
all_trials = [];
for trialtype = [-1,1,9]
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
SSVEP_b.SSGnv = total_trials;

block = {'MGv','MGnv','SG'};

for b = 1:length(block)
    nTrialsPerBlock =nRepeats*ntrialtype;
    total_trials1(nTrialsPerBlock) = struct('location', [], 'condition', [], 'stim_sequence', [], 'pattern', []);
    
    all_trials = [-1;1;9];
    all_trials1 = repmat(all_trials,nRepeats,1);
    all_trials = all_trials1;
    random_order = randperm(size(all_trials, 1));
    all_trials = all_trials(random_order, :);

    for i = 1:size(all_trials, 1)
        % total_trials(i).location = all_trials(i, 2);      % Location编号
        total_trials1(i).condition = all_trials(i, 1);    % trialtype编号

    end
    SSVEP_b.(block{b}) = total_trials1;
end

load('D://Ensemble coding//QQdata//tooldata//Exp1Btrial0915_1.mat','target10','target90','random');
% MGv
if isfield(SSVEP_b,'MGv')
    for trial = 1:size(SSVEP_b.MGv,2)
        SSVEP_b.MGv(trial).block = 'MGv';
        trialtype = SSVEP_b.MGv(trial).condition;
        if trialtype == -1
            SSVEP_b.MGv(trial).stim_sequence = random(1,:);
            SSVEP_b.MGv(trial).pic_idx = random(2,:);
        elseif trialtype == 1
            SSVEP_b.MGv(trial).stim_sequence = target10(1,:);
            SSVEP_b.MGv(trial).pic_idx = target10(2,:);
        elseif trialtype == 9
            SSVEP_b.MGv(trial).stim_sequence = target90(1,:);
            SSVEP_b.MGv(trial).pic_idx = target90(2,:);
        end
    end
end

% MGnv
if isfield(SSVEP_b,'MGnv')
    for trial = 1:size(SSVEP_b.MGnv,2)
        SSVEP_b.MGnv(trial).block = 'MGnv';
        trialtype = SSVEP_b.MGnv(trial).condition;
        if trialtype == -1
            SSVEP_b.MGnv(trial).stim_sequence = random(1,:);
            SSVEP_b.MGnv(trial).pattern = random(3,:);
        elseif trialtype == 1
            SSVEP_b.MGnv(trial).stim_sequence = target10(1,:);
            SSVEP_b.MGnv(trial).pattern = target10(3,:);
        elseif trialtype == 9
            SSVEP_b.MGnv(trial).stim_sequence = target90(1,:);
            SSVEP_b.MGnv(trial).pattern = target90(3,:);
        end
        
        SSVEP_b.MGnv(trial).pic_idx = 5400+(SSVEP_b.MGnv(trial).pattern-1)*18 + SSVEP_b.MGnv(trial).stim_sequence;
    end
end
% SG
if isfield(SSVEP_b,'SG')
    for trial = 1:size(SSVEP_b.MGnv,2)
        SSVEP_b.SG(trial).block = 'SG';
        trialtype = SSVEP_b.SG(trial).condition;
        if trialtype == -1
            SSVEP_b.SG(trial).stim_sequence = random(1,:);
            SSVEP_b.SG(trial).pattern = random(3,:);
        elseif trialtype == 1
            SSVEP_b.SG(trial).stim_sequence = target10(1,:);
            SSVEP_b.SG(trial).pattern = target10(3,:);
        elseif trialtype == 9
            SSVEP_b.SG(trial).stim_sequence = target90(1,:);
            SSVEP_b.SG(trial).pattern = target90(3,:);
        end
        
        SSVEP_b.SG(trial).pic_idx = 5292+ (SSVEP_b.SG(trial).pattern-1)*18+ SSVEP_b.SG(trial).stim_sequence  ;
    end
end
% SSGv
if isfield(SSVEP_b,'SSGv')
    for trial = 1:size(SSVEP_b.SSGv,2)
        SSVEP_b.SSGv(trial).block = 'SSGv';
        trialtype = SSVEP_b.SSGv(trial).condition;
        if trialtype == -1
            SSVEP_b.SSGv(trial).stim_sequence = random(1,:);
            SSVEP_b.SSGv(trial).pic_idx = random(2,:);
        elseif trialtype == 1
            SSVEP_b.SSGv(trial).stim_sequence = target10(1,:);
            SSVEP_b.SSGv(trial).pic_idx = target10(2,:);
        elseif trialtype == 9
            SSVEP_b.SSGv(trial).stim_sequence = target90(1,:);
            SSVEP_b.SSGv(trial).pic_idx = target90(2,:);
        end

        if SSVEP_b.SSGv(trial).location <=12
            SSVEP_b.SSGv(trial).pic_idx = (SSVEP_b.SSGv(trial).pic_idx - 5508-1)*12+SSVEP_b.SSGv(trial).location;
        elseif SSVEP_b.SSGv(trial).location == 13
            SSVEP_b.SSGv(trial).pic_idx = 3888 + (SSVEP_b.SSGv(trial).stim_sequence-1)*1+randi([0,5])*18+(SSVEP_b.SSGv(trial).location-1)*108+1;
        end
    end
end
% SSGnv
if isfield(SSVEP_b,'SSGnv')
    for trial = 1:size(SSVEP_b.SSGnv,2)
        SSVEP_b.SSGnv(trial).block = 'SSGnv';
        trialtype = SSVEP_b.SSGnv(trial).condition;
        if trialtype == -1
            SSVEP_b.SSGnv(trial).stim_sequence = random(1,:);
            SSVEP_b.SSGnv(trial).pic_idx = random(2,:);
            SSVEP_b.SSGnv(trial).pattern = random(3,:);
        elseif trialtype == 1
            SSVEP_b.SSGnv(trial).stim_sequence = target10(1,:);
            SSVEP_b.SSGnv(trial).pic_idx = target10(2,:);
            SSVEP_b.SSGnv(trial).pattern = target10(3,:);
        elseif trialtype == 9
            SSVEP_b.SSGnv(trial).stim_sequence = target90(1,:);
            SSVEP_b.SSGnv(trial).pic_idx = target90(2,:);
            SSVEP_b.SSGnv(trial).pattern = target90(3,:);
        end
        SSVEP_b.SSGnv(trial).pic_idx = 3888 + SSVEP_b.SSGnv(trial).stim_sequence+(SSVEP_b.SSGnv(trial).pattern-1)*18+(SSVEP_b.SSGnv(trial).location-1)*108;

    end
end