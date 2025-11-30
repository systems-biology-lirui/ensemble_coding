%% 一些整过的小代码
% 2025.11.30
% 1.给DG_Master_Meta_Table.mat中的SSGnv中加入pattern
% 2.给DG_Master_Meta_Table.mat中的SSGv中加入pattern



% --------------------------------------------------------------
% 给DG_Master_Meta_Table.mat中的SSGnv中加入pattern
idx = find(strcmp(MetaTable.Block,'SSGnv'));
idx = idx(9:end);

for i = idx'
    % load(MetaTable.FileName(i));
    for  t = 1:length(MetaTable.Content{i})
        a = MetaTable.Content{i}(t).Pic_Idx;
        [ori, pat, pos] = ind2sub([18, 6, 13], a);
        ori(pos == 14) = 19;
        if isequal(ori,MetaTable.Content{i}(t).Stim_Sequence)
            MetaTable.Content{i}(t).Pattern = pat;
        else
            fprintf('diff ori in session %d trial %d',i,t);
        end
    end
end

% ----------------------------------------------------------------
% 给DG_Master_Meta_Table.mat中的SSGv中加入pattern
idx1 = MetaTable.Content{267,1}(3).Pattern;
idx2 = MetaTable.Content{267,1}(6).Pattern;
idx3 = MetaTable.Content{267,1}(5).Pattern;
idx = find(strcmp(MetaTable.Block,'SSGv'));
for i = idx'
    for  t = 1:length(MetaTable.Content{i})
        a = MetaTable.Content{i}(t).Condition;
        switch a
            case -1
                MetaTable.Content{i}(t).Pattern = idx1;
            case 1
                MetaTable.Content{i}(t).Pattern = idx2;
            case 9
                MetaTable.Content{i}(t).Pattern = idx3;
        end
    end
end