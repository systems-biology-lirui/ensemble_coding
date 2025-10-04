% 3）天之内去除异常trail；4）按照朝向等特征进行排列；5）normalize；6）天之间合并
% 先在每天上将信号整理，之后按照上下分位去除每个朝向下的异常值，之后对天之间的数据进行标准化处理，
% 对LFP和MUA
%-----------------------------%%-------------------------%%
% 1-ori; 2-location; 3-trail_target;
% location: 1-13; 14-SC;15-blank



function [All_data_pre, All_num, All_data] = pre_analyse(All_data, Meta_data, Days, Conditions, factor1, window)


numDays = length(Days);
numConditions = 14;  % 1:14 conditions

% 初始化数据存储
if Conditions == 6 || Conditions == 8
    All_data_pre = cell(15, 20);
else
    All_data_pre = cell(1, 20);
end

All_num = zeros(15, 20); % 记录每个位置和朝向的数据数量

% 遍历每一天的数据
for dayIdx = 1:numDays
    day = dayIdx;
    numSessions = length(Meta_data{1, day});

    for sessionIdx = 1:numSessions
        numTrials = length(Meta_data{1, day}{1, sessionIdx}{1, 1}(1, :));

        % 为每个 session 重新初始化 condition 数据
        Session_data_pre = cell(size(All_data_pre));
        Session_num = zeros(size(All_num));

        for trialIdx = 1:numTrials
            trialData = All_data{1, day}{1, sessionIdx}(trialIdx, :, :);

            % 处理不同 condition
            for condition = 1:numConditions
                if factor1 == 2
                    [locationIdx, trialClusterIdx] = processTrial(factor1, Meta_data, day, sessionIdx, trialIdx);
                    Session_data_pre{locationIdx, trialClusterIdx} = cat(1, ...
                        Session_data_pre{locationIdx, trialClusterIdx}, trialData);
                    Session_num(locationIdx, trialClusterIdx) = ...
                        Session_num(locationIdx, trialClusterIdx) + 1;
                else
                    for pic = 1:size(Meta_data{1, day}{1, sessionIdx}{1, 1}, 1)
                        if Meta_data{1, day}{1, sessionIdx}{1, 1}(pic, trialIdx) < 19
                            windowLeft = 101 + min(window) + (pic - 1) * 20;
                            windowRight = 101 + max(window) + (pic - 1) * 20;
                            picData = trialData(:, :, windowLeft:windowRight);
                            
                            [locationIdx, trialClusterIdx] = processTrial(factor1, Meta_data, day, sessionIdx, trialIdx, pic);
                            if locationIdx == condition
                                Session_data_pre{locationIdx, trialClusterIdx} = cat(1, ...
                                    Session_data_pre{locationIdx, trialClusterIdx}, picData);
                                Session_num(locationIdx, trialClusterIdx) = ...
                                    Session_num(locationIdx, trialClusterIdx) + 1;
                            end
                        end
                    end
                end
            end
        end
        
        % 累加 session 数据到总数据
        
        for loc = 1:size(All_data_pre, 1)
            for ori = 1:size(All_data_pre, 2)
                if ~isempty(Session_data_pre{loc, ori})
                    All_data_pre{loc, ori} = cat(1, ...
                        All_data_pre{loc, ori}, Session_data_pre{loc, ori});
                    All_num(loc, ori) = ...
                        All_num(loc, ori) + Session_num(loc, ori);
                end
            end
        end
        
        fprintf('Processed Session: %d\n', sessionIdx);
        % 清空 session 变量
        clear Session_data_pre Session_num
        All_data{1, day}{1, sessionIdx} = []; 
    end
    
    fprintf('Processed Day: %d\n', day);
end

save(sprintf('All_data_pre%d.mat', condition), 'All_data_pre', '-v7.3');

end

function [locationIdx, trialClusterIdx] = processTrial(factor1, Meta_data, day, sessionIdx, trialIdx, pic)
    if nargin < 6
        pic = 1;
    end

    if isempty(Meta_data{1, day}{1, sessionIdx}{1, 2})
        locationIdx = 1;
    else
        locationIdx = Meta_data{1, day}{1, sessionIdx}{1, 2}(1, trialIdx);
    end

    if factor1 == 2
        trialClusterIdx = Meta_data{1, day}{1, sessionIdx}{1, 3}(pic, trialIdx);
    else
        trialClusterIdx = Meta_data{1, day}{1, sessionIdx}{1, 1}(pic, trialIdx);
    end
end
