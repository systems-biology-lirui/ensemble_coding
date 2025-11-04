dbstop if error

%%
for s = 1:200
    disp(s)
    for m = 1
        if  ~isempty(Meta_data{s,m})
            myStruct = Meta_data{s,m};
            for trial = 1:length(myStruct)
                pic = myStruct(trial).Pic_idx;
                loc = myStruct(trial).Location;
                ori = myStruct(trial).Stim_Sequence;
                if strcmp(myStruct(trial).Block,'SSGnv')

                    myStruct(trial).Pattern = floor((pic-3888 - (loc-1)*108 - ori)/18)+1;
                elseif strcmp(myStruct(trial).Block,'SSGv')
                    myStruct(trial).Pattern = floor((floor((pic-1)/12)+1-(ori-1)*18-1)/3)+1;
                elseif strcmp(myStruct(trial).Block,'SG')
                    myStruct(trial).Pattern = floor((pic-5292- ori)/18) +1;
                elseif strcmp(myStruct(trial).Block,'MGnv')
                    myStruct(trial).Pattern = floor((pic-5400- ori)/18) +1;
                elseif strcmp(myStruct(trial).Block,'MGv')
                    myStruct(trial).Pattern = floor((pic -5508 - (ori-1)*18 -1)/3)+1;
                end
                myStruct(trial).Pattern(setdiff(1:52,[1,14,27,40])) = 0;
            end
        end
        Meta_data{s,m} = myStruct;
    end
end

%histogram([Meta_data{61,1}.Pattern],1:6)


%%
oldname = {'location','condition','stim_sequence','pattern','pic_idx','block'};
newname = {'Location','Condition','Stim_Sequence','Pattern','Pic_idx','Block'};
for s = [1:60,103:200]
    disp(s)
    data = struct();
    for trial = 1:size(Meta_data{s,1},2)
        for i = 1:length(newname)
        data(trial).(newname{i}) = Meta_data{s,1}(trial).(oldname{i});
        end
    end
    Meta_data{s,1} = data;
end




