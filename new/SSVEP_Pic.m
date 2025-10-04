%---------------------------提取SSVEPA中的pic---------------------------%
function SSVEP_Pic(file_idx,MUA_LFP,label)

% 从SSVEP的trial数据中提取处Pic数据
%
% 输入参数：
%   MUA_LFP - 信号选择：1-MUA{1}; 2-MUA{2}; 3-LFP
%
% 输出内容：
%   SSVEP_PIC_DATA - 6*18的cell，phase*ori


for i = 1:length(file_idx)
    if strcmpi(label{i},'SSGnv') ||strcmpi(label{i},'SSGv')
        data = load(file_idx{i});
        SSVEP_PIC_DATA = cell(18,6,13);
        for cond = 1:130
            if ~isempty(data.(label{i})(cond).Data)
                fprintf(sprintf('start%scond%d\n',label{i},cond));
                trialdata = data.(label{i})(cond).Data;
                if isempty(data.(label{i})(cond).Pattern)
                    data.(label{i})(cond).Pattern = ones(size(trialdata,1),72);
                end
                for trial = 1:size(trialdata,1)
                    for pic = 1:72
                        window = 100+(pic-1)*20+1+(-20:79);
                        ori = data.(label{i})(cond).Pic_Ori(trial,pic);
                        location = data.(label{i})(cond).Location;
                        pattern = data.(label{i})(cond).Pattern(trial,pic);
                        currentdata = trialdata(trial,:,window);
                        trialbaseline = int16(mean(trialdata(trial,:,1:100),3));
                        SSVEP_PIC_DATA{ori,pattern,location} = cat(1,SSVEP_PIC_DATA{ori,pattern,location},currentdata-trialbaseline);
                    end
                end
                data.(label{i})(cond).Data = [];
            end
        end
    else
        data = load(file_idx{i});
        SSVEP_PIC_DATA = cell(18,6);
        for cond = 1:10
            if ~isempty(data.(label{i})(cond).Data)

                fprintf(sprintf('start%scond%d\n',label{i},cond));
                trialdata = int16(data.(label{i})(cond).Data);
                if isempty(data.(label{i})(cond).Pattern)
                    data.(label{i})(cond).Pattern = ones(size(trialdata,1),72);
                end
                for trial = 1:size(trialdata,1)
                    for pic = 1:72
                        window = 100+(pic-1)*20+1+(-20:79);
                        ori = data.(label{i})(cond).Pic_Ori(trial,pic);
                        pattern = data.(label{i})(cond).Pattern(trial,pic);
                        currentdata = trialdata(trial,:,window);
                        trialbaseline = int16(mean(trialdata(trial,:,1:100),3));
                        picbaseline =0;
                        SSVEP_PIC_DATA{ori,pattern} = cat(1,SSVEP_PIC_DATA{ori,pattern},currentdata-trialbaseline-picbaseline);
                    end
                end
                data.(label{i})(cond).Data = [];
            end

        end
        
    end
    [~,file_name,~] = fileparts(file_idx{i});
    
    save(sprintf('SSVEP_PIC_DATA_Bnew_%s_%s_%s.mat',file_name(1:2),MUA_LFP,label{i}),'SSVEP_PIC_DATA','-v7.3');
    fprintf('complete %s %s',MUA_LFP,label{i});
end


end