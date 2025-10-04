function [All_data_pre,All_data,All_num_pre] = pattern_pre_analyse(All_data, Meta_data,window)
% 主要的目的是提取出每张图片以及知晓前一张图片是什么，适用于EC

All_num_pre = zeros(7,19,19);
All_data_pre = cell(7,19,19);
% for x = 1:7
%     for y =1 :19
%         for z = 1
%             All_data_pre{x,y,z} = zeros(1,96,60);
%         end
%     end
% end
for day = 1:size(All_data,2)
    for session = 1:size(All_data{day},2)
        for trial = 1:size(All_data{day}{session},1)
            for pic = 2:size(Meta_data{day}{session}{1},1)
                pre_ori = Meta_data{day}{session}{1}(pic-1,trial);
                patternidx = Meta_data{day}{session}{4}(pic,trial);
                oriidx = Meta_data{day}{session}{1}(pic,trial);

                All_data_pre{patternidx,oriidx,pre_ori} = cat(1,All_data_pre{patternidx,oriidx,pre_ori},All_data{day}{session}(trial,:,window+100+(pic-1)*20+1));
                % All_num_pre(patternidx,oriidx,oripreidx) = All_num_pre(patternidx,oriidx,oripreidx) +1;

            end
        end
        fprintf(sprintf('Session%d complete \n',session))
        All_data{day}{session}=[];
    end
end
% for x = 1:7
%     for y =1 :19
%         for z = 1:19
%             All_data_pre{x,y,z} = All_data_pre{x,y,z}/squeeze(All_num_pre(x,y,z));
%         end
%     end
% end