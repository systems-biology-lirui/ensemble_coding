
%%
for ori = 1:180
    for repeat = 1:6
        idx = (ori-1)*6+repeat;
        meta_data{idx,1} = sprintf('000000%04d.bmp',idx);
        meta_data{idx,2} = ori;
        meta_data{idx,3} = 0;
        meta_data{idx,4} = repeat;
        meta_data{idx,5} = 0;
        meta_data{idx,6} = 0;
        meta_data{idx,7} = 0;
        meta_data{idx,8} = 1;
        meta_data{idx,9} = 0;
        meta_data{idx,10} = 1;
    end
end
label = {'file_name','ori','loc','phase/pattern','SSGv','SSGv','BSG','MGnv','MGv','index1'};
meta_data = [label;meta_data];
writecell(meta_data, 'newsti_meta_1119_MGnv.csv');


%% {1} pic_file; {2} ori; {3} loc; {4} phase/pattern
% {5} SSGv(from MGv); {6} SSGnv; {7} BSG; {8} MGnv; {9} MGv; 
pic_idx = {1:3888;3999:5292;5293:5400;5401:5508;5509:5832};
for pic = 1:5832
    meta_data{pic,1} = sprintf('000000%04d.bmp',pic);
    meta_data{pic,2} = ori_all(pic);
    meta_data{pic,3} = location_all(pic);
    meta_data{pic,4} = phase_all(pic);
    for cluster = 1:5
        meta_data{pic,cluster+4} = 0;
        if ismember(pic,pic_idx{cluster})
            meta_data{pic,cluster+4} = 1;
        end
    end
    
end
%%
% 是否重复
index1 = zeros(1,5832);
for loc = 1:12
    for pic = 1:324
        i = (pic-1)*12+loc;
        if mod(pic,3)==1
            index1(i) = 1;
        end
    end
end
% ----------------SSGnv
for loc = 1:13
    for ori = 1:18
        for phase = 1:6
            i = (loc-1)*108+(phase-1)*18+ori;
            index1(i+3888) = 1;
        end
    end
end
% ----------------SG
for ori = 1:18
    for phase = 1:6
        i = (phase-1)*18+ori;
        index1(i+5292) = 1;
    end
end
% ----------------MGnv
for ori = 1:18
    for phase = 1:6
        i = (phase-1)*18+ori;
        index1(i+5400) = 1;
    end
end
% ---------------MGv
for ori = 1:18
    for pattern = 1:18
        i = (ori-1)*18+pattern;
        if mod(pattern,3) == 1
            index1(i+5508) = 1;
        end
    end
end
for pic = 1:5832
    meta_data{pic,10} = index1(pic);
end
label = {'file_name','ori','loc','phase/pattern','SSGv','SSGv','BSG','MGnv','MGv','index1'};
meta_data = [label;meta_data];
writecell(meta_data, 'sti_meta_data.csv');
%%
ori_all = zeros(1,5832);
location_all = zeros(1,5832);
phase_all = zeros(1,5832);


% ----------------SSGv
for loc = 1:12
    for pic = 1:324
        i = (pic-1)*12+loc;
        ori_all(i) = ori_data(loc,pic);
        location_all(i) = idx_ssgv(loc);
        phase_all(i) = floor(mod((pic-1),18)/3)+1;

    end
end
% ----------------SSGnv
for loc = 1:13
    for ori = 1:18
        for phase = 1:6
            i = (loc-1)*108+(phase-1)*18+ori;
            ori_all(i+3888) = ori*10;
            location_all(i+3888) = idx_ssgnv(loc);
            phase_all(i+3888) = phase;
            
        end
    end
end
% ----------------SG
for ori = 1:18
    for phase = 1:6
        i = (phase-1)*18+ori;
        ori_all(i+5292) = ori*10;
        phase_all(i+5292) = phase;

    end
end
% ----------------MGnv
for ori = 1:18
    for phase = 1:6
        i = (phase-1)*18+ori;
        ori_all(i+5400) = ori*10;
        phase_all(i+5400) = phase;

    end
end
% ---------------MGv
for ori = 1:18
    for pattern = 1:18
        i = (ori-1)*18+pattern;
        ori_all(i+5508) = ori*10;
        phase_all(i+5508) = floor((pattern-1)/3)+1;
        if mod(pattern,3) == 1
            index1(i+5508) = 1;
        end
    end
end