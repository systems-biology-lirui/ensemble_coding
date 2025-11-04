function [repeatnum_per_ori, ClusterData] = TrialDataRearrange(config, ReFactor, trialdata)
    % Extracts and baseline-corrects neural data for specified pictures in each trial.
    locationselect = config.TrialDataParams.ssglocation;
    % Initialize structures
    repeatnum_per_ori(1:18) = struct('MGv',0,'MGnv',0,'SG',0); % Counts per orientation for specific blocks
    ClusterData = struct(...
        'MGv',  {cell(3, 10)}, ... % {1,ori}=Data, {2,ori}=Pattern
        'MGnv', {cell(3, 10)}, ...
        'SG',   {cell(3, 10)}, ...
        'SSGnv',{cell(2, 13, 10)}, ... % {loc,ori}=Data (QQ processing specific)
        'blank',[]);      % Store raw blank trials

    % Time parameters from config
    t = config.TrialDataParams;
    
    uniqueChars = unique({ReFactor.Block});  % 返回 {'A', 'B', 'C', 'D'}

    charIndices = cell(1, length(uniqueChars));

    for i = 1:length(uniqueChars)
        charIndices{i} = find(strcmp({ReFactor.Block}, uniqueChars{i}));
    end
    

    for i = 1:length(uniqueChars)
        currentBlock = uniqueChars{i};
        currentBlockidx = ReFactor(charIndices{i});
        if strcmp(currentBlock,'SSGnv')
            for loc = locationselect
                condition = -1:2:17;
                for condi = 1:length(-1:2:17)
                    idx = [currentBlockidx.Location] == loc & [currentBlockidx.Condition] == condition(condi);
                    idx = charIndices{i}(idx);
                    data = trialdata(idx, 1:96, 1:1640);
                    filteredData = data - mean(data(:,:,1:100),3);
                    % if any(isnan(data(:))) || any(isinf(data(:)))
                    % disp(min(data(:)));
                    % disp(max(data(:)));
                    % end
                    % filteredData = filtfilt(b, a, single(data)')'; % 滤波
                    % filteredData = reshape(filteredData,[1,96,1640]);
                    ClusterData.SSGnv{1, loc, condi} = int16(filteredData);

                    ClusterData.SSGnv{2, loc,condi} = int16([ReFactor(idx).Stim_Sequence]);
                end
            end
        elseif strcmp(currentBlock,'SSGv')
            for loc = locationselect
                condition = -1:2:17;
                for condi = 1:length(-1:2:17)
                    idx = [currentBlockidx.Location] == loc & [currentBlockidx.Condition] == condition(condi);
                    idx = charIndices{i}(idx);
                    data = trialdata(idx, 1:96, 1:1640);
                    filteredData = data - mean(data(:,:,1:100),3);
                    % if any(isnan(data(:))) || any(isinf(data(:)))
                    %     disp(min(data(:)));
                    %     disp(max(data(:)));
                    % end
                    % filteredData = filtfilt(b, a, single(data)')'; % 滤波
                    % filteredData = reshape(filteredData,[1,96,1640]);
                    ClusterData.SSGnv{1, loc, condi} = int16(filteredData);

                    ClusterData.SSGnv{2, loc,condi} = int16([ReFactor(idx).Stim_Sequence]);
                end
            end
        elseif strcmp(currentBlock,'blank')
            idx = charIndices{i};
            ClusterData.blank = cat(1,ClusterData.blank,single(trialdata(idx,1:94,1:1640)));
        else
            condition = t.condition;
            for condi = 1:length(condition)
                idx1 = [currentBlockidx.Condition] == condition(condi);
                idx = charIndices{i}(idx1);
                data = trialdata(idx, 1:94, t.triallength);
                filteredData = data - mean(data(:,:,1:100),3);
                % filteredData = filtfilt(b, a, single(data)')'; % 滤波
                % filteredData = reshape(filteredData,[1,96,1640]);
                ClusterData.(currentBlock){1,condi} = int16(filteredData);
                ClusterData.(currentBlock){2,condi} = cat(1,ReFactor(idx).Stim_Sequence);
                ClusterData.(currentBlock){3,condi} = cat(1,ReFactor(idx).Pattern);
            end
        end
    end
    
end